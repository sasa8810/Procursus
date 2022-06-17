ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

# Latest release does not work with ffmpeg 5.0

SUBPROJECTS               += ffmpegthumbnailer
FFMPEGTHUMBNAILER_COMMIT  := 3db9fe895b2fa656bb40ddb7a62e27604a688171
FFMPEGTHUMBNAILER_VERSION := 2.2.2+git20220219.$(shell echo $(ATTACH_COMMIT) | cut -c -7)
DEB_FFMPEGTHUMBNAILER_V   ?= $(FFMPEGTHUMBNAILER_VERSION)

ffmpegthumbnailer-setup: setup
	$(call GITHUB_ARCHIVE,dirkvdb,ffmpegthumbnailer,$(FFMPEGTHUMBNAILER_COMMIT),$(FFMPEGTHUMBNAILER_COMMIT))
	$(call EXTRACT_TAR,ffmpegthumbnailer-$(FFMPEGTHUMBNAILER_COMMIT).tar.gz,ffmpegthumbnailer-$(FFMPEGTHUMBNAILER_COMMIT),ffmpegthumbnailer)
	mkdir -p $(BUILD_WORK)/ffmpegthumbnailer/build

ifneq ($(wildcard $(BUILD_WORK)/ffmpegthumbnailer/.build_complete),)
ffmpegthumbnailer:
	@echo "Using previously built ffmpegthumbnailer."
else
ffmpegthumbnailer: ffmpegthumbnailer-setup ffmpeg libjpeg-turbo libpng16
	cd $(BUILD_WORK)/ffmpegthumbnailer/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DENABLE_STATIC=true \
		-DENABLE_SHARED=true \
		-DENABLE_TESTS=false \
		-DENABLE_GIO=true \
		..
	+$(MAKE) -C $(BUILD_WORK)/ffmpegthumbnailer/build
	+$(MAKE) -C $(BUILD_WORK)/ffmpegthumbnailer/build install \
		DESTDIR="$(BUILD_STAGE)/ffmpegthumbnailer"
	$(call AFTER_BUILD,copy)
endif

ffmpegthumbnailer-package: ffmpegthumbnailer-stage
	# ffmpegthumbnailer.mk Package Structure
	rm -rf $(BUILD_DIST)/{ffmpegthumbnailer,libffmpegthumbnailer{-dev,4v5}}
	mkdir -p $(BUILD_DIST)/{ffmpegthumbnailer,libffmpegthumbnailer{-dev,4v5}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libffmpegthumbnailer{-dev,4v5}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpegthumbnailer.mk Prep ffmpegthumbnailer
	cp -a $(BUILD_STAGE)/ffmpegthumbnailer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/ffmpegthumbnailer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# ffmpegthumbnailer.mk Prep libffmpegthumbnailer4v5
	cp -a $(BUILD_STAGE)/ffmpegthumbnailer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libffmpegthumbnailer.4{.15.1,}.dylib $(BUILD_DIST)/libffmpegthumbnailer4v5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpegthumbnailer.mk Prep libffmpegthumbnailer-dev
	cp -a $(BUILD_STAGE)/ffmpegthumbnailer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libffmpegthumbnailer-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/ffmpegthumbnailer/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libffmpegthumbnailer.{dylib,a},pkgconfig} $(BUILD_DIST)/libffmpegthumbnailer4v5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# ffmpegthumbnailer.mk Sign
	$(call SIGN,ffmpegthumbnailer,general.xml)
	$(call SIGN,libffmpegthumbnailer4v5,general.xml)

	# ffmpegthumbnailer.mk Make .debs
	$(call PACK,ffmpegthumbnailer,DEB_FFMPEGTHUMBNAILER_V)
	$(call PACK,libffmpegthumbnailer4v5,DEB_FFMPEGTHUMBNAILER_V)
	$(call PACK,libffmpegthumbnailer-dev,DEB_FFMPEGTHUMBNAILER_V)

	# ffmpegthumbnailer.mk Build cleanup
	rm -rf $(BUILD_DIST)/{ffmpegthumbnailer,libffmpegthumbnailer{-dev,4v5}}

.PHONY: ffmpegthumbnailer ffmpegthumbnailer-package
