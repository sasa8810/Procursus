ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += xfce4-panel
XFCE4-PANEL_VERSION := 4.17.1
DEB_XFCE4-PANEL_V   ?= $(XFCE4-PANEL_VERSION)

xfce4-panel-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/xfce4-panel/$(shell echo $(XFCE4-PANEL_VERSION) | cut -f-2 -d.)/xfce4-panel-$(XFCE4-PANEL_VERSION).tar.bz2
	$(call EXTRACT_TAR,xfce4-panel-$(XFCE4-PANEL_VERSION).tar.bz2,xfce4-panel-$(XFCE4-PANEL_VERSION),xfce4-panel)

ifneq ($(wildcard $(BUILD_WORK)/xfce4-panel/.build_complete),)
xfce4-panel:
	@echo "Using previously built xfce4-panel."
else
xfce4-panel: xfce4-panel-setup garcon gtk+3 cairo exo libwnck pango libxext gdk-pixbuf glib2.0
	cd $(BUILD_WORK)/xfce4-panel && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--x-libraries=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--x-includes=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--enable-vala=no \
		--enable-debug=no \
		--disable-dbusmenu-gtk3 \
		--enable-nls \
		--enable-gio-unix \
		--disable-visibility
	+$(MAKE) -C $(BUILD_WORK)/xfce4-panel
	+$(MAKE) -C $(BUILD_WORK)/xfce4-panel install \
		DESTDIR=$(BUILD_STAGE)/xfce4-panel
	$(call AFTER_BUILD,copy)
endif

xfce4-panel-package: xfce4-panel-stage
	# xfce4-panel.mk Package Structure
	rm -rf $(BUILD_DIST)/{xfce4-panel,libxfce4panel-2.0-4,libxfce4panel-2.0-dev}
	mkdir -p $(BUILD_DIST)/{xfce4-panel,libxfce4panel-2.0-4,libxfce4panel-2.0-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/{xfce4-panel,libxfce4panel-2.0-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# xfce4-panel.mk Prep xfce4-panel
	cp -a $(BUILD_STAGE)/xfce4-panel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{locale,icons,xfce4,applications} $(BUILD_DIST)/xfce4-panel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/xfce4-panel/$(MEMO_PREFIX)/etc $(BUILD_DIST)/xfce4-panel/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/xfce4-panel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/xfce4-panel/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/xfce4-panel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xfce4 $(BUILD_DIST)/xfce4-panel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xfce4-panel.mk Prep libxfce4panel-2.0-4
	cp -a $(BUILD_STAGE)/xfce4-panel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxfce4panel-2.0.4.dylib $(BUILD_DIST)/libxfce4panel-2.0-4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xfce4-panel.mk Prep libxfce4panel-2.0-dev
	cp -a $(BUILD_STAGE)/xfce4-panel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxfce4panel-2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/xfce4-panel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gtk-doc $(BUILD_DIST)/libxfce4panel-2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/xfce4-panel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libxfce4panel-2.0.{dylib,a},pkgconfig} $(BUILD_DIST)/libxfce4panel-2.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xfce4-panel.mk Sign
	$(call SIGN,xfce4-panel,general.xml)
	$(call SIGN,libxfce4panel-2.0-4,general.xml)

	# xfce4-panel.mk Make .debs
	$(call PACK,xfce4-panel,DEB_XFCE4-PANEL_V)
	$(call PACK,libxfce4panel-2.0-4,DEB_XFCE4-PANEL_V)
	$(call PACK,libxfce4panel-2.0-dev,DEB_XFCE4-PANEL_V)

	# xfce4-panel.mk Build cleanup
	rm -rf $(BUILD_DIST)/{xfce4-panel,libxfce4panel-2.0-4,libxfce4panel-2.0-dev}

.PHONY: xfce4-panel xfce4-panel-package
