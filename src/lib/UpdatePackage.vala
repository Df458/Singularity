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

namespace Singularity
{
    // Represents the result of a feed update created by an UpdateGenerator
    // THis is just a container, and has no logic of its' own
    public class UpdatePackage : Object
    {
        public PackageContents contents { get; construct; }
        public Feed feed { get; construct; }
        public Gee.List<Item?>? new_items { get; construct; }
        public Gee.List<Item?>? changed_items { get; construct; }
        public string? message { get; construct; }

        public enum PackageContents
        {
            EMPTY = -1,
            FEED_UPDATE,
            ERROR_DATA,
        }

        public UpdatePackage.success(Feed f, Gee.List<Item?> i_new, Gee.List<Item?> i_change)
        {
            Object(contents: PackageContents.FEED_UPDATE, feed: f, new_items: i_new, changed_items: i_change, message: null);
        }

        public UpdatePackage.failure(Feed f, string m)
        {
            Object(contents: PackageContents.ERROR_DATA, feed: f, new_items: null, changed_items: null, message: m);
        }
    }
}
