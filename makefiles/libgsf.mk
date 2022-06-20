ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libgsf
LIBGSF_VERSION := 1.14.49
DEB_LIBGSF_V   ?= $(LIBGSF_VERSION)

libgsf-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/libgsf/$(shell echo $(LIBGSF_VERSION) | cut -f-2 -d.)/libgsf-$(LIBGSF_VERSION).tar.xz
	$(call EXTRACT_TAR,libgsf-$(LIBGSF_VERSION).tar.xz,libgsf-$(LIBGSF_VERSION),libgsf)

ifneq ($(wildcard $(BUILD_WORK)/libgsf/.build_complete),)
libgsf:
	@echo "Using previously built libgsf."
else
libgsf: libgsf-setup glib2.0 libffi gettext gdk-pixbuf
	cd $(BUILD_WORK)/libgsf && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-gdk-pixbuf \
		--with-bz2 \
		PKG_CONFIG="$(BUILD_TOOLS)/cross-pkg-config"
	+$(MAKE) -C $(BUILD_WORK)/libgsf
	+$(MAKE) -C $(BUILD_WORK)/libgsf install \
		DESTDIR=$(BUILD_STAGE)/libgsf
	$(call AFTER_BUILD,copy)
endif

libgsf-package: libgsf-stage
	# libgsf.mk Package Structure
	rm -rf $(BUILD_DIST)/libgsf-{1-{114,common,dev},bin}
	mkdir -p $(BUILD_DIST)/libgsf-{1-{114,common,dev},bin}
	mkdir -p $(BUILD_DIST)/libgsf-1-{114,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libgsf-{1-{common,dev},bin}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libgsf.mk Prep libgsf-1-114
	cp -a $(BUILD_STAGE)/libgsf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgsf-1.114.dylib $(BUILD_DIST)/libgsf-1-114/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgsf.mk Prep libgsf-1-common
	cp -a $(BUILD_STAGE)/libgsf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libgsf-1-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libgsf.mk Prep libgsf-1-dev
	cp -a $(BUILD_STAGE)/libgsf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libgsf-1.{dylib,a},pkgconfig} $(BUILD_DIST)/libgsf-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgsf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgsf-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libgsf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gtk-doc $(BUILD_DIST)/libgsf-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libgsf.mk Prep libgsf-bin
	cp -a $(BUILD_STAGE)/libgsf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libgsf-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libgsf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{thumbnailers,man} $(BUILD_DIST)/libgsf-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libgsf.mk Sign
	$(call SIGN,libgsf-1-114,general.xml)
	$(call SIGN,libgsf-bin,general.xml)

	# libgsf.mk Make .debs
	$(call PACK,libgsf-1-114,DEB_LIBGSF_V)
	$(call PACK,libgsf-1-common,DEB_LIBGSF_V)
	$(call PACK,libgsf-1-dev,DEB_LIBGSF_V)
	$(call PACK,libgsf-bin,DEB_LIBGSF_V)

	# libgsf.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgsf-{1-{114,common,dev},bin}

.PHONY: libgsf libgsf-package
