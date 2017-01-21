project('singularity', ['vala', 'c'],
        version : '0.3',
        license : 'GPLv3')

gnome = import('gnome')
glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')
gee = dependency('gee-0.8')
dflib = dependency('dflib')
webkitgtk = dependency('webkit2gtk-4.0')
soup = dependency('libsoup-2.4')
xml = dependency('libxml-2.0')
sqlheavy = dependency('sqlheavy-0.1')

resource_path = 'data/singularity.gresource.xml'
resources = gnome.compile_resources('resources', resource_path, source_dir : 'data')

deps = [glib, gobject, gee, dflib, webkitgtk, soup, xml, sqlheavy]

subdir('src/lib')
#subdir('src/test')
subdir('src/app')
