appsrc = ['AddPane.vala', 'FeedBuilder.vala', 'FeedPane.vala', 'ItemView.vala', 'MainWindow.vala', 'SettingsView.vala', 'Singularity.vala', 'main.vala', 'ImportDialog.vala', 'ItemListEntry.vala', 'PropertiesWindow.vala'
]
appinc = [include_directories('../../build/src/lib'), include_directories('../lib')]
apptarget = executable('singularity', appsrc + resources,
                        dependencies : deps,
                        include_directories : appinc,
                        link_with : [libtarget, libctarget],
                        vala_args : ['--target-glib=2.38', '--gresources=../' + resource_path, '--pkg=jshandler', '--vapidir=../vapi'],
                        install : true)
