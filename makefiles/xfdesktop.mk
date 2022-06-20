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
	@echo "Using previously built xfdesktop."
else
xfdesktop: xfdesktop-setup libx11 exo gtk+3 libxfce4ui libxfce4util gettext pango cairo freetype fontconfig garcon glib2.0 libsm gdk-pixbuf libwnck atk
	cd $(BUILD_WORK)/xfdesktop && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--x-libraries=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--x-includes=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--disable-notifications \
		--with-file-manager-fallback=thunar \
		--enable-file-icons \
		--enable-file-icons \
		--enable-debug=no \
		--enable-thunarx
	+$(MAKE) -C $(BUILD_WORK)/xfdesktop
	+$(MAKE) -C $(BUILD_WORK)/xfdesktop install \
		DESTDIR=$(BUILD_STAGE)/xfdesktop
	$(call AFTER_BUILD,copy)
endif

xfdesktop-package: xfdesktop-stage
	# xfdesktop.mk Package Structure
	rm -rf $(BUILD_DIST)/xfdesktop4{,-data}
	mkdir -p $(BUILD_DIST)/xfdesktop4{,-data}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# xfdesktop.mk Prep xfdesktop4
	cp -a $(BUILD_STAGE)/xfdesktop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/xfdesktop4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/xfdesktop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/xfdesktop4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# xfdesktop.mk Prep xfdesktop4-data
	cp -a $(BUILD_STAGE)/xfdesktop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{applications,backgrounds,icons,locale,pixmaps} $(BUILD_DIST)/xfdesktop4-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# xfdesktop.mk Sign
	$(call SIGN,xfdesktop4,general.xml)

	# xfdesktop.mk Make .debs
	$(call PACK,xfdesktop4,DEB_XFDESKTOP_V)
	$(call PACK,xfdesktop4-data,DEB_XFDESKTOP_V)

	# xfdesktop.mk Build cleanup
	rm -rf $(BUILD_DIST)/xfdesktop4{,-data}

.PHONY: xfdesktop xfdesktop-package
