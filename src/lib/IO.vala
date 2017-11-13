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
    if(node == null || node->children == null) {
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

// Converts a string containing a month (or abbreviation) into an integer.
// Since we're dealing with a date, the integer starts at one.
// If the string being passed is not valid, this function prints a warning and returns 0
// TODO: Figure out how to make this work with localization
int get_month(string month_abbr)
    ensures(0 <= result <= 12)
{
    switch(month_abbr.down()) {
        case "jan":
        case "january":
            return 1;
        case "feb":
        case "february":
            return 2;
        case "mar":
        case "march":
            return 3;
        case "apr":
        case "april":
            return 4;
        case "may":
            return 5;
        case "jun":
        case "june":
            return 6;
        case "jul":
        case "july":
            return 7;
        case "aug":
        case "august":
            return 8;
        case "sep":
        case "september":
            return 9;
        case "oct":
        case "october":
            return 10;
        case "nov":
        case "november":
            return 11;
        case "dec":
        case "december":
            return 12;
    }

    warning("%s is not a valid month", month_abbr);

    return 0;
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

// Converts a string for SQL. This replaces every ' character with its escaped form.
// If str is null, returns the string "null" which becomes a nulkl value in SQL.
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

// Hashes a string for use as a unique id
public static string md5_guid(string str)
    ensures(str != "")
{
    uchar[64] digest = new uchar[64];
    uchar[32] buffer;
    GCrypt.Hash.hash_buffer(GCrypt.Hash.Algorithm.MD5, digest, str.data);

    GCrypt.MPI mpi;

    GCrypt.Error err;
    size_t scanned;
    err = GCrypt.MPI.scan(out mpi, GCrypt.MPI.Format.USG, digest, 64, out scanned);
    if(err.code() != GCrypt.ErrorCode.NO_ERROR) {
        warning("Failed to scan MPI: %s", err.to_string());
        return "";
    }
    err = mpi.aprint(GCrypt.MPI.Format.HEX, out buffer);
    if(err.code() != GCrypt.ErrorCode.NO_ERROR) {
        warning("Failed to print MPI: %s", err.to_string());
        return "";
    }

    StringBuilder builder = new StringBuilder();
    int zero_start = -1;
    for(int i = 0; i < buffer.length; ++i) {
        if((char)buffer[i] == '0' && zero_start == -1)
            zero_start = i;
        else if((char)buffer[i] != '0' && buffer[i] != 0) {
            zero_start = -1;
        }

        builder.append_c((char)buffer[i]);
    }

    string g = builder.str;

    if(zero_start != -1)
        return g.substring(0, zero_start);

    return g;
}
}
