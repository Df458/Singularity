namespace Singularity.Menus {
    /**
     * Creates the menu for item views
     */
    public class ViewMenuBuilder {
        /**
         * Creates and returns the menu
         */
        public static GLib.Menu get() {
            var menu = new GLib.Menu();
            menu.append ("Unread Only", "view.important");

            return menu;
        }
    }
}
