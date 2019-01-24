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

using SQLHeavy;

public enum RequestPriority {
    INVALID = -1,
    LOW,
    MEDIUM,
    HIGH,
    COUNT,
    DEFAULT = LOW
}

public enum RequestStatus {
    COMPLETED = 0,
    FAILED,
    CONTINUE,
    COUNT,
    DEFAULT = COMPLETED
}

// The interface used by all classes that handle database IO
public interface DatabaseRequest : GLib.Object {
    public abstract Query build_query (Database db);
    public abstract RequestStatus process_result (QueryResult res);
    public signal void processing_complete ();
}
