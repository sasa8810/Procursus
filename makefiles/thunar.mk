ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += thunar
THUNAR_VERSION := 4.17.8
DEB_THUNAR_V   ?= $(THUNAR_VERSION)

thunar-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/thunar/$(shell echo $(THUNAR_VERSION) | cut -f-2 -d.)/thunar-$(THUNAR_VERSION).tar.bz2
	$(call EXTRACT_TAR,thunar-$(THUNAR_VERSION).tar.bz2,thunar-$(THUNAR_VERSION),thunar)

ifneq ($(wildcard $(BUILD_WORK)/thunar/.build_complete),)
thunar:
	@echo "Using previously built thunar."
else
thunar: thunar-setup libx11 libxau libxmu xorgproto xxhash exo hicolor-icon-theme pcre
	cd $(BUILD_WORK)/thunar && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--x-libraries=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--x-includes=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--disable-notifications \
		--enable-introspection=no
	+$(MAKE) -C $(BUILD_WORK)/thunar
	+$(MAKE) -C $(BUILD_WORK)/thunar install \
		DESTDIR=$(BUILD_STAGE)/thunar
	$(call AFTER_BUILD,copy)
endif

thunar-package: thunar-stage
	# thunar.mk Package Structure
	rm -rf $(BUILD_DIST)/{thunar{,-data},libthunarx-3-{0,dev}}
	mkdir -p $(BUILD_DIST)/{thunar{,-data},libthunarx-3-{0,dev}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/{thunar,libthunarx-3-{0,dev}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/{libthunarx-3-dev,thunar{,-data}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# thunar.mk Prep thunar
	cp -a $(BUILD_STAGE)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{metainfo,polkit-1,applications,man} $(BUILD_DIST)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	$(LN_SR) $(BUILD_DIST)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{t,T}hunar.1$(MEMO_MANPAGE_SUFFIX)

	# thunar.mk Prep thunar-data
	cp -a $(BUILD_STAGE)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{Thunar,locale,dbus-1,icons} $(BUILD_DIST)/thunar-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/thunar/$(MEMO_PREFIX)/etc $(BUILD_DIST)/thunar-data/$(MEMO_PREFIX)/etc

	# thunar.mk Prep libthunarx-3-0
	cp -a $(BUILD_STAGE)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libthunarx-3.0.dylib,thunarx-3} $(BUILD_DIST)/libthunarx-3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# thunar.mk Prep libthunarx-3-dev
	cp -a $(BUILD_STAGE)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libthunarx-3.{dylib,a}} $(BUILD_DIST)/libthunarx-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gtk-doc $(BUILD_DIST)/libthunarx-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/thunar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libthunarx-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# thunar.mk Sign
	$(call SIGN,thunar,general.xml)
	$(call SIGN,libthunarx-3-0,general.xml)

	# thunar.mk Make .debs
	$(call PACK,thunar,DEB_THUNAR_V)
	$(call PACK,thunar-data,DEB_THUNAR_V)
	$(call PACK,libthunarx-3-0,DEB_THUNAR_V)
	$(call PACK,libthunarx-3-dev,DEB_THUNAR_V)

	# thunar.mk Build cleanup
	rm -rf $(BUILD_DIST)/{thunar{,-data},libthunarx-3-{0,dev}}

.PHONY: thunar thunar-package
