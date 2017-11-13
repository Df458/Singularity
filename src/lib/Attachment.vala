using DFLib;
using SQLHeavy;

namespace Singularity
{
    public class Attachment : DataEntryGuid
    {
        public string name    { get; set; }
        public string url      { get; set; }
        public int size        { get; set; }
        public string mimetype { get; set; }

        public Attachment.from_record(SQLHeavy.Record r) throws SQLHeavy.Error
        {
            base.from_record(r);
        }

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

        public void prepare_for_db(Item owner)
        {
            set_guid(md5_guid(owner.guid+url));
        }

        protected override bool build_from_record(SQLHeavy.Record r)
        {
            try {
                set_guid(r.get_string("guid"));
                name = r.get_string("name");
                url = r.get_string("uri");
                size = r.get_int("length");
                mimetype = r.get_string("mimetype");
                return true;
            } catch(SQLHeavy.Error e) {
                warning("Cannot load attachment data: " + e.message);
                return false;
            }
        }
    }
}
