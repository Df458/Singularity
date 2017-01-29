/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

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

using Gtk;
using WebKit;
using JSHandler;
using Singularity;

public interface ItemView : Widget
{
    // Returns whether to only show "important" items (unread and starred)
    public abstract bool get_important_only();
    // Sets the items to display
    public abstract void view_items(Gee.List<Item> items);

    // TODO: Maybe replace these?
    public signal void item_viewed(Item i);
    public signal void item_read_toggle(Item i);
    public signal void item_star_toggle(Item i);
    public signal void unread_mode_changed(bool unread_only);
}

[GtkTemplate (ui = "/org/df458/Singularity/StreamItemView.ui")]
public class StreamItemView : Box, ItemView {
    // Returns whether to only show "important" items (unread and starred)
    public bool get_important_only() { return m_important_view; }

    public StreamItemView(GlobalSettings app_settings) {
        m_global_settings = app_settings;

        UserContentManager content_manager = new UserContentManager();

        File userscript_resource = File.new_for_uri("resource:///org/df458/Singularity/StreamViewLink.js");
        FileInputStream stream = userscript_resource.read();
        DataInputStream data_stream = new DataInputStream(stream);

        // Load the linking JS and inject it
        StringBuilder builder = new StringBuilder();
        string? str = data_stream.read_line();
        do {
            builder.append(str + "\n");
            str = data_stream.read_line();
        } while(str != null);
        UserScript link_script = new UserScript(builder.str, UserContentInjectedFrames.ALL_FRAMES, UserScriptInjectionTime.START, null, null);
        content_manager.add_script(link_script);

        m_web_view = new WebView.with_user_content_manager(content_manager);
        WebKit.Settings settings = new WebKit.Settings();
        settings.set_allow_file_access_from_file_urls(true);
        settings.set_enable_developer_extras(true); // TODO: For now. We may want to disable this for release builds
        settings.set_enable_dns_prefetching(false);
        settings.set_enable_frame_flattening(true);
        settings.set_enable_fullscreen(true);
        settings.set_enable_page_cache(false);
        settings.set_enable_smooth_scrolling(true);
        settings.set_enable_write_console_messages_to_stdout(false);

        m_web_view.set_settings(settings);

        m_web_view.decide_policy.connect(policy_decision);

        content_manager.script_message_received.connect(message_received);
        content_manager.register_script_message_handler("test");

        m_builder = new StreamViewBuilder();

        pack_start(m_web_view, true, true);
    }
    // Sets the items to display
    public void view_items(Gee.List<Item> item_list) {
        m_item_list = item_list;
        string html = m_builder.buildHTML(m_item_list);
        m_web_view.load_html(html, "file://singularity");
    }

    private bool m_important_view = true;
    private StreamViewBuilder m_builder;
    private Gee.List<Item> m_item_list;
    private WebKit.WebView m_web_view;
    private GlobalSettings m_global_settings;

    private bool policy_decision(PolicyDecision decision, PolicyDecisionType type)
    {
        if(type == PolicyDecisionType.NAVIGATION_ACTION) {
            NavigationPolicyDecision nav_dec = (NavigationPolicyDecision) decision;
            if(nav_dec.get_navigation_action().get_navigation_type() == NavigationType.LINK_CLICKED) {
                try {
                    GLib.Process.spawn_command_line_async(m_global_settings.link_command.printf(nav_dec.get_navigation_action().get_request().uri));
                    nav_dec.ignore();
                } catch(Error e) {
                    warning("Error opening external link: %s", e.message);
                }
            }
            return true;
        }
        return false;
    }

    // Called when the "Mark all as read" button is clicked
    [GtkCallback]
    void on_mark_all_read() {
        // TODO
    }

    // Called when the "Toggle important" toggle is toggled
    [GtkCallback]
    void on_toggle_important_view() {
        m_important_view = !m_important_view;
        unread_mode_changed(m_important_view);
    }

