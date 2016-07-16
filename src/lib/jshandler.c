#include "jshandler.h"
#include <JavaScriptCore/JSValueRef.h>
#include <JavaScriptCore/JSContextRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include <stdlib.h>

js_req get_js_info(WebKitJavascriptResult* res)
{
    JSValueRef v = webkit_javascript_result_get_value(res);
    JSGlobalContextRef c = webkit_javascript_result_get_global_context(res);
    JSType type = JSValueGetType(c, v);

    js_req req;
    GValue value = G_VALUE_INIT;

    switch(type) {
        case kJSTypeBoolean:
            g_value_init(&value, G_TYPE_BOOLEAN);
            g_value_set_boolean(&value, JSValueToBoolean(c, v));
            break;
        case kJSTypeNumber:
            g_value_init(&value, G_TYPE_DOUBLE);
            // TODO: Check for exceptions
            g_value_set_double(&value, JSValueToNumber(c, v, NULL));
            break;
        case kJSTypeString:
            g_value_init(&value, G_TYPE_STRING);
            // TODO: Check for exceptions
            JSStringRef jstr = JSValueToStringCopy(c, v, NULL);
            size_t len = JSStringGetLength(jstr);
            char* str = calloc(len + 1, sizeof(char));
            JSStringGetUTF8CString(jstr, str, len + 1);

            g_value_set_string(&value, str);

            free(str);

            break;
        default:
            // TODO: Properly handle unexpected values
            break;
    }

    req.value = value;

    return req;
}
