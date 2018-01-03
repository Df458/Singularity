/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2017  Hugues Ross <hugues.ross@gmail.com>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
using DFLib;
using Gtk;

namespace Singularity
{
// The popover for subscribing to new feeds
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
        title_label.label = "Feed Title";
        link_label.label = "Site Link";
        to_build = null;
        m_temp_items = null;
        url_changed = false;
        info_revealer.reveal_child = false;
    }

    public signal void subscription_added(Feed new_sub, bool loaded, Gee.List<Item?>? items);
    public signal void cancelled();

    private Feed to_build = null;
    private bool url_changed = false;

    private Gee.List<Item?>? m_temp_items = null;
    [GtkChild]
    private Entry url_entry;
    [GtkChild]
    private Label title_label;
    [GtkChild]
    private Label link_label;
    [GtkChild]
    private Button subscribe_button;
    [GtkChild]
    private Revealer info_revealer;

    private void reload_feed()
    {
        url_changed = false;

        if(url_entry.text == "")
            return;

        Soup.Session session = new Soup.Session();
        if(AppSettings.cookie_db_path != "") {
            Soup.CookieJarDB cookies = new Soup.CookieJarDB(AppSettings.cookie_db_path, true);
            session.add_feature(cookies);
        }
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
                info_revealer.reveal_child = true;
            }
        });
    }

    [GtkCallback]
    private void on_cancel()
    {
        cancelled();
        reset_form();
    }

    [GtkCallback]
    private void on_subscribe()
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
    }

    [GtkCallback]
    private void on_url_changed()
    {
        subscribe_button.sensitive = url_entry.text != "";
        url_changed = true;
        url_entry.secondary_icon_name = url_entry.text != "" ? "content-loading-symbolic" : "";
        to_build = null;
        m_temp_items = null;
        info_revealer.reveal_child = false;
    }
}
}
