ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += xfconf
XFCONF_VERSION := 4.16.0
XFCONF_MAJOR_V := 4.16
DEB_XFCONF_V   ?= $(XFCONF_VERSION)

xfconf-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/xfconf/$(shell echo $(XFCONF_VERSION) | cut -f-2 -d.)/xfconf-$(XFCONF_VERSION).tar.bz2
	$(call EXTRACT_TAR,xfconf-$(XFCONF_VERSION).tar.bz2,xfconf-$(XFCONF_VERSION),xfconf)

ifneq ($(call HAS_COMMAND,gdbus-codegen),1)
libxfce4util:
	@echo "Install libglib2.0-dev-bin before building"

else ifneq ($(wildcard $(BUILD_WORK)/xfconf/.build_complete),)
xfconf:
	@echo "Using previously built xfconf."
else
xfconf: xfconf-setup libx11 libxfce4util libice gtk+3 fontconfig freetype gettext
	cd $(BUILD_WORK)/xfconf && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--x-libraries=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--x-includes=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--disable-visibility \
		--enable-introspection=no
	+$(MAKE) -C $(BUILD_WORK)/xfconf
	+$(MAKE) -C $(BUILD_WORK)/xfconf install \
		DESTDIR=$(BUILD_STAGE)/xfconf
	$(call AFTER_BUILD,copy)
endif

xfconf-package: xfconf-stage
	# xfconf.mk Package Structure
	rm -rf $(BUILD_DIST)/{xfconf,libxfconf-0-3,libxfconf-0-dev}
	mkdir -p $(BUILD_DIST)/{xfconf,libxfconf-0-3,libxfconf-0-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/{xfconf,libxfconf-0-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# xfconf.mk Prep xfconf
	cp -a $(BUILD_STAGE)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin  $(BUILD_DIST)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/xfce4  $(BUILD_DIST)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{dbus-1,locale,bash-completion}  $(BUILD_DIST)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# xfconf.mk Prep libxfconf-0-3
	cp -a $(BUILD_STAGE)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libxfconf-0.3.dylib $(BUILD_DIST)/libxfconf-0-3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# xfconf.mk Prep libxfconf-0-dev
	cp -a $(BUILD_STAGE)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libxfconf-0.{dylib,a},pkgconfig,gio} $(BUILD_DIST)/libxfconf-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxfconf-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/xfconf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gtk-doc $(BUILD_DIST)/libxfconf-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# xfconf.mk Sign
	$(call SIGN,xfconf,general.xml)
	$(call SIGN,libxfconf-0-3,general.xml)

	# xfconf.mk Make .debs
	$(call PACK,xfconf,DEB_XFCONF_V)
	$(call PACK,libxfconf-0-3,DEB_XFCONF_V)
	$(call PACK,libxfconf-0-dev,DEB_XFCONF_V)

	# xfconf.mk Build cleanup
	rm -rf $(BUILD_DIST)/{xfconf,libxfconf-0-3,libxfconf-0-dev}

.PHONY: xfconf xfconf-package
