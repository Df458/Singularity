appsrc = [
    'main.vala',

    'FeedBuilder.vala',
    'FeedPane.vala',
    'ImportDialog.vala',
    'ItemListEntry.vala',
    'ItemView.vala',
    'MainWindow.vala',
    'PropertiesWindow.vala',
    'SettingsView.vala',
    'Singularity.vala'
]
appinc = [include_directories('../../build/src/lib'), include_directories('../lib')]
apptarget = executable('singularity', appsrc + resources,
                        dependencies : deps,
                        include_directories : appinc,
                        link_with : [libtarget, libctarget],
                        vala_args : ['--target-glib=2.38', '--gresources=../' + resource_path, '--pkg=jshandler', '--vapidir=../vapi'],
                        install : true)
