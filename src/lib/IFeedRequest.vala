namespace Singularity {
    /** Represents a request for loading feed providers */
    public interface IFeedRequest : Object {
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
        public abstract bool send ();

        /**
         * Sends the request asynchronously
         *
         * @return true if the request succeeded; otherwise, false
         */
        public abstract async bool send_async ();
    }
}
