ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += poppler
POPPLER_VERSION := 22.06.0
DEB_POPPLER_V   ?= $(POPPLER_VERSION)

poppler-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://poppler.freedesktop.org/poppler-$(POPPLER_VERSION).tar.xz
	$(call EXTRACT_TAR,poppler-$(POPPLER_VERSION).tar.xz,poppler-$(POPPLER_VERSION),poppler)
	sed -i -e 's/pread64(/pread(/g' -e 's/lseek64(/lseek(/g' $(BUILD_WORK)/poppler/goo/gfile.cc
	sed -i -e 's|#include <openjpeg.h>|#include <openjpeg-2.4/openjpeg.h>|g' $(BUILD_WORK)/poppler/poppler/JPEG2000Stream.cc
	mkdir -p $(BUILD_WORK)/poppler/build

ifneq ($(wildcard $(BUILD_WORK)/poppler/.build_complete),)
poppler:
	@echo "Using previously built poppler."
else
poppler: poppler-setup fontconfig libboost lcms2 libjpeg-turbo openjpeg curl gdk-pixbuf gtk+3 libtiff cairo
	cd $(BUILD_WORK)/poppler/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DENABLE_UNSTABLE_API_ABI_HEADERS=ON \
		..
	+$(MAKE) -C $(BUILD_WORK)/poppler/build
	+$(MAKE) -C $(BUILD_WORK)/poppler/build install \
		DESTDIR="$(BUILD_STAGE)/poppler"
	$(call AFTER_BUILD,copy)
endif

poppler-package: poppler-stage
	# poppler.mk Package Structure
	rm -rf $(BUILD_DIST)/{poppler-utils,libpoppler{122,-{glib-dev,cpp-dev,cpp0v10,dev,glib8,private-dev}}}
	mkdir -p $(BUILD_DIST)/libpoppler{122,-{glib-dev,cpp-dev,cpp0v10,dev,glib8,private-dev}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libpoppler-{dev,private-dev,cpp-dev,glib-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	mkdir -p $(BUILD_DIST)/libpoppler-{private-dev,cpp-dev,glib-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/poppler
	mkdir -p $(BUILD_DIST)/poppler-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# poppler.mk Prep poppler-utils
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share,bin} $(BUILD_DIST)/poppler-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# poppler.mk Prep libpoppler122
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpoppler.122{,.0.0}.dylib $(BUILD_DIST)/libpoppler122/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# poppler.mk Prep libpoppler-cpp0v10
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpoppler-cpp.0{,.10.0}.dylib $(BUILD_DIST)/libpoppler-cpp0v10/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# poppler.mk Prep libpoppler-glib8
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpoppler-glib.8{,.23.0}.dylib $(BUILD_DIST)/libpoppler-glib8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# poppler.mk Prep libpoppler-dev
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpoppler.dylib $(BUILD_DIST)/libpoppler-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/poppler.pc $(BUILD_DIST)/libpoppler-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# poppler.mk Prep libpoppler-cpp-dev
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpoppler-cpp.dylib $(BUILD_DIST)/libpoppler-cpp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/poppler-cpp.pc $(BUILD_DIST)/libpoppler-cpp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/poppler/cpp $(BUILD_DIST)/libpoppler-cpp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/poppler

	# poppler.mk Prep libpoppler-private-dev
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/poppler/{*.h,fofi,goo,splash} $(BUILD_DIST)/libpoppler-cpp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/poppler

	# poppler.mk Prep libpoppler-glib-dev
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpoppler-glib.dylib $(BUILD_DIST)/libpoppler-cpp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/poppler/glib $(BUILD_DIST)/libpoppler-cpp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/poppler
	cp -a $(BUILD_STAGE)/poppler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/poppler-cpp.pc $(BUILD_DIST)/libpoppler-cpp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# poppler.mk Sign
	$(call SIGN,poppler-utils,general.xml)
	$(call SIGN,libpoppler122,general.xml)
	$(call SIGN,libpoppler-cpp0v10,general.xml)
	$(call SIGN,libpoppler-glib8,general.xml)

	# poppler.mk Make .debs
	$(call PACK,poppler-utils,DEB_POPPLER_V)
	$(call PACK,libpoppler122,DEB_POPPLER_V)
	$(call PACK,libpoppler-cpp0v10,DEB_POPPLER_V)
	$(call PACK,libpoppler-dev,DEB_POPPLER_V)
	$(call PACK,libpoppler-cpp-dev,DEB_POPPLER_V)
	$(call PACK,libpoppler-private-dev,DEB_POPPLER_V)
	$(call PACK,libpoppler-glib8,DEB_POPPLER_V)
	$(call PACK,libpoppler-glib-dev,DEB_POPPLER_V)

	# poppler.mk Build cleanup
	rm -rf $(BUILD_DIST)/{poppler-utils,libpoppler{122,-{glib-dev,cpp-dev,cpp0v10,dev,glib8,private-dev}}}

.PHONY: poppler poppler-package
