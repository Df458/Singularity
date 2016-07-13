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

namespace Singularity
{

public class ItemView : Box
{
    public ItemView(GlobalSettings gs)
    {
        m_global_settings = gs;

        this.orientation = Orientation.VERTICAL;
        this.spacing = 12;

        m_view_builder = new StreamViewBuilder(css_str, star_icon_base64); // TODO: Remove the need for either of these arguments

        init_content();
        connect_signals();

        this.show_all();
    }

    public void view_items(Gee.List<Item?> item_list)
    {
        string html = m_view_builder.buildHTML(item_list);
        m_web_view.load_html(html, null);
    }

    private ViewBuilder  m_view_builder;
    private WebView      m_web_view;
    private unowned GlobalSettings m_global_settings;
    private UserContentManager m_content_manager;

    private void init_content()
    {

        m_content_manager = new UserContentManager();
        UserScript test_script = new UserScript(js_str, UserContentInjectedFrames.ALL_FRAMES, UserScriptInjectionTime.START, null, null);
        m_content_manager.add_script(test_script);

        m_web_view = new WebView.with_user_content_manager(m_content_manager);

        WebKit.Settings settings = new WebKit.Settings();
        settings.set_allow_file_access_from_file_urls(true);
        settings.set_enable_developer_extras(true); // For now. We may want to disable this for release builds
        settings.set_enable_dns_prefetching(false);
        settings.set_enable_frame_flattening(true);
        settings.set_enable_fullscreen(true);
        settings.set_enable_page_cache(false);
        settings.set_enable_smooth_scrolling(true);
        settings.set_enable_write_console_messages_to_stdout(false);

        m_web_view.set_background_color(this.get_style_context().get_background_color(StateFlags.NORMAL));
        m_web_view.set_settings(settings);

        this.pack_start(m_web_view, true, true);
    }

    private void connect_signals()
    {
        m_web_view.decide_policy.connect(policy_decision);

        m_content_manager.script_message_received.connect(message_received);
        m_content_manager.register_script_message_handler("test");
    }

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

    private void message_received(JavascriptResult result)
    {
        JavascriptAppRequest request = get_js_info(result);
        // TODO: Handle the value
        stderr.printf("Returned value is a %s: %s\n", request.returned_value.type_name(), (string)request.returned_value);
    }
}
}
