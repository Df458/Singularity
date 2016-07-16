appsrc = ['AddPane.vala', 'FeedBuilder.vala', 'FeedPane.vala', 'FeedSettingsPane.vala', 'ItemView.vala', 'JSStr.vala', 'MainWindow.vala', 'RuleEntry.vala', 'SettingsPane.vala', 'Singularity.vala', 'main.vala']
appdeps = deps
appinc = [include_directories(meson.current_build_dir() + '/../lib'), include_directories(meson.current_source_dir() + '/../lib')]
apptarget = executable('singularity', appsrc,
                        dependencies : appdeps,
                        include_directories : appinc,
                        link_with : [libtarget, libctarget],
                        vala_args : ['--pkg=jshandler', '--vapidir=../vapi'],
                        install : true)
