namespace Singularity.Menus {
    /**
     * Creates the menu for item views
     */
    public class ViewMenuBuilder {
        /**
         * Creates and returns the menu
         */
        public static Menu get () {
            var menu = new Menu ();
            menu.append ("Unread Only", "view.important");

            var sort_menu = new Menu ();
            sort_menu.append ("Sort Ascending", "view.sort_type::ascending");
            sort_menu.append ("Sort Dscending", "view.sort_type::descending");
            // TODO sort types

            menu.append_submenu ("Sort", sort_menu);

            return menu;
        }
    }
}
