async Xml.Doc* getXmlData(string url) {
    SourceFunc callback = getXmlData.callback;
    Soup.Session session = new Soup.Session();
    session.use_thread_context = true;
    Soup.Message message = new Soup.Message("GET", url);
    //stdout.printf("Loading data from %s...\n", url);
    string data = "";
    session.queue_message(message, (session_out, message_out) => {
	data = (string)message_out.response_body.data;
	Idle.add((owned) callback);
    });
    yield;
    //stdout.printf("Data: %s\n", data);
    Xml.Doc* xml_doc = Xml.Parser.parse_doc(data);
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
	    // TODO: Add escape support
	    case "html":
		output = node->children->get_content();
	    break;

	    case "xhtml":
		output = dumpXml(node);
		stderr.printf(output);
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
