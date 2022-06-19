ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += garcon
GARCON_VERSION := 4.17.0
DEB_GARCON_V   ?= $(GARCON_VERSION)

garcon-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/garcon/$$(echo $(GARCON_VERSION) | cut -d. -f-2)/garcon-$(GARCON_VERSION).tar.bz2
	$(call EXTRACT_TAR,garcon-$(GARCON_VERSION).tar.bz2,garcon-$(GARCON_VERSION),garcon)

ifneq ($(wildcard $(BUILD_WORK)/garcon/.build_complete),)
garcon:
	@echo "Using previously built garcon."
else
garcon: garcon-setup atk cairo gdk-pixbuf gtk+3 glib2.0 harfbuzz gettext pango libxfce4ui libxfce4util
	cd $(BUILD_WORK)/garcon && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-introspection=no \
		--enable-debug=no
	+$(MAKE) -C $(BUILD_WORK)/garcon
	+$(MAKE) -C $(BUILD_WORK)/garcon install \
		DESTDIR=$(BUILD_STAGE)/garcon
	$(call AFTER_BUILD,copy)
endif

garcon-package: garcon-stage
	# garcon.mk Package Structure
	rm -rf $(BUILD_DIST)/libgarcon-{1-0,1-dev,common,gtk3-1-0,gtk3-1-dev}
	mkdir -p $(BUILD_DIST)/libgarcon-{1-0,1-dev,gtk3-1-0,gtk3-1-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libgarcon-{common,1-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/libgarcon-{gtk3-,}1-dev/{include,lib/pkgconfig}

	# garcon.mk Prep libgarcon-common
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{icons,locale,desktop-directories} $(BUILD_DIST)/libgarcon-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)/etc $(BUILD_DIST)/libgarcon-common/$(MEMO_PREFIX)

	# garcon.mk Prep libgarcon-1-0
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgarcon-1.0.dylib $(BUILD_DIST)/libgarcon-1-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# garcon.mk Prep libgarcon-gtk3-1-0
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgarcon-gtk3-1.0.dylib $(BUILF_DIST)/libgarcon-gtk3-1-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# garcon.mk Prep libgarcon-1-dev
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gtk-doc $(BUILD_DIST)/libgarcon-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgarcon-1.{dylib,a} $(BUILD_DIST)/libgarcon-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/garcon-1.pc $(BUILD_DIST)/libgarcon-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/garcon-1 $(BUILD_DIST)/libgarcon-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# garcon.mk Prep libgarcon-gtk3-1-dev
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libgarcon-gtk3-1.{dylib,a} $(BUILD_DIST)/libgarcon-gtk3-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/garcon-gtk3-1.pc $(BUILD_DIST)/libgarcon-gtk3-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/garcon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/garcon-gtk3-1 $(BUILD_DIST)/libgarcon-3-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# garcon.mk Sign
	$(call SIGN,libgarcon-1-0,general.xml)
	$(call SIGN,libgarcon-gtk3-1-0,general.xml)


	# garcon.mk Make .debs
	$(call PACK,libgarcon-common,DEB_GARCON_V)
	$(call PACK,libgarcon-1-0,DEB_GARCON_V)
	$(call PACK,libgarcon-gtk3-1-0,DEB_GARCON_V)
	$(call PACK,libgarcon-1-dev,DEB_GARCON_V)
	$(call PACK,libgarcon-gtk3-1-dev,DEB_GARCON_V)

	# garcon.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgarcon-{1-0,1-dev,common,gtk3-1-0,gtk3-1-dev}

.PHONY: garcon garcon-package