    private void message_received(JavascriptResult result)
    {
        JavascriptAppRequest request = get_js_info(result);
        string command = (string)request.returned_value;
        if(command == null)
            return;
        char cmd;
        int id;
        if(command.scanf("%c:%d", out cmd, out id) != 2)
            return;

        switch(cmd) {
            case 'v': // Item viewed
                item_viewed(m_item_list[id]);
            break;

            case 's': // Star button pressed
                item_star_toggle(m_item_list[id]);
            break;

            case 'r': // Read button pressed
                item_read_toggle(m_item_list[id]);
            break;
        }
    }
}

[GtkTemplate (ui = "/org/df458/Singularity/ColumnItemView.ui")]
public class ColumnItemView : Paned, ItemView {
    // Returns whether to only show "important" items (unread and starred)
    public bool get_important_only() { return false; }

    public ColumnItemView(GlobalSettings app_settings) {
        m_global_settings = app_settings;

        m_row_list = new Gee.ArrayList<ListBoxRow>();

        m_web_view = new WebView();
        WebKit.Settings settings = new WebKit.Settings();
        settings.set_allow_file_access_from_file_urls(true);
        settings.set_enable_developer_extras(true); // TODO: For now. We may want to disable this for release builds
        settings.set_enable_dns_prefetching(false);
        settings.set_enable_frame_flattening(true);
        settings.set_enable_fullscreen(true);
        settings.set_enable_page_cache(false);
        settings.set_enable_smooth_scrolling(true);
        settings.set_enable_write_console_messages_to_stdout(false);

        m_web_view.set_settings(settings);

        m_web_view.decide_policy.connect(policy_decision);

        m_builder = new ColumnViewBuilder();

        item_box.set_header_func(listbox_header_separator);

        webview_box.pack_start(m_web_view, true, true);
    }
    // Sets the items to display
    public void view_items(Gee.List<Item> item_list) {
        foreach(ListBoxRow row in m_row_list)
            item_box.remove(row);
        m_row_list.clear();

        m_item_list = item_list;
        foreach(Item i in item_list) {
            ListBoxRow row = new ListBoxRow();
            row.add(new ItemListEntry(i));
            item_box.add(row);
            m_row_list.add(row);
        }
        this.show_all();
    }

    [GtkChild]
    private ListBox item_box;
    [GtkChild]
    private Box webview_box;
    private ColumnViewBuilder m_builder;
    private Gee.List<Item> m_item_list;
    private Gee.List<ListBoxRow> m_row_list;
    private WebKit.WebView m_web_view;
    private GlobalSettings m_global_settings;

    private bool policy_decision(PolicyDecision decision, PolicyDecisionType type)
    {
        if(type == PolicyDecisionType.NAVIGATION_ACTION) {
            NavigationPolicyDecision nav_dec = (NavigationPolicyDecision) decision;
            if(nav_dec.get_navigation_action().get_navigation_type() == NavigationType.LINK_CLICKED) {
                try {
                    GLib.Process.spawn_command_line_async(m_global_settings.link_command.printf(nav_dec.get_navigation_action().get_request().uri));
                    nav_dec.ignore();
                } catch(Error e) {
                    warning("Error opening external link: %s", e.message);
                }
            }
            return true;
        }
        return false;
    }

    // Called when the "Mark all as read" button is clicked
    [GtkCallback]
    void on_mark_all_read() {
        // TODO
    }

    [GtkCallback]
    void on_item_selected(ListBoxRow? row) {
        if(row == null)
            return;

        ItemListEntry entry = row.get_child() as ItemListEntry;
        Item item = entry.item;
        entry.viewed();
        if(item.unread)
            item_viewed(item);

        m_builder.page = m_item_list.index_of(item);
        string html = m_builder.buildHTML(m_item_list);
        m_web_view.load_html(html, "file://singularity");
    }
}
