namespace Singularity {
public interface ViewBuilder : GLib.Object
{
   public abstract string buildPageHTML(Gee.List<Item> items, int limit); 
   public abstract string buildItemHTML(Item item, int id); 
}
}
