win = import('windows')

# Define install script parameters
install_gplv3 = '0'

if mkxp_gplv3 == true
    install_gplv3 = '1'
endif

# Windows install script
if mkxp_steam
    meson.add_install_script('install.sh', install_gplv3, steamworks_libpath, steamworks_libname)
else
    meson.add_install_script('install.sh', install_gplv3, '', '')
endif

win_rc_args = []

if is_debug
    win_rc_args += '-D_DEBUG'
endif

win_copyright_license = 'Licensed under '
if mkxp_gplv3
    win_copyright_license += 'GPL-3.0.'
else
    win_copyright_license += 'GPL-2.0 or later.'
endif

win_config = configuration_data()
win_config.set('PROJECT_NAME', meson.project_name())
win_config.set('PROJECT_VERSION', meson.project_version())
win_config.set('VERSION_MAJOR', version_major)
win_config.set('VERSION_MINOR', version_minor)
win_config.set('VERSION_PATCH', version_patch)
win_config.set('AUTHOR', 'hat_kid')
win_config.set('COPYRIGHT', '(c) 2024, hat_kid. @0@'.format(win_copyright_license))
win_config.set('COMMENT', '')

if git_hash != '0000000000000000000000000000000000000000'
    win_config.set('COMMENT', 'Built from Git hash: @0@'.format(git_hash))
endif

# ModShot Windows executable resources
win_mkxp_config = configuration_data()
win_mkxp_config.merge_from(win_config)
win_mkxp_config.set('FILE_DESC', 'OneShot')
win_mkxp_config.set('PRODUCT_NAME', meson.project_name())
win_mkxp_config.set('FILENAME', '@0@.exe'.format(mkxp_name))
win_mkxp_config.set('MANIFEST_FILE', 'manifest.xml')
win_mkxp_config.set('MANIFEST_DESC', '@0@ - Advanced OneShot (2016) Game Engine'.format(meson.project_name()))

win_mkxp_xml = configure_file(
    configuration: win_mkxp_config,
    input: 'manifest.xml.in',
    output: 'manifest.xml'
)

win_mkxp_rc = configure_file(
    configuration: win_mkxp_config,
    input: 'resource.rc.in',
    output: 'resource.rc'
)

win_mkxp_resources = win.compile_resources(
    win_mkxp_rc,
    args: win_rc_args,
    include_directories: [include_directories('.')],
    depend_files: [
        'icon.ico',
        win_mkxp_xml
    ]
)

mkxp_sources += win_mkxp_resources

# Steamshim Windows executable resources
if mkxp_steam
    if get_option('steamshim_debug') == true and '-D_DEBUG' not in win_rc_args
        win_rc_args += '-D_DEBUG'
    endif

    win_steamshim_config = configuration_data()
    win_steamshim_config.merge_from(win_config)
    win_steamshim_config.set('FILE_DESC', '@0@ Steamshim'.format(meson.project_name()))
    win_steamshim_config.set('PRODUCT_NAME', 'Steamshim')
    win_steamshim_config.set('FILENAME', '@0@.exe'.format(steamshim_name))
    win_steamshim_config.set('MANIFEST_FILE', 'manifest-steamshim.xml')
    win_steamshim_config.set('MANIFEST_DESC', 'Steamshim - Bridge between a child process and the Steamworks SDK')

    win_steamshim_xml = configure_file(
        configuration: win_steamshim_config,
        input: 'manifest.xml.in',
        output: 'manifest-steamshim.xml'
    )

    win_steamshim_rc = configure_file(
        configuration: win_steamshim_config,
        input: 'resource.rc.in',
        output: 'resource-steamshim.rc'
    )

    win_steamshim_resources = win.compile_resources(
        win_steamshim_rc,
        args: win_rc_args,
        include_directories: [include_directories('.')],
        depend_files: [
            'icon.ico',
            win_steamshim_xml
        ]
    )

    steamshim_sources += win_steamshim_resources
endif
