mkxp_shaders = files(
    'common.h',
    'minimal.vert',
    'flatColor.frag',
    'simple.frag',
    'simple.vert',
    'simpleColor.frag',
    'simpleColor.vert',
    'simpleAlpha.frag',
    'simpleAlphaUni.frag',
    'simpleMatrix.vert',
    'bitmapBlit.frag',
    'sprite.frag',
    'sprite.vert',
    'plane.frag',
    'hue.frag',
    'gray.frag',
    'trans.frag',
    'transSimple.frag',
    'blur.frag',
    'blurH.vert',
    'blurV.vert',
    'tilemap.frag',
    'tilemap.vert',
    'tilemapvx.vert',
    'flashMap.frag',
    'bicubic.frag',
    'lanczos3.frag',
    'obscured.frag'
)

# xBRZ shader is licensed under GPLv3, so checking for enabled OpenSSL support
# as it's also requires to be GPLv3 compatable
if mkxp_gplv3 == true
    mkxp_shaders += files('xbrz.frag')
endif

mkxp_shaders_xxd = xxd_gen.process(mkxp_shaders)

mkxp_sources += mkxp_shaders_xxd
