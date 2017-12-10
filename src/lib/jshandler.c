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
