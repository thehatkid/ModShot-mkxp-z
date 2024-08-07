project(
    'mkxp-z',
    ['cpp', 'c'],
    version: '2.5.0',
    license: 'GPL-2.0 or later',
    meson_version: '>=0.56.0',
    default_options: [
        'cpp_std=c++14',
        'c_std=c11',
        'warning_level=1',
        'buildtype=release',
        'b_ndebug=if-release',
        'bindir=.'
    ]
)

host_system = host_machine.system()
host_cpu = host_machine.cpu()
host_arch = host_machine.cpu_family()

# We have Xcode project in "macos" directory to build mkxp-z for macOS systems
if host_system == 'darwin'
    error('This Meson project currently does not supports macOS building')
endif

fs = import('fs')

cc = meson.get_compiler('c')
cxx = meson.get_compiler('cpp')

# Get major, minor and patch version numbers
version_split = meson.project_version().split('.')
version_major = version_split[0]
version_minor = version_split[1]
version_patch = version_split[2]

is_debug = get_option('buildtype').startswith('debug')
is_crossbuild = meson.is_cross_build()
is_64bit = host_arch in ['x86_64', 'ia64', 'aarch64', 'ppc64', 'riscv64', 'mips64', 'wasm64', 'loongarch64']
is_static = get_option('static')
force_32bit = get_option('force_32bit')

appimagetool = get_option('appimagetool')

# Get dependencies install prefix from MKXPZ_PREFIX vars.sh variable
mkxp_deps_prefix = run_command('sh', '-c', 'echo $MKXPZ_PREFIX', check: true).stdout().strip()

if mkxp_deps_prefix == '' and host_system != 'darwin'
    error('Please source vars.sh file: source @0@/vars.sh'.format(host_system))
endif

# Get XXD program for embedding assets and shaders into executable
xxd = find_program('xxd', native: true, required: true)

xxd_gen = generator(
    xxd,
    arguments: ['-i', '@INPUT@', '@OUTPUT@'],
    output: '@PLAINNAME@.xxd'
)

# Get latest Git commit hash
git_hash = '0000000000000000000000000000000000000000'
if fs.is_dir('.git')
    git = find_program('git', required: false)
    if git.found()
        git_hash = run_command(git, 'rev-parse', 'HEAD', capture: true, check: true).stdout().strip()
    else
        warning('Unable to get Git; fallback MKXPZ_GIT_HASH to zeros')
    endif
else
    warning('".git" directory was not found; fallback MKXPZ_GIT_HASH to zeros')
endif

# Define global variables for mkxp-z target
mkxp_name = meson.project_name()
mkxp_sources = []
mkxp_includes = []
mkxp_dependencies = []
mkxp_cflags = []
mkxp_ldflags = []

# Tell compiler that we want build in 32-bit mode
if force_32bit
    mkxp_cflags += '-m32'
endif

# Set MKXPZ_DEBUG define if we building in Debug build mode
if is_debug
    mkxp_cflags += '-DMKXPZ_DEBUG'
endif

# Add mkxp-z C flags
mkxp_cflags += [
    '-DMKXPZ_BUILD_MESON',
    '-DMKXPZ_VERSION="@0@"'.format(meson.project_version()),
    '-DMKXPZ_GIT_HASH="@0@"'.format(git_hash),
    '-DMKXPZ_INIT_GL_LATER'
]

if get_option('require_nanosleep') == 'auto'
    if host_system != 'windows'
        mkxp_cflags += '-DMKXPZ_NANOSLEEP'
    endif
elif get_option('require_nanosleep') == 'true'
    mkxp_cflags += '-DMKXPZ_NANOSLEEP'
endif

if get_option('simple_smooth_scaling') == true
    mkxp_cflags += '-DMKXPZ_SIMPLE_SMOOTH_SCALING'
endif

# Suppress compiler warnings
# TODO: Reduce no-warning flags and fix warnings in code sources
warn_args = [
    '-Wno-reorder',
    '-Wno-uninitialized',
    '-Wno-unknown-pragmas',
    '-Wno-non-virtual-dtor',
    '-Wno-stringop-truncation'
]

if cxx.get_id() == 'clang'
    warn_args += [
        '-Wno-undefined-var-template',
        '-Wno-delete-non-abstract-non-virtual-dtor'
    ]
endif

if host_system == 'windows' and cxx.get_id() != 'clang'
    mkxp_cflags += '-masm=intel'
endif

# Link statically libgcc, libstdc++, and winpthread/pthread
if is_static
    if host_system == 'windows'
        mkxp_ldflags += [
            '-static-libgcc',
            '-static-libstdc++',
            '-Wl,-Bstatic',
            '-lgcc',
            '-lstdc++',
            '-lpthread',
            '-Wl,-Bdynamic'
        ]
    elif host_system == 'linux'
        mkxp_ldflags += [
            '-static-libgcc',
            '-static-libstdc++'
        ]
    endif
