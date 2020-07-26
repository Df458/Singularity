appsrc = files(
    'main.vala',

    'ErrorLabel.vala',
    'ErrorsList.vala',
    'FeedBuilder.vala',
    'FeedPane.vala',
    'IconLocator.vala',
    'ImportDialog.vala',
    'Init.vala',
    'ItemListEntry.vala',
    'ItemView.vala',
    'menus/ViewMenuBuilder.vala',
    'MainWindow.vala',
    'PropertiesWindow.vala',
    'SettingsView.vala',
    'Singularity.vala'
  )
appinc = [include_directories('../../build/src/lib'), include_directories('../lib')]
app_glade_target = shared_library('singularity-library', appsrc + resources,
                        dependencies : deps,
                        include_directories : appinc,
                        link_with : [libtarget, libctarget],
                        vala_args : ['--target-glib=2.38', '--gresources=../' + resource_path, '--pkg=jshandler', '--vapidir=' + vapidir])
apptarget = executable('singularity', appsrc + resources,
                        dependencies : deps,
                        include_directories : appinc,
                        link_with : [libtarget, libctarget],
                        vala_args : ['--target-glib=2.38', '--gresources=../' + resource_path, '--pkg=jshandler', '--vapidir=' + vapidir],
                        install : true)

if lint.found()
    run_target(
        'lint-app',
        command: [
            lint,
        ] + appsrc)
endif

valadoc = find_program('valadoc')
build_dir = 'valadoc'
run_target('valadoc', command : [
  valadoc,
  '--package-name', meson.project_name(),
  '--package-version', meson.project_version(),
  '-b', join_paths(meson.source_root(),'src'),
  '-o', join_paths(meson.build_root(), build_dir),
  '--pkg', gee.name(),
  '--pkg', webkitgtk.name(),
  '--pkg', soup.name(),
  '--pkg', xml.name(),
  '--pkg', sqlheavy.name(),
  '--pkg', gtk.name(),
  '--pkg', 'gcrypt',
  '--pkg', 'jshandler',
  '--pkg', 'dflib',
  '--vapidir', vapidir,
  '--vapidir', join_paths(meson.build_root(), 'subprojects/dflib/src'),
  '--verbose',
  '--force'
  ] + appsrc + libsrc,
  depends: apptarget)
