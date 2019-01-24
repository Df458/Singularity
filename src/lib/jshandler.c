/*
    Singularity - A web newsfeed aggregator
    Copyright (C) 2017  Hugues Ross <hugues.ross@gmail.com>

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
#include "jshandler.h"
#include <JavaScriptCore/JSValueRef.h>
#include <JavaScriptCore/JSContextRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include <stdlib.h>

// This function allows us to retreive the actual value of
// a WebKitJavaScriptResult, and use it in Vala code
js_req get_js_info(WebKitJavascriptResult* res) {
    JSCValue* v = webkit_javascript_result_get_js_value(res);

    js_req req;
    GValue value = G_VALUE_INIT;

    // Init the value based on type
    if(jsc_value_is_boolean(v)) {
        g_value_init(&value, G_TYPE_BOOLEAN);
        g_value_set_boolean(&value, jsc_value_to_boolean(v));
    } else if(jsc_value_is_number(v)) {
        g_value_set_double(&value, jsc_value_to_double(v));
    } else if(jsc_value_is_string(v)) {
        g_value_init(&value, G_TYPE_STRING);
        char* str = jsc_value_to_string(v);
        g_value_set_string(&value, str);
        free(str);
    } else {
        g_warning("JS result is an unrecognized type");
    }

    req.value = value;

    return req;
}
