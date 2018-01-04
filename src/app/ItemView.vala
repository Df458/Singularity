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
using Gtk;
using WebKit;
using JSHandler;
using Singularity;

// Interface for widgets that display items
public interface ItemView : Widget
{
    // Returns whether to only show "important" items (unread and starred)
    public abstract bool get_important_only();
    // Sets the items to display
    public abstract void view_items(Gee.Traversable<Item> items, string title, string? desc);

    public signal void items_viewed(Item[] i);
    public signal void item_read_toggle(Item i);
    public signal void item_star_toggle(Item i);
    public signal void unread_mode_changed(bool unread_only);
}

// ItemView that displays all items in a linear "stream"
[GtkTemplate (ui = "/org/df458/Singularity/StreamItemView.ui")]
public class StreamItemView : Box, ItemView {
    // Returns whether to only show "important" items (unread and starred)
    public bool get_important_only() { return m_important_view; }

    public StreamItemView() {
        UserContentManager content_manager = new UserContentManager();

        try {
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
        } catch(Error e) {
            error("Can't read JS resources: %s", e.message);
        }

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
    public void view_items(Gee.Traversable<Item> item_list, string title, string? desc) {
        page_cursor = 0;

        m_item_list = new Gee.ArrayList<Item>();
        item_list.foreach((i) => { m_item_list.add(i); return true; });

        string html = m_builder.buildPageHTML(m_item_list, AppSettings.items_per_list);
        m_web_view.load_html(html, "file://singularity");

        title_label.label = "<span font=\"24\">%s</span>".printf(title);
        if(desc != null) {
            desc_label.label = desc.substring(0, desc.index_of("\n"));
        } else {
            desc_label.label = "";
        }
    }

    private bool m_important_view = true;
    private StreamViewBuilder m_builder;
    private Gee.List<Item> m_item_list;
    private WebKit.WebView m_web_view;

    [GtkChild]
    private Label title_label;
    [GtkChild]
    private Label desc_label;

    private int page_cursor = 0;

    private bool policy_decision(PolicyDecision decision, PolicyDecisionType type) {
        if(type == PolicyDecisionType.NAVIGATION_ACTION) {
            NavigationPolicyDecision nav_dec = (NavigationPolicyDecision) decision;
            if(nav_dec.get_navigation_action().get_navigation_type() == NavigationType.LINK_CLICKED) {
                try {
                    GLib.Process.spawn_command_line_async(AppSettings.link_command.printf(nav_dec.get_navigation_action().get_request().uri));
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
        m_web_view.run_javascript.begin("readAll();", null);

        items_viewed(m_item_list.to_array());
    }

    // Called when the "Toggle important" toggle is toggled
    [GtkCallback]
    void on_toggle_important_view() {
        m_important_view = !m_important_view;
        unread_mode_changed(m_important_view);
    }

    private void message_received(JavascriptResult result) {
        JavascriptAppRequest request = get_js_info(result);
        string command = (string)request.returned_value;
        if(command == null)
            return;
        char cmd;
        int id;
        if(command.scanf("%c:%d", out cmd, out id) != 2 && cmd != 'p')
            return;

        switch(cmd) {
            case 'v': // Item viewed
                items_viewed({m_item_list[id]});
            break;

            case 's': // Star button pressed
                item_star_toggle(m_item_list[id]);
            break;

            case 'r': // Read button pressed
                item_read_toggle(m_item_list[id]);
            break;

            case 'p':
                add_items();
            break;
        }
    }

    private void add_items() {
        page_cursor += AppSettings.items_per_list;
        if(page_cursor > m_item_list.size)
            return;
        StringBuilder sb = new StringBuilder("document.body.innerHTML += String.raw`");
        int starting_id = page_cursor;
        for(int i = 0; i < AppSettings.items_per_list && page_cursor + i < m_item_list.size; ++i) {
            sb.append(m_builder.buildItemHTML(m_item_list[page_cursor + i], page_cursor + i));
        }
        sb.append_printf("`; prepareItems(%d);", starting_id);

        m_web_view.run_javascript.begin(sb.str, null);
    }
}

// ItemView that displays items in a 2-column format: One column with an item list, and a second that displys the selected item.
[GtkTemplate (ui = "/org/df458/Singularity/ColumnItemView.ui")]
public class ColumnItemView : Paned, ItemView {
    // Returns whether to only show "important" items (unread and starred)
    public bool get_important_only() { return false; }

    public ColumnItemView() {
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

        m_item_list = new Gee.ArrayList<Item>();
        column_scroll.edge_reached.connect((p) => {
            if(p == PositionType.BOTTOM) {
                add_items();
            }
        });
    }
    // Sets the items to display
    public void view_items(Gee.Traversable<Item> item_list, string title, string? desc) {
        page_cursor = 0;
        column_scroll.vadjustment.set_value(0);

        title_label.label = title;

        m_item_list = new Gee.ArrayList<Item>();
        item_list.foreach((i) => { m_item_list.add(i); return true; });

        foreach(ListBoxRow row in m_row_list)
            item_box.remove(row);
        m_row_list.clear();
        add_items();

        m_builder.page = -1;
        string html = m_builder.buildPageHTML(m_item_list, 0);
        m_web_view.load_html(html, "file://singularity");
    }

    [GtkChild]
    private ListBox item_box;
    [GtkChild]
    private Box webview_box;
    [GtkChild]
    private ScrolledWindow column_scroll;
    [GtkChild]
    private Label title_label;
    [GtkChild]
    private ToggleButton star_button;
    private ColumnViewBuilder m_builder;
    private Gee.List<Item> m_item_list;
    private Gee.List<ListBoxRow> m_row_list;
    private WebKit.WebView m_web_view;

    private int page_cursor = 0;

    private bool policy_decision(PolicyDecision decision, PolicyDecisionType type) {
        if(type == PolicyDecisionType.NAVIGATION_ACTION) {
            NavigationPolicyDecision nav_dec = (NavigationPolicyDecision) decision;
            if(nav_dec.get_navigation_action().get_navigation_type() == NavigationType.LINK_CLICKED) {
                try {
                    GLib.Process.spawn_command_line_async(AppSettings.link_command.printf(nav_dec.get_navigation_action().get_request().uri));
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

    // Called when the user selects an item in the left column
    [GtkCallback]
    void on_item_selected(ListBoxRow? row) {
        if(row == null)
            return;

        ItemListEntry entry = row.get_child() as ItemListEntry;
        Item item = entry.item;
        entry.viewed();
        if(item.unread) {
            items_viewed({item});
            item.unread = false;
        }

        star_button.active = item.starred;

        m_builder.page = m_item_list.index_of(item);
        string html = m_builder.buildPageHTML(m_item_list, 0);
        m_web_view.load_html(html, "file://singularity");
    }

    // Called when the user presses the Mark as Unread button
    [GtkCallback]
    void on_unread_pressed() {
        ItemListEntry row = item_box.get_selected_row().get_child() as ItemListEntry;
        item_read_toggle(row.item);
        row.update_view();
    }

    // Called when the user toggle the star button
    [GtkCallback]
    void on_star_pressed() {
        ItemListEntry row = item_box.get_selected_row().get_child() as ItemListEntry;
        if(star_button.active == row.item.starred)
            return;

        item_star_toggle(row.item);
        row.update_view();
    }

    public void add_items() {
        int i = 0;
        for(i = 0; i < AppSettings.items_per_list && i + page_cursor < m_item_list.size; ++i) {
            ListBoxRow row = new ListBoxRow();
            row.add(new ItemListEntry(m_item_list[page_cursor + i]));
            item_box.add(row);
            m_row_list.add(row);
        }

        page_cursor += i;
        this.show_all();
    }
}

// ItemView that displays items in a grid. Clicking any grid square causes the full item to pop up over the view.
[GtkTemplate (ui = "/org/df458/Singularity/GridItemView.ui")]
public class GridItemView : Box, ItemView {
    // Returns whether to only show "important" items (unread and starred)
    public bool get_important_only() { return m_important_view; }

    public GridItemView() {
        UserContentManager content_manager = new UserContentManager();

        try {
            File userscript_resource = File.new_for_uri("resource:///org/df458/Singularity/GridViewLink.js");
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
        } catch(Error e) {
            error("Can't read JS resources: %s", e.message);
        }

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

        m_builder = new GridViewBuilder();

        pack_start(m_web_view, true, true);
    }
    // Sets the items to display
    public void view_items(Gee.Traversable<Item> item_list, string title, string? desc) {
        page_cursor = 0;

        m_item_list = new Gee.ArrayList<Item>();
        item_list.foreach((i) => { m_item_list.add(i); return true; });

        string html = m_builder.buildPageHTML(m_item_list, AppSettings.items_per_list);
        m_web_view.load_html(html, "file://singularity");

        title_label.label = "<span font=\"24\">%s</span>".printf(title);
        if(desc != null) {
            desc_label.label = desc.substring(0, desc.index_of("\n"));
        } else {
            desc_label.label = "";
        }
    }

    private bool m_important_view = true;
    private GridViewBuilder m_builder;
    private Gee.List<Item> m_item_list;
    private WebKit.WebView m_web_view;

    [GtkChild]
    private Label title_label;
    [GtkChild]
    private Label desc_label;

    private int page_cursor = 0;

    private bool policy_decision(PolicyDecision decision, PolicyDecisionType type) {
        if(type == PolicyDecisionType.NAVIGATION_ACTION) {
            NavigationPolicyDecision nav_dec = (NavigationPolicyDecision) decision;
            if(nav_dec.get_navigation_action().get_navigation_type() == NavigationType.LINK_CLICKED) {
                try {
                    GLib.Process.spawn_command_line_async(AppSettings.link_command.printf(nav_dec.get_navigation_action().get_request().uri));
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
        m_web_view.run_javascript.begin("readAll();", null);

        items_viewed(m_item_list.to_array());
    }

    // Called when the "Toggle important" toggle is toggled
    [GtkCallback]
    void on_toggle_important_view() {
        m_important_view = !m_important_view;
        unread_mode_changed(m_important_view);
    }

    private void message_received(JavascriptResult result) {
        JavascriptAppRequest request = get_js_info(result);
        string command = (string)request.returned_value;
        if(command == null)
            return;
        char cmd;
        int id;
        if(command.scanf("%c:%d", out cmd, out id) != 2 && cmd != 'p')
            return;

        switch(cmd) {
            case 'v': // Item viewed
                items_viewed({m_item_list[id]});
            break;

            case 's': // Star button pressed
                item_star_toggle(m_item_list[id]);
            break;

            case 'r': // Read button pressed
                item_read_toggle(m_item_list[id]);
            break;

            case 'p':
                add_items();
            break;
        }
    }

    private void add_items() {
        page_cursor += AppSettings.items_per_list;
        if(page_cursor > m_item_list.size)
            return;
        StringBuilder sb = new StringBuilder("document.body.innerHTML += String.raw`");
        int starting_id = page_cursor;
        for(int i = 0; i < AppSettings.items_per_list && page_cursor + i < m_item_list.size; ++i) {
            sb.append(m_builder.buildItemHTML(m_item_list[page_cursor + i], page_cursor + i));
        }
        sb.append_printf("`; prepareItems(%d);", starting_id);

        m_web_view.run_javascript.begin(sb.str, null);
    }
}
