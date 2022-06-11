ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libxfce4ui
LIBXFCE4UI_VERSION := 4.17.6
DEB_LIBXFCE4UI_V   ?= $(LIBXFCE4UI_VERSION)

libxfce4ui-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/libxfce4ui/$(shell echo $(LIBXFCE4UI_VERSION) | cut -f-2 -d.)/libxfce4ui-$(LIBXFCE4UI_VERSION).tar.bz2
	$(call EXTRACT_TAR,libxfce4ui-$(LIBXFCE4UI_VERSION).tar.bz2,libxfce4ui-$(LIBXFCE4UI_VERSION),libxfce4ui)

ifneq ($(wildcard $(BUILD_WORK)/libxfce4ui/.build_complete),)
libxfce4ui:
	@echo "Using previously built libxfce4ui."
else
libxfce4ui: libxfce4ui-setup libx11 libxau libxmu xorgproto xxhash xfconf
	cd $(BUILD_WORK)/libxfce4ui && mkdir -p build && cd build && ../configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--x-libraries=$(BUILD_BASE)/usr/lib \
		--x-includes=$(BUILD_BASE)/usr/include \
		--disable-visibility \
		--enable-introspection=no \
		--with-vendor-info=Procursus \
		--with-sysroot=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/libxfce4ui/build
	+$(MAKE) -i -C $(BUILD_WORK)/libxfce4ui/build install \
		DESTDIR=$(BUILD_STAGE)/libxfce4ui
	$(call AFTER_BUILD,copy)
endif

libxfce4ui-package: libxfce4ui-stage
	# libxfce4ui.mk Package Structure
	rm -rf $(BUILD_DIST)/libxfce4ui

	# libxfce4ui.mk Prep libxfce4ui
	cp -a $(BUILD_STAGE)/libxfce4ui $(BUILD_DIST)

	# libxfce4ui.mk Sign
	$(call SIGN,libxfce4ui,general.xml)

	# libxfce4ui.mk Make .debs
	$(call PACK,libxfce4ui,DEB_LIBXFCE4UI_V)

	# libxfce4ui.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxfce4ui

.PHONY: libxfce4ui libxfce4ui-package
