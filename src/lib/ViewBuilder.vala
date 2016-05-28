namespace Singularity {
public interface ViewBuilder : GLib.Object
{
   public abstract string buildHTML(Gee.List<Item> items); 
}
}
