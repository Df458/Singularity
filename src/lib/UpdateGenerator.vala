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
    // This class handles a single feed update, by requesting the data and running the appropriate parser.
    public class UpdateGenerator
    {
        protected Feed to_update;

        public UpdateGenerator(Feed f, Soup.Session s)
        {
            to_update = f;
            m_session = s;
        }
        
        // Runs the actual feed update. This returns a package containing either the resulting update data, or an error message
        public UpdatePackage do_update()
        {
            XmlRequest req = new XmlRequest(to_update.link, m_session);
            if(req.send() == false) {
                return new UpdatePackage.failure(to_update, req.error_message);
            }

            GXml.GDocument doc = req.doc;

            FeedProvider source = req.get_provider_from_request();

            if(source == null)
                return new UpdatePackage.failure(to_update, "Couldn't determine document content type");
            if(!source.parse_data(doc))
                return new UpdatePackage.failure(to_update, "Failed to parse feed data");
            if(!to_update.update_contents(source))
                return new UpdatePackage.failure(to_update, "Data was parsed, but the feed couldn't be updated");

            Gee.List<Item?> new_items = new Gee.ArrayList<Item?>();
            Gee.List<Item?> changed_items = new Gee.ArrayList<Item?>();

            foreach(Item? i in source.data) {
                Item? i2 = to_update.get_item(i.weak_guid, false);

                if(i2 == null) {
                    new_items.add(i);
                    to_update.add_item(i);

                    i.content = html_to_generic(i.content, req.get_base_uri());
                } else if(!i.equals(i2)) {
                    changed_items.add(i);
                }
            }

            return new UpdatePackage.success(to_update, new_items, changed_items);
        }

        private Soup.Session m_session;
    }
}
