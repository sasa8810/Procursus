ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += xfdesktop
XFDESKTOP_VERSION := 4.16.0
DEB_XFDESKTOP_V   ?= $(XFDESKTOP_VERSION)

xfdesktop-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/xfdesktop/$(shell echo $(XFDESKTOP_VERSION) | cut -f-2 -d.)/xfdesktop-$(XFDESKTOP_VERSION).tar.bz2
	$(call EXTRACT_TAR,xfdesktop-$(XFDESKTOP_VERSION).tar.bz2,xfdesktop-$(XFDESKTOP_VERSION),xfdesktop)

ifneq ($(wildcard $(BUILD_WORK)/xfdesktop/.build_complete),)
xfdesktop:
	find $(BUILD_STAGE)/xfdesktop -type f -exec codesign --remove {} \; &> /dev/null; \
	find $(BUILD_STAGE)/xfdesktop -type f -exec codesign --sign $(CODESIGN_IDENTITY) --force --preserve-metadata=entitlements,requirements,flags,runtime {} \; &> /dev/null
	@echo "Using previously built xfdesktop."
else
xfdesktop: xfdesktop-setup libx11 libxau libxmu xorgproto xxhash
	cd $(BUILD_WORK)/xfdesktop && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--x-libraries=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--x-includes=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--disable-notifications \
		--enable-thunarx
	+$(MAKE) -C $(BUILD_WORK)/xfdesktop
	+$(MAKE) -C $(BUILD_WORK)/xfdesktop install \
		DESTDIR=$(BUILD_STAGE)/xfdesktop
	$(call AFTER_BUILD,copy)
endif

xfdesktop-package: xfdesktop-stage
	# xfdesktop.mk Package Structure
	rm -rf $(BUILD_DIST)/xfdesktop

	# xfdesktop.mk Prep xfdesktop
	cp -a $(BUILD_STAGE)/xfdesktop $(BUILD_DIST)

	# xfdesktop.mk Sign
	$(call SIGN,xfdesktop,general.xml)

	# xfdesktop.mk Make .debs
	$(call PACK,xfdesktop,DEB_XFDESKTOP_V)

	# xfdesktop.mk Build cleanup
	rm -rf $(BUILD_DIST)/xfdesktop

.PHONY: xfdesktop xfdesktop-package
