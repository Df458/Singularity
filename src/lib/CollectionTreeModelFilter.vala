/*
    Singularity - A web newsfeed aggregator
    Copyright (C) 2019  Hugues Ross <hugues.ross@gmail.com>

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
using Gtk;

namespace Singularity {
    public class CollectionTreeModelFilter : AdvancedTreeModelFilter {
        public string search_text {
            get {
                return _search_text;
            }
            set {
                if (_search_text != value) {

                    if (value != null) {
                        _search_text = value.down ();
                    } else {
                        _search_text = null;
                    }
                    _has_search_text = (value != null && value != "");
                    filter ();
                }
            }
        }
        private string _search_text = "";

        public bool has_search_text { get; private set; default = false; }

        public CollectionTreeModelFilter (CollectionTreeStore model) {
            base (model, null, CollectionTreeStore.Column.VISIBLE);

            filter ();
        }

        public override TreeFilterResult is_visible (TreeIter iter) {
            string title;
            CollectionNode node;
            child_model.get (iter,
                    CollectionTreeStore.Column.TITLE, out title,
                    CollectionTreeStore.Column.NODE, out node);

            bool is_match = !has_search_text || title.down ().contains (search_text);

            return is_match ? TreeFilterResult.SHOW : TreeFilterResult.SHOW_WITH_CHILDREN;
        }
    }
}