endif

# Add suffix of CPU arch to executable filename on Linux
if host_system == 'linux' and appimagetool == ''
    mkxp_name += '.' + host_cpu
endif

mkxp_gplv3 = false
if get_option('https') == true
    mkxp_gplv3 = true
endif

if get_option('workdir_current') == true
    mkxp_cflags += '-DWORKDIR_CURRENT'
endif

if get_option('cxx11_experimental') == true
    mkxp_cflags += '-DMKXPZ_EXP_FS'
endif

if get_option('cjk_font') == true
    mkxp_cflags += '-DMKXPZ_CJK_FONT'
endif

mkxp_miniffi = false
if get_option('miniffi') == true
    mkxp_miniffi = true
    mkxp_cflags += '-DMKXPZ_MINIFFI'
endif

# OpenGL and OpenGL ES
gl_backend = get_option('gl_backend')
if gl_backend == 'gles'
    mkxp_cflags += '-DGLES2_HEADER'
elif gl_backend == 'gl'
    mkxp_dependencies += dependency('GL')
else
    error('Unknown "gl_backend" option value: @0@'.format(gl_backend))
endif

# Steamworks SDK
mkxp_steam = false
steamworks_path = get_option('steamworks_sdk')
steamworks_libpath = ''
if steamworks_path != ''
    steamworks_bindir = ''
    steamworks_libname = 'steam_api'

    # Determine library name and path for each platform
    if host_system == 'windows'
        if is_64bit
            steamworks_bindir = 'win64'
            steamworks_libname += '64'
        endif
    elif host_system == 'linux'
        if is_64bit
            steamworks_bindir = 'linux64'
        else
            steamworks_bindir = 'linux32'
        endif
    elif host_system == 'darwin'
        steamworks_bindir = 'osx'
    else
        error('Unsupported host system for Steamworks SDK')
    endif

    steamworks_inc = include_directories(steamworks_path / 'public')
    steamworks_libpath = steamworks_path / 'redistributable_bin' / steamworks_bindir
    steamworks_lib = cc.find_library(
        steamworks_libname,
        dirs: [steamworks_libpath],
        required: false
    )

    if steamworks_lib.found()
        mkxp_steam = true

        # Append with Steamshim sources
        mkxp_sources += files('steamshim/steamshim_child.c')
        mkxp_includes += include_directories('steamshim')
        mkxp_cflags += '-DMKXPZ_STEAM'
    else
        warning('Could not locate Steamworks SDK in @0@'.format(steam_libpath))
        warning('Steam features will be remain disabled')
    endif
endif

# Build Steamshim if we have Steamworks SDK
if mkxp_steam
    # Define global variables for Steamshim target
    steamshim_name = 'steamshim'
    steamshim_sources = [
        files(
            'steamshim/steamshim_parent.cpp'
        )
    ]
    steamshim_dependencies = [
        steamworks_lib
    ]
    steamshim_includes = [
        steamworks_inc
    ]
    steamshim_cflags = [
        '-DGAME_LAUNCH_NAME="@0@"'.format(mkxp_name)
    ]
    steamshim_ldflags = []
    steamshim_win_subsystem = 'windows,6.0'

    if is_static
        if host_system == 'windows'
            steamshim_ldflags += [
                '-static'
            ]
        else
            steamshim_ldflags += [
                '-static-libgcc',
                '-static-libstdc++'
            ]
        endif
    endif

    if get_option('steam_appid') != ''
        steamshim_cflags += '-DSTEAM_APPID=@0@'.format(get_option('steam_appid'))
    endif

    # Set debug define and Console subsystem version for Steamshim
    if get_option('steamshim_debug') == true
        steamshim_cflags += '-DSTEAMSHIM_DEBUG'
        steamshim_win_subsystem = 'console,6.0'
    endif
endif

# Include subdirectories
subdir('assets')
subdir('shader')
subdir('src')
subdir('binding')

if host_system == 'windows'
    subdir('windows')
elif host_system == 'linux'
    subdir('linux')
endif

# Steamshim executable target
if mkxp_steam
    executable(
        steamshim_name,
        sources: steamshim_sources,
        include_directories: steamshim_includes,
        dependencies: steamshim_dependencies,
        c_args: steamshim_cflags,
        cpp_args: steamshim_cflags,
        link_args: steamshim_ldflags,
        install: (appimagetool == ''),
        win_subsystem: steamshim_win_subsystem
    )
endif

# mkxp-z executable target
executable(
    mkxp_name,
    sources: mkxp_sources,
    include_directories: mkxp_includes,
    dependencies: mkxp_dependencies,
    c_args: mkxp_cflags,
    cpp_args: mkxp_cflags + warn_args,
    link_args: mkxp_ldflags,
    install: (appimagetool == ''),
    win_subsystem: 'windows,6.0'
)
