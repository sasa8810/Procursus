ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += irrlichtmt
IRRLITCHTMT_VERSION := 1.9.0mt5
DEB_IRRLITCHTMT_V   ?= $(IRRLITCHTMT_VERSION)

irrlichtmt-setup: setup
	$(call GITHUB_ARCHIVE,minetest,irrlicht,$(IRRLITCHTMT_VERSION),$(IRRLITCHTMT_VERSION))
	$(call EXTRACT_TAR,irrlicht-$(IRRLITCHTMT_VERSION).tar.gz,irrlicht-$(IRRLITCHTMT_VERSION),irrlichtmt)
	$(call DO_PATCH,irrlichtmt-ios,irrlichtmt,-p1)
	#sed -i -e 's/#define _IRR_COMPILE_WITH_OGLES1_/#define _IRR_COMPILE_WITH_OGLES2_/g' $(BUILD_WORK)/irrlichtmt/include/IrrCompileConfig.h
ifeq (,$(findstring darwin, $(MEMO_TARGET)))
	#sed -i -e 's/#define _IRR_COMPILE_WITH_OSX_DEVICE_//' $(BUILD_WORK)/irrlichtmt/include/IrrCompileConfig.h
endif
	sed -i 's|#include <SDL|#include <SDL2/SDL|' $(BUILD_WORK)/irrlichtmt/source/Irrlicht/{CIrrDeviceSDL.{h,cpp},os.cpp,COpenGLCommon.h}
	sed -i '1s|^|#define GL_GLEXT_PROTOTYPES 1\n#include <GL/glcorearb.h>\n#include <GL/glext.h>\n#include <GL/gl.h>\n|' $(BUILD_WORK)/irrlichtmt/source/Irrlicht/{COpenGL*,COGLES2*}
	sed -i '1s|^|#define GL_POINT_DISTANCE_ATTENUATION 0x8129\n#define GL_POINT_SIZE_MAX 0x8127\n#define GL_COORD_REPLACE 0x8862\n#define GL_FOG_COORDINATE_SOURCE 0x8450\n#define GL_FRAGMENT_DEPTH 0x8452\n|' $(BUILD_WORK)/irrlichtmt/source/Irrlicht/COpenGLDriver.cpp
	sed -i '1s|^|#define GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT 0x8CD9\n#define GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT\n|' $(BUILD_WORK)/irrlichtmt/source/Irrlicht/COpenGLCoreRenderTarget.h
	sed -i '1s|^|#define GL_GENERATE_MIPMAP_HINT 0x8192\n|' $(BUILD_WORK)/irrlichtmt/source/Irrlicht/COGLES2Driver.cpp
	sed -i 's/FeatureAvailable\[IRR_EXT_texture_lod_bias\]/FeatureAvailable\[IRR_GL_EXT_texture_lod_bias\]/' $(BUILD_WORK)/irrlichtmt/source/Irrlicht/COGLES2ExtensionHandler.cpp
	mkdir -p $(BUILD_WORK)/irrlichtmt/build

ifneq ($(wildcard $(BUILD_WORK)/irrlichtmt/.build_complete),)
irrlichtmt:
	@echo "Using previously built irrlichtmt."
else
irrlichtmt: irrlichtmt-setup mesa libx11 libjpeg-turbo libpng16 sdl2 libglu
	cd $(BUILD_WORK)/irrlichtmt/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DOPENGLES_LIBRARY=-lGLESv2 \
		-DOPENGL_INCLUDE_DIR='$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/GL' \
		..
	+sed -i -e 's/-framework Cocoa/-framework CoreFoundation/g' -e 's/-framework OpenGLES/-lGL/g' -e 's/-framework OpenGL//g' $(BUILD_WORK)/irrlichtmt/build/source/Irrlicht/CMakeFiles/IrrlichtMt.dir/link.txt
	+$(MAKE) -C $(BUILD_WORK)/irrlichtmt/build
	+$(MAKE) -C $(BUILD_WORK)/irrlichtmt/build install \
		DESTDIR="$(BUILD_STAGE)/irrlichtmt"
	$(call AFTER_BUILD,copy)
endif

irrlichtmt-package: irrlichtmt-stage
	# irrlichtmt.mk Package Structure
	rm -rf $(BUILD_DIST)/libirrlichtmt{1.9,-dev}
	mkdir -p $(BUILD_DIST)/libirrlichtmt{1.9,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# irrlichtmt.mk Prep irrlichtmt1.9
	cp -a $(BUILD_STAGE)/irrlichtmt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libIrrlichtMt.1.9{,.0}.dylib $(BUILD_DIST)/libirrlichtmt1.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# irrlichtmt.mk Prep irrlichtmt-dev
	cp -a $(BUILD_STAGE)/irrlichtmt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libIrrlichtMt.dylib,cmake} $(BUILD_DIST)/libirrlichtmt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/irrlichtmt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libirrlichtmt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# irrlichtmt.mk Sign
	$(call SIGN,libirrlichtmt1.9,general.xml)

	# irrlichtmt.mk Make .debs
	$(call PACK,libirrlichtmt1.9,DEB_IRRLITCHTMT_V)
	$(call PACK,libirrlichtmt-dev,DEB_IRRLITCHTMT_V)

	# irrlichtmt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libirrlichtmt{1.9,-dev}

.PHONY: irrlichtmt irrlichtmt-package
