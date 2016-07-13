[CCode(cheader_filename = "jshandler.h")]
namespace JSHandler {
    [CCode (cname = "js_req", destroy_function = "", has_type_id = "false")]
    [SimpleType]
    public struct JavascriptAppRequest {
        [CCode (cname = "value")]
        GLib.Value returned_value;
    }

    [CCode(cname = "get_js_info")]
    public JavascriptAppRequest get_js_info(WebKit.JavascriptResult res);
}
