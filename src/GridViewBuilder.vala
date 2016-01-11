// TODO: Implement this
class GridViewBuilder : ViewBuilder
{
    string opening_section = "";
    string closing_section = "";

    public GridViewBuilder()
    {
    }

    public string buildHTML(Gee.ArrayList<Item> items)
    {
        StringBuilder builder = new StringBuilder(opening_section);
        foreach(Item i in items) {
        }

        builder.append(closing_section);

        return builder.str;
    }
}
