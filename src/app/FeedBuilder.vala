using DFLib;
using Gtk;
using Singularity;

[GtkTemplate (ui="/org/df458/Singularity/FeedBuilder.ui")]
public class FeedBuilder : Popover
{
    public FeedBuilder()
    {
        Timeout.add_seconds(2, () => { if(url_changed) reload_feed(); return true; });
    }

    public void reset_form()
    {
        url_entry.text = "";
        title_label.label = "";
        link_label.label = "";
        to_build = null;
        m_temp_items = null;
        url_changed = false;
    }

    public signal void subscription_added(Feed new_sub, bool loaded, Gee.List<Item?>? items);
    public signal void cancelled();

    private Feed to_build;
    private bool url_changed = false;

    private Gee.List<Item?>? m_temp_items = null;
    [GtkChild]
    private Entry url_entry;
    [GtkChild]
    private Label title_label;
    [GtkChild]
    private Label link_label;

    private void reload_feed()
    {
        url_changed = false;

        Soup.Session session = new Soup.Session();
        XmlRequest request = new XmlRequest(url_entry.text, session);
        request.send_async.begin((obj, ret) =>
        {
            bool success = request.send_async.end(ret);
            url_entry.secondary_icon_name = success ? "emblem-ok-symbolic" : "dialog-error-symbolic";

            if(success) {
                FeedProvider? provider = request.get_provider_from_request();
                if(provider != null && provider.parse_data(request.doc)) {
                    to_build = provider.stored_feed;
                    title_label.label = to_build.title;
                    if(to_build.site_link != null)
                        link_label.label = to_build.site_link;
                    m_temp_items = provider.data;
                }
            }
        });
    }

    [GtkCallback]
    private void on_cancel() {
        cancelled();
        reset_form();
    }

    [GtkCallback]
    private void on_subscribe() {
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
    }

    [GtkCallback]
    private void on_url_changed() {
        url_changed = true;
        url_entry.secondary_icon_name = "content-loading-symbolic";
        to_build = null;
        m_temp_items = null;
    }
}
