using Gtk;

namespace Singularity {
    /**
     * Helper class for finding GTK+ icons on the disk
     */
    public class IconLocator {
        /**
         * Get the path to an icon file from the given name/size
         *
         * @param icon_name The name of the icon to lookup
         * @param icon_size The desired resolution of the icon, in pixels
         *
         * @return A filepath to the icon, or "" if no icon was found
         */
        public static string get_icon (string icon_name, int icon_size) {
            IconInfo? info = IconTheme.get_default().choose_icon({icon_name}, icon_size, IconLookupFlags.FORCE_SVG);
            if (info != null) {
                return info.get_filename() ?? "";
            }

            return "";
        }
    }
}
