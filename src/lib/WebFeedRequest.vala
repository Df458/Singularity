namespace Singularity {
    /** IFeedRequest for loading feeds from a URI */
    public abstract class WebFeedRequest : Object, IFeedRequest {
        /** Whether or not this request generated an error */
        public bool error_exists { get { return error_message != null; } }

        /** The error message for this request, if any */
        public string? error_message { get; protected set; default = null; }

        /** Whether or not this request has been sent */
        public bool request_sent { get; private set; default = false; }

        protected WebFeedRequest (string uri, Soup.Session s) {
            string turi = uri;
            if (!uri.has_prefix ("http://")
                && !uri.has_prefix ("https://")
                && !uri.has_prefix ("file://"))
                turi = "http://" + uri;

            m_session = s;
            m_message = new Soup.Message ("GET", turi);
        }

        /**
         * Create the XML document from a string containing data
         *
         * @param data The data to parse
         * @return true on success; otherwise, false
         */
        protected abstract bool create_doc (string? data);

        /**
         * Returns the base URI that this request is loading from
         */
        public string get_base_uri () {
            return m_message.uri.get_host ();
        }

        /**
         * Get the provider from this request
         *
         * @return A FeedProvider, or null if not loaded
         */
        public abstract FeedProvider? get_provider ();

        /**
         * Sends the request synchronously
         *
         * @return true if the request succeeded; otherwise, false
         */
        public bool send () {
            var loop = new MainLoop ();
            request_sent = true;

            if (m_message == null) {
                error_message = "Invalid URL";
                return false;
            }

            m_session.queue_message (m_message, (s, m) =>
            {
                loop.quit ();
            });

            loop.run ();

            if (m_message.status_code >= 400) {
                error_message = get_status_error (m_message.status_code);
                return false;
            }

            string data = (string)m_message.response_body.data;
            return create_doc (data);
        }

        /**
         * Sends the request asynchronously
         *
         * @return true if the request succeeded; otherwise, false
         */
        public async bool send_async () {
            SourceFunc callback = this.send_async.callback;
            request_sent = true;
            string? data = null;

            if (m_session == null) {
                error_message = "Broken Session";
                warning ("Failed to create session");
                return false;
            }

            if (m_message == null) {
                error_message = "Invalid URL";
                warning ("Failed to retrieve URL");
                return false;
            }

            m_session.queue_message (m_message, (s, m) =>
            {
                data = (string)m.response_body.data;
                Idle.add ((owned) callback);
            });

            yield;

            if (m_message.status_code >= 400) {
                error_message = get_status_error (m_message.status_code);
                return false;
            }

            return create_doc (data);
        }

        /**
         * Get a textual error from the given HTTP status code
         *
         * @param status_code The status code
         * @return A string containing an error message
         */
        private string get_status_error (uint status_code) {
            string description = "";
            switch (status_code) {
                case Soup.Status.NOT_FOUND:
                    description = "Not found";
                    break;
                case Soup.Status.FORBIDDEN:
                    description = "Forbidden";
                    break;
                case Soup.Status.UNAUTHORIZED:
                    description = "Unauthorized";
                    break;
                default:
                    return "Server returned error code %u".printf (status_code);
            }

            return "Server returned error code %u: %s".printf (status_code, description);
        }

        private Soup.Session? m_session = null;
        private Soup.Message? m_message = null;
    }
}
