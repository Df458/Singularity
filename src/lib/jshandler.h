#ifndef JS_HANDLER_H
#define JS_HANDLER_H
#include <webkit2/webkit2.h>
#include <glib-object.h>

typedef struct js_req
{
    GValue value;
}
js_req;

js_req get_js_info(WebKitJavascriptResult* res);

#endif
