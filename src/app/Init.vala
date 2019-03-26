namespace Singularity {
    public static void init () {
        typeof (FeedPane).ensure ();
        typeof (ColumnItemView).ensure ();
        typeof (GridItemView).ensure ();
        typeof (StreamItemView).ensure ();
    }
}
