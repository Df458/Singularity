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
using DFLib;
using SQLHeavy;

namespace Singularity
{
    // Represents a person, used for displaying item authors
    public class Person : DataEntryGuid
    {
        public string? name     { get; set; }
        public string? url      { get; set; }
        public string? email    { get; set; }
        public bool    is_valid { get { return (name != null && name.length != 0) || (email != null && email.length != 0); } }

        public Person(string? name, string? url = null, string? email = null)
        {
            this.name  = name;
            this.url   = url;
            this.email = email;
        }

        public Person.from_xml(GXml.Node node)
        {
            var name_list = node.get_elements_by_name("name");
            if(name_list.size > 0)
                name = name_list[0].value;

            var uri_list = node.get_elements_by_name("uri");
            if(uri_list.size > 0)
                url = uri_list[0].value;

            var email_list = node.get_elements_by_name("email");
            if(email_list.size > 0)
                email = email_list[0].value;
        }

        public Person.from_record(SQLHeavy.Record r) throws SQLHeavy.Error
        {
            base.from_record(r);
        }

        // Stubs for implementing DataEntryGuid
        public override Query? insert(Queryable q)
        {
            return null;
        }
        public override Query? update(Queryable q)
        {
            return null;
        }
        public override Query? remove(Queryable q)
        {
            return null;
        }

        // Prepares and hashes this object's guid
        public void prepare_for_db(Item owner)
        {
            set_guid(md5_guid(to_string()));
        }

        public string to_string()
        {
            StringBuilder builder = new StringBuilder();
            if(name != null)
                builder.append(name);
            else if(url != null)
                builder.append(url);

            if(email != null)
                builder.append_printf(" (%s)", email);

            return builder.str;
        }

        // Tries to populate data from a database record
        // Returns true if successful
        protected override bool build_from_record(SQLHeavy.Record r)
        {
            try {
                set_guid(r.get_string("guid"));
                name     = r.get_string("name");
                url      = r.get_string("url");
                email    = r.get_string("email");
                return true;
            } catch(SQLHeavy.Error e) {
                warning("Cannot load author data: " + e.message);
                return false;
            }
        }
    }
}
