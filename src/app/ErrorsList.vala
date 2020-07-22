using Gtk;
using Gee;

namespace Singularity {
    /**
     * Widget that displays feed update errors
     */
    [GtkTemplate (ui = "/org/df458/Singularity/ErrorsList.ui")]
    public class ErrorsList : Bin {
        /**
         * The number of recorded feeds with update errors
         */
        public uint error_count { get { return errors_by_id.size; } }

        construct {
            errors_box.set_header_func (listbox_header_separator);
        }

        /**
         * Add a new feed error
         *
         * @param f The feed that has the error
         * @param message The error message
         */
        public void add_error (Feed f, string message) {
            errors_by_id[f.id] = message;

            var label = new ErrorLabel (f, message);
            label.margin = 6;
            errors_box.add (label);
            errors_box.show_all ();
        }

        private HashMap<uint, string> errors_by_id = new HashMap<uint, string> ();

        [GtkChild]
        private ListBox errors_box;
    }
}
