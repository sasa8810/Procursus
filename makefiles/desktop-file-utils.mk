ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                += desktop-file-utils
DESKTOP_FILE_UTILS_VERSION := 0.26
DEB_DESKTOP_FILE_UTILS_V   ?= $(DESKTOP_FILE_UTILS_VERSION)

desktop-file-utils-setup: setup
	wget -q -nc -P$(BUILD_SOURCE)/ https://www.freedesktop.org/software/desktop-file-utils/releases/desktop-file-utils-$(DESKTOP_FILE_UTILS_VERSION).tar.xz{,.asc}
	$(call PGP_VERIFY,desktop-file-utils-$(DESKTOP_FILE_UTILS_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,desktop-file-utils-$(DESKTOP_FILE_UTILS_VERSION).tar.xz,desktop-file-utils-$(DESKTOP_FILE_UTILS_VERSION),desktop-file-utils)

ifneq ($(wildcard $(BUILD_WORK)/desktop-file-utils/.build_complete),)
desktop-file-utils:
	@echo "Using previously built desktop-file-utils."
else
desktop-file-utils: desktop-file-utils-setup gettext libglib2.0
	cd $(BUILD_WORK)/desktop-file-utils && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/desktop-file-utils
	+$(MAKE) -C $(BUILD_WORK)/desktop-file-utils install \
		DESTDIR=$(BUILD_STAGE)/desktop-file-utils
	$(call AFTER_BUILD)
endif

desktop-file-utils-package: desktop-file-utils-stage
	# desktop-file-utils.mk Package Structure
	rm -rf $(BUILD_DIST)/desktop-file-utils

	# desktop-file-utils.mk Prep desktop-file-utils
	cp -a $(BUILD_STAGE)/desktop-file-utils $(BUILD_DIST)

	# desktop-file-utils.mk Sign
	$(call SIGN,desktop-file-utils,general.xml)

	# desktop-file-utils.mk Make .debs
	$(call PACK,desktop-file-utils,DEB_DESKTOP_FILE_UTILS_V)

	# desktop-file-utils.mk Build cleanup
	rm -rf $(BUILD_DIST)/desktop-file-utils

.PHONY: desktop-file-utils desktop-file-utils-package
