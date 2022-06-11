ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += libxfce4util
LIBXFCE4UTIL_VERSION  := 4.17.2
DEB_LIBXFCE4UTIL_V    ?= $(LIBXFCE4UTIL_VERSION)
DEBIAN_LIBXFCE4UTIL_V := 4.17.2-1

libxfce4util-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/libxfce4util/$(shell echo $(LIBXFCE4UTIL_VERSION) | cut -f-2 -d.)/libxfce4util-$(LIBXFCE4UTIL_VERSION).tar.bz2
	$(call EXTRACT_TAR,libxfce4util-$(LIBXFCE4UTIL_VERSION).tar.bz2,libxfce4util-$(LIBXFCE4UTIL_VERSION),libxfce4util)
	wget -q -nc -P $(BUILD_WORK)/libxfce4util https://sources.debian.org/data/main/libx/libxfce4util/$(DEBIAN_LIBXFCE4UTIL_V)/debian/xfce4-kiosk-query.8

ifneq ($(call HAS_COMMAND,intltool-update),1)
libxfce4util:
        @echo "Install gtk-doc-tools, intltool and libxml-parser-perl before building"

else ifneq ($(wildcard $(BUILD_WORK)/libxfce4util/.build_complete),)
libxfce4util:
	@echo "Using previously built libxfce4util."
else
libxfce4util: libxfce4util-setup libx11 libxau libxmu xorgproto xxhash glib2.0
	cd $(BUILD_WORK)/libxfce4util && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--x-libraries=$(BUILD_BASE)/usr/lib \
		--x-includes=$(BUILD_BASE)/usr/include \
		--disable-visibility \
		--enable-introspection=no
	+$(MAKE) -C $(BUILD_WORK)/libxfce4util
	+$(MAKE) -C $(BUILD_WORK)/libxfce4util install \
		DESTDIR=$(BUILD_STAGE)/libxfce4util
	mkdir -p $(BUILD_STAGE)/libxfce4util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(INSTALL) -m644 $(BUILD_WORK)/libxfce4util/xfce4-kiosk-query.8 $(BUILD_STAGE)/libxfce4util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(call AFTER_BUILD,copy)
endif

libxfce4util-package: libxfce4util-stage
	# libxfce4util.mk Package Structure
	rm -rf $(BUILD_DIST)/libxfce4util{7,-common,-bin,-dev}
	mkdir -p $(BUILD_DIST)/libxfce4util{7,-common,-bin,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libxfce4util{7,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libxfce4util-{common,dev,bin}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libxfce4util.mk Prep libxfce4util7
	cp -a $(BUILD_STAGE)/libxfce4util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxfce4util.7.dylib $(BUILD_DIST)/libxfce4util7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libxfce4util.mk libxfce4util-dev
	cp -a $(BUILD_STAGE)/libxfce4util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libxfce4util.{dylib,a}} $(BUILD_DIST)/libxfce4util-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxfce4util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gtk-doc $(BUILD_DIST)/libxfce4util-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/libxfce4util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxfce4util-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libxfce4util.mk Prep libxfce4util-bin
	cp -a $(BUILD_STAGE)/libxfce4util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin $(BUILD_DIST)/libxfce4util-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxfce4util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/libxfce4util-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libxfce4util.mk Prep libxfce4util-common
	cp -a $(BUILD_STAGE)/libxfce4util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libxfce4util7/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libxfce4util.mk Sign
	$(call SIGN,libxfce4util7,general.xml)
	$(call SIGN,libxfce4util-bin,general.xml)

	# libxfce4util.mk Make .debs
	$(call PACK,libxfce4util7,DEB_LIBXFCE4UTIL_V)
	$(call PACK,libxfce4util-dev,DEB_LIBXFCE4UTIL_V)
	$(call PACK,libxfce4util-bin,DEB_LIBXFCE4UTIL_V)
	$(call PACK,libxfce4util-common,DEB_LIBXFCE4UTIL_V)

	# libxfce4util.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxfce4util{7,-common,-bin,-dev}

.PHONY: libxfce4util libxfce4util-package
