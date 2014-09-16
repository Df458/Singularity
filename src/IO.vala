/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2014  Hugues Ross <hugues.ross@gmail.com>

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

async Xml.Doc* getXmlData(string url) {
    SourceFunc callback = getXmlData.callback;
    Soup.Session session = new Soup.Session();
    session.use_thread_context = true;
    Soup.Message message = new Soup.Message("GET", url);
    string data = "";
    session.queue_message(message, (session_out, message_out) => {
	data = (string)message_out.response_body.data;
	Idle.add((owned) callback);
    });
    yield;
    Xml.Doc* xml_doc = Xml.Parser.parse_doc(data);
    if(xml_doc == null && data != null) {
	data = data.split("<!DOCTYPE html")[0];
	xml_doc = Xml.Parser.parse_doc(data);
    }
    return xml_doc;
}

string getNodeContents(Xml.Node* node, bool atom = false) {
    string output = "";
    if(node == null || node->children == null){
	stderr.printf("Unexpected null pointer. Ignoring...\n");
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
		output = dumpXml(node);
	    break;
	}
    } else if(node->children->type != Xml.ElementType.TEXT_NODE && node->children->type != Xml.ElementType.CDATA_SECTION_NODE) {
	stderr.printf("Unexpected element <%s> detected.", node->children->name);
    } else {
	output = node->children->get_content();
    } 
    return output;
}

int getMonth(string month_abbr) {
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

string dumpXml(Xml.Node* node) {
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
	    xml_str += dumpXml(n);
	xml_str += "</" + node->name + ">";
    }
    return xml_str;
}
