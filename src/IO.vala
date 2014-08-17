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

string getNodeContents(Xml.Node* node) {
    string output = "";
    if(node->children->type != Xml.ElementType.TEXT_NODE) {
	stderr.printf("Unexpected element <%s> detected.", node->children->name);
    } else {
	output = node->children->get_content();
    } 
    return output;
}
