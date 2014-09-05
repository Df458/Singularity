using Gee;

Singularity app;

public static int main (string[] args){
    Gtk.init(ref args);
    app = new Singularity(args);
    return app.run();
}
