using Gtk;

namespace Singularity
{
    public class FeedBuilder : Box
    {
        public FeedBuilder()
        {
            this.orientation = Orientation.VERTICAL;
            this.spacing = 6;
            this.margin = 18;

            init_structure();
            init_content();
            connect_signals();

            Timeout.add_seconds(3, () => { if(url_changed) reload_feed(); return true; });
        }

        public void reset_form()
        {
            url_entry.text = "";
            title_entry.text = "";
            link_entry.text = "";
            to_build = null;
            m_temp_items = null;
            url_changed = false;
        }

        public signal void subscription_added(Feed new_sub, bool loaded, Gee.List<Item?>? items);
        public signal void cancelled();

        private Feed to_build;
        private bool url_changed = false;

        private Entry url_entry;
        private SettingsGrid attr_grid;
        private ButtonBox response_box;
        private Entry title_entry;
        private Entry link_entry;
        private Button subscribe_button;
        private Button cancel_button;

        private Gee.List<Item?>? m_temp_items = null;

        private void init_structure()
        {
            attr_grid = new SettingsGrid();
            response_box = new ButtonBox(Orientation.HORIZONTAL);

            this.pack_end(response_box, true, true);
            this.pack_end(attr_grid, true, true);
        }

        private void init_content()
        {
            url_entry   = new Entry();
            title_entry = new Entry();
            link_entry  = new Entry();
            subscribe_button = new Button.with_label("Subscribe");
            cancel_button = new Button.with_label("Cancel");

            url_entry.placeholder_text = "Enter a URL\u2026";
            subscribe_button.get_style_context().add_class("suggested-action");

            this.pack_start(url_entry, false, false);
            attr_grid.add("Title", title_entry, 0);
            attr_grid.add("Site Link", link_entry, 0);
            response_box.add(subscribe_button);
            response_box.add(cancel_button);
        }

        private void connect_signals()
        {
            url_entry.changed.connect(() =>
            {
                url_changed = true;
                url_entry.secondary_icon_name = "content-loading-symbolic";
                to_build = null;
                m_temp_items = null;
            });

            cancel_button.clicked.connect(() =>
            {
                cancelled();
                reset_form();
            });

            subscribe_button.clicked.connect(() =>
            {
                if(url_entry.text == "") {
                    cancelled();
                    reset_form();
                    return;
                }

                bool loaded = true;
                if(to_build == null) {
                    loaded = false;
                    to_build = new Feed();
                }

                to_build.link = url_entry.text;
                subscription_added(to_build, loaded, m_temp_items);
                reset_form();
            });
        }

        private void reload_feed()
        {
            url_changed = false;
            // TODO: Indicate working state

            XmlRequest request = new XmlRequest(url_entry.text);
            request.send_async.begin((obj, ret) =>
            {
                bool success = request.send_async.end(ret);

                // TODO: Indicate success/failure
                if(success)
                    url_entry.secondary_icon_name = "emblem-ok-symbolic";
                else
                    url_entry.secondary_icon_name = "dialog-error-symbolic";

                if(success) {
                    FeedProvider? provider = request.get_provider_from_request();
                    if(provider != null && provider.parse_data(request.doc)) {
                        to_build = provider.stored_feed;
                        title_entry.text = to_build.title;
                        if(to_build.site_link != null)
                            link_entry.text = to_build.site_link;
                        m_temp_items = provider.data;
                    }
                }
            });
        }

    }
}
