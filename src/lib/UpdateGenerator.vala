/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

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
    public class UpdateGenerator
    {
        protected Feed to_update;

        public UpdateGenerator(Feed f)
        {
            to_update = f;
        }
        
        public UpdatePackage do_update()
        {
            XmlRequest req = new XmlRequest(to_update.link);
            if(req.send() == false) {
                return new UpdatePackage.failure(to_update, req.error_message);
            }

            Xml.Doc* doc = req.doc;

            FeedProvider source = null;
            XmlRequest.ContentType type = req.determine_content_type();
            switch(type) {
                case XmlRequest.ContentType.INVALID:
                    return new UpdatePackage.failure(to_update, "Couldn't determine document content type");
                case XmlRequest.ContentType.RSS:
                    source = new RSSItemDataSource();
                    break;
                case XmlRequest.ContentType.ATOM:
                    source = new AtomItemDataSource();
                    break;
            }
            if(source == null || !source.parse_data(doc))
                return new UpdatePackage.failure(to_update, "Failed to parse feed data");

            if(!to_update.update_contents(source)) {
                return new UpdatePackage.failure(to_update, "Data was parsed, but the feed couldn't be updated");
            }

            foreach(Item? i in source.data) {
                i.owner = to_update;
            }

            return new UpdatePackage.success(to_update, source.data);
        }
    }
}
