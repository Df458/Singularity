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
#ifndef JS_HANDLER_H
#define JS_HANDLER_H
#include <webkit2/webkit2.h>
#include <glib-object.h>

// Container for WebKitJavaScriptResults
typedef struct js_req
{
    GValue value;
}
js_req;

// This function allows us to retreive the actual value of
// a WebKitJavaScriptResult, and use it in Vala code
js_req get_js_info(WebKitJavascriptResult* res);

#endif
