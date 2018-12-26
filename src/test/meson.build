testsrc = [
    'main.vala',

    'PersonTest.vala',
    'TestSuite.vala',
    'UnitTest.vala',
]
testinc = [include_directories('../../build/src/lib'), include_directories('../lib')]
testtarget = executable('singularity-test', testsrc,
                        dependencies : deps,
                        include_directories : testinc,
                        link_with : [libtarget, libctarget],
                        vala_args : ['--target-glib=2.38', '--gresources=../' + resource_path, '--pkg=jshandler', '--vapidir=../vapi'])
test('Singularity Tests', testtarget)

if lint.found()
    run_target(
        'lint-test',
        command: [
            lint,
        ] + testsrc)
endif
