ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS               += libusb-compat-0.1
LIBUSB_COMPAT_0.1_VERSION := 0.1.7
DEB_LIBUSB_COMPAT_0.1_V   ?= $(LIBUSB_COMPAT_0.1_VERSION)

libusb-compat-0.1-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/libusb/libusb-compat-0.1/releases/download/v$(LIBUSB_COMPAT_0.1_VERSION)/libusb-compat-$(LIBUSB_COMPAT_0.1_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libusb-compat-$(LIBUSB_COMPAT_0.1_VERSION).tar.bz2,libusb-compat-$(LIBUSB_COMPAT_0.1_VERSION),libusb-compat-0.1)
	#$(call DO_PATCH,libusb-compat-0.1,libusb-compat-0.1,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libusb-compat-0.1/.build_complete),)
libusb-compat-0.1:
	@echo "Using previously built libusb-compat-0.1."
else
libusb-compat-0.1: libusb-compat-0.1-setup libusb
	cd $(BUILD_WORK)/libusb-compat-0.1 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libusb-compat-0.1
	+$(MAKE) -C $(BUILD_WORK)/libusb-compat-0.1 install \
		DESTDIR=$(BUILD_STAGE)/libusb-compat-0.1
	$(call AFTER_BUILD,copy)
endif

libusb-compat-0.1-package: libusb-compat-0.1-stage
	# libusb-compat-0.1.mk Package Structure
	rm -rf $(BUILD_DIST)/libusb-{0.1-4,dev}
	mkdir -p $(BUILD_DIST)/libusb-{0.1-4,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libusb-compat-0.1.mk Prep libusb-0.1-4
	cp -a $(BUILD_STAGE)/libusb-compat-0.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libusb-0.1.4.dylib $(BUILD_DIST)/libusb-0.1-4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libusb-compat-0.1.mk Prep libusb-dev
	cp -a $(BUILD_STAGE)/libusb-compat-0.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libusb.{dylib,a}} $(BUILD_DIST)/libusb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libusb-compat-0.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib} $(BUILD_DIST)/libusb-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libusb-compat-0.1.mk Sign
	$(call SIGN,libusb-0.1-4,general.xml)

	# libusb-compat-0.1.mk Make .debs
	$(call PACK,libusb-0.1-4,DEB_LIBUSB_COMPAT_0.1_V)
	$(call PACK,libusb-dev,DEB_LIBUSB_COMPAT_0.1_V)

	# libusb-compat-0.1.mk Build cleanup
	rm -rf $(BUILD_DIST)/libusb-{0.1-4,dev}

.PHONY: libusb-compat-0.1 libusb-compat-0.1-package
