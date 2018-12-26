project('singularity', ['vala', 'c'],
        version : '0.3',
        license : 'GPLv3')

vala = meson.get_compiler('vala')
gcc = meson.get_compiler('c')

lint = find_program('io.elementary.vala-lint', required: false)

gnome = import('gnome')
glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')
gcrypt_v = vala.find_library('gcrypt', dirs: join_paths(meson.current_source_dir(), 'vapi'))
gcrypt_c = gcc.find_library('gcrypt')
gee = dependency('gee-0.8')
dflib = subproject('dflib').get_variable('dflib')
webkitgtk = dependency('webkit2gtk-4.0')
soup = dependency('libsoup-2.4')
xml = dependency('gxml-0.16')
sqlheavy = dependency('sqlheavy-0.1')
sqlite = dependency('sqlite3')

resource_path = 'data/singularity.gresource.xml'
resources = gnome.compile_resources('resources', resource_path, source_dir : 'data')
install_data(['data/org.df458.singularity.gschema.xml'], install_dir: '/usr/share/glib-2.0/schemas')

deps = [glib, gobject, gcrypt_v, gcrypt_c, gee, dflib, webkitgtk, soup, xml, sqlheavy]

subdir('src/lib')
subdir('src/app')
subdir('src/test')

run_command('ctags', '-R', 'src')
