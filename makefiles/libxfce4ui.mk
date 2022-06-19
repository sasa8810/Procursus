ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libxfce4ui
LIBXFCE4UI_VERSION  := 4.17.6
DEB_LIBXFCE4UI_V    ?= $(LIBXFCE4UI_VERSION)
DEBIAN_LIBXFCE4UI_V := 4.17.6-1

libxfce4ui-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/libxfce4ui/$(shell echo $(LIBXFCE4UI_VERSION) | cut -f-2 -d.)/libxfce4ui-$(LIBXFCE4UI_VERSION).tar.bz2
	$(call EXTRACT_TAR,libxfce4ui-$(LIBXFCE4UI_VERSION).tar.bz2,libxfce4ui-$(LIBXFCE4UI_VERSION),libxfce4ui)
	wget -q -nc -P $(BUILD_WORK)/libxfce4ui https://sources.debian.org/data/main/libx/libxfce4ui/$(DEBIAN_LIBXFCE4UI_V)/debian/xfce4-about.1

ifneq ($(wildcard $(BUILD_WORK)/libxfce4ui/.build_complete),)
libxfce4ui:
	@echo "Using previously built libxfce4ui."
else
libxfce4ui: libxfce4ui-setup libx11 libxau libxmu xorgproto xxhash xfconf gtk+3
	cd $(BUILD_WORK)/libxfce4ui && mkdir -p build && cd build && ../configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--x-libraries=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--x-includes=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--disable-visibility \
		--enable-introspection=no \
		--with-vendor-info=Procursus \
		--with-sysroot=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/libxfce4ui/build
	+$(MAKE) -i -C $(BUILD_WORK)/libxfce4ui/build install \
		DESTDIR=$(BUILD_STAGE)/libxfce4ui
	mkdir -p $(BUILD_STAGE)/libxfce4ui/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(INSTALL) -m644 $(BUILD_WORK)/libxfce4ui/xfce4-about.1 $(BUILD_STAGE)/libxfce4ui/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(call AFTER_BUILD,copy)
endif

libxfce4ui-package: libxfce4ui-stage
	# libxfce4ui.mk Package Structure
	rm -rf $(BUILD_DIST)/libxfce4ui-{2-{0,dev},common,utils}
	mkdir -p $(BUILD_DIST)/libxfce4ui-{2-{0,dev},common,utils}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libxfce4ui-{2-{0,dev},common,utils}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libxfce4ui-2-{0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libxfce4ui-{common,utils}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/libxfce4ui-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libxfce4ui.mk Prep libxfce4ui-2-0
	cp -a $(BUILD_STAGE)/libxfce4ui/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libxfce4kbd-private-3.0,libxfce4ui-2.0}.dylib $(BUILD_DIST)/libxfce4ui-2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxfce4ui.mk Prep libxfce4ui-2-dev
	cp -a $(BUILD_STAGE)/libxfce4ui/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{{libxfce4kbd-private-3,libxfce4ui-2}.dylib,pkgconfig} $(BUILD_DIST)/libxfce4ui-2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxfce4ui/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxfce4ui-2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxfce4ui.mk Prep libxfce4ui-common
	cp -a $(BUILD_STAGE)/libxfce4ui/$(MEMO_PREFIX)/etc $(BUILD_DIST)/libxfce4ui-common/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/libxfce4ui/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libxfce4ui-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libxfce4ui.mk Prep libxfce4ui-utils
	cp -a $(BUILD_STAGE)/libxfce4ui/$(MEMO_PREFIX)/etc $(BUILD_DIST)/libxfce4ui-common/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/libxfce4ui/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{locale,applications} $(BUILD_DIST)/libxfce4ui-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libxfce4ui.mk Sign
	$(call SIGN,libxfce4ui-2-0,general.xml)
	$(call SIGN,libxfce4ui-utils,general.xml)

	# libxfce4ui.mk Make .debs
	$(call PACK,libxfce4ui-2-0,DEB_LIBXFCE4UI_V)
	$(call PACK,libxfce4ui-2-dev,DEB_LIBXFCE4UI_V)
	$(call PACK,libxfce4ui-common,DEB_LIBXFCE4UI_V)
	$(call PACK,libxfce4ui-utils,DEB_LIBXFCE4UI_V)

	# libxfce4ui.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxfce4ui-{2-{0,dev},common,utils}

.PHONY: libxfce4ui libxfce4ui-package
