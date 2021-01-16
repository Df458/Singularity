app_settings = files(
    'org.df458.singularity.gschema.xml'
)
gnome.compile_schemas(build_by_default: true, depend_files: app_settings)
install_data(app_settings, install_dir: '/usr/share/glib-2.0/schemas')
