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
string get_node_contents(Xml.Node* node, bool atom = false)
{
    string output = "";
    if(node == null || node->children == null){
            // TODO: verbose
        /* if(verbose) */
        /*     stderr.printf("Unexpected null pointer. Ignoring...\n"); */
        return output;
    }
    if(atom && node->has_prop("type") != null && node->has_prop("type")->children->content != "text") {
	switch(node->has_prop("type")->children->content) {
//:TODO: 05.09.14 11:25:16, Hugues Ross
// Add support for HTML escapes
	    case "html":
            output = node->children->get_content();
	    break;

	    case "xhtml":
            output = dump_xml_node(node);
	    break;
	}
    } else if(node->children->type != Xml.ElementType.TEXT_NODE && node->children->type != Xml.ElementType.CDATA_SECTION_NODE) {
        stderr.printf("Unexpected element <%s> detected.", node->children->name);
    } else {
        output = node->children->get_content();
    } 

    output = output.replace("\"//", "\"http://");
    return output;
}

int get_month(string month_abbr)
{
    switch(month_abbr) {
	case "Jan":
	    return 1;
	case "Feb":
	    return 2;
	case "Mar":
	    return 3;
	case "Apr":
	    return 4;
	case "May":
	    return 5;
	case "Jun":
	    return 6;
	case "Jul":
	    return 7;
	case "Aug":
	    return 8;
	case "Sep":
	    return 9;
	case "Oct":
	    return 10;
	case "Nov":
	    return 11;
	case "Dec":
	    return 12;
    }
    return -1;
}

public static string dump_xml_node(Xml.Node* node)
{
    string xml_str = "";

    if(node->type == Xml.ElementType.TEXT_NODE || node->type == Xml.ElementType.CDATA_SECTION_NODE)
        return node->children->get_content();
    xml_str += "<" + node->name;
    for(Xml.Attr* a = node->properties; a != null; a = a->next)
        xml_str += " " + a->name + " =  \"" + a->children->get_content() + "\"";
    if(node->children == null)
        xml_str += "/>";
    else {
        xml_str += ">";
        for(Xml.Node* n = node->children; n != null; n = n->next)
            xml_str += dump_xml_node(n);
        xml_str += "</" + node->name + ">";
    }
    return xml_str;
}

public static string sql_str(string? str)
{
    if(str == null)
        return "null";

    StringBuilder sb = new StringBuilder("'");
    sb.append_printf("%s'", str.replace("'", "''"));

    return sb.str;
}

public static string strip_htm(string str)
{
    return str.replace("<", "&lt;").replace(">", "&gt;");
}
}
