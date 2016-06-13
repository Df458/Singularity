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

namespace Singularity
{
public class GlobalSettings
{
    public bool   auto_update;
    public bool   start_update;
    public uint   auto_update_freq;
    public int    read_rule[3];
    public int    unread_rule[3];
    public bool   download_attachments;
    public bool   ask_download_location;
    public File   default_download_location;
    public string link_command;

    public GlobalSettings(string id)
    {
        m_source = new Settings(id);
    }

    public void save()
    {
        m_source.set_boolean("auto-update", auto_update);
        m_source.set_boolean("start-update", start_update);
        m_source.set_uint("auto-update-freq", auto_update_freq);
        m_source.set_value("read-rule", new Variant("(iii)", read_rule[0], read_rule[1], read_rule[2]));
        m_source.set_value("unread-rule", new Variant("(iii)", unread_rule[0], unread_rule[1], unread_rule[2]));
        m_source.set_boolean("download-attachments", download_attachments);
        m_source.set_boolean("ask-download-location", ask_download_location);
        m_source.set_string("default-download-location", default_download_location.get_path());
        m_source.set_string("link-command", link_command);
    }

    public void load()
    {
        auto_update               = m_source.get_boolean("auto-update");
        start_update              = m_source.get_boolean("start-update");
        auto_update_freq          = m_source.get_uint("auto-update-freq");
        Variant read_value        = m_source.get_value("read-rule");
        VariantIter read_iter     = read_value.iterator();
        read_iter.next("i", &read_rule[0]);
        read_iter.next("i", &read_rule[1]);
        read_iter.next("i", &read_rule[2]);
        Variant unread_value      = m_source.get_value("unread-rule");
        VariantIter unread_iter   = unread_value.iterator();
        unread_iter.next("i", &unread_rule[0]);
        unread_iter.next("i", &unread_rule[1]);
        unread_iter.next("i", &unread_rule[2]);
        download_attachments      = m_source.get_boolean("download-attachments");
        ask_download_location     = m_source.get_boolean("ask-download-location");
        default_download_location = File.new_for_path(m_source.get_string("default-download-location"));
        link_command              = m_source.get_string("link-command");
    }

    public void reset()
    {
        auto_update               = true;
        start_update              = true;
        auto_update_freq          = 10;
        read_rule                 = { 6, 1, 1 };
        unread_rule               = { 0, -1, 0 };
        download_attachments      = true;
        ask_download_location     = true;
        default_download_location = File.new_for_path(Environment.get_home_dir() + "/Downloads");
        link_command              = "xdg-open %s";
    }

    private Settings m_source;
}
}
