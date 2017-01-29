appsrc = ['AddPane.vala', 'FeedBuilder.vala', 'FeedPane.vala', 'ItemView.vala', 'MainWindow.vala', 'SettingsView.vala', 'Singularity.vala', 'main.vala', 'ImportDialog.vala', 'ItemListEntry.vala']
appdeps = deps
appinc = [include_directories(meson.current_build_dir() + '/../lib'), include_directories(meson.current_source_dir() + '/../lib')]
apptarget = executable('singularity', appsrc + resources,
                        dependencies : appdeps,
                        include_directories : appinc,
                        link_with : [libtarget, libctarget],
                        vala_args : ['--target-glib=2.38', '--gresources=../' + resource_path, '--pkg=jshandler', '--vapidir=../vapi'],
                        install : true)
