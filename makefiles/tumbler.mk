ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += tumbler
TUMBLER_VERSION := 4.17.1
DEB_TUMBLER_V   ?= $(TUMBLER_VERSION)

tumbler-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/tumbler/$$(echo $(TUMBLER_VERSION) | cut -d. -f-2)/tumbler-$(TUMBLER_VERSION).tar.bz2
	$(call EXTRACT_TAR,tumbler-$(TUMBLER_VERSION).tar.bz2,tumbler-$(TUMBLER_VERSION),tumbler)

ifneq ($(wildcard $(BUILD_WORK)/tumbler/.build_complete),)
tumbler:
	@echo "Using previously built tumbler."
else
tumbler: tumbler-setup gdk-pixbuf curl gettext freetype glib2.0 libjpeg-turbo libpng16 poppler ffmpegthumbnailer libopenraw libgsf cairo
	cd $(BUILD_WORK)/tumbler && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-{cover,font,jpeg,ffmpeg,raw,poppler,desktop,raw}-thumbnailer \
		--disable-gepub-thumbnailer \
		--enable-xdg-cache \
		--enable-debug=no \
		LIBOPENRAW_GNOME_LIBS="-lopenrawgnome" \
		LIBOPENRAW_GNOME_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libopenraw-$$(echo $(LIBOPENRAW_VERSION) | cut -d. -f-2)"
	+$(MAKE) -C $(BUILD_WORK)/tumbler
	+$(MAKE) -C $(BUILD_WORK)/tumbler install \
		DESTDIR=$(BUILD_STAGE)/tumbler
	$(call AFTER_BUILD,copy)
endif

tumbler-package: tumbler-stage
	# tumbler.mk Package Structure
	rm -rf $(BUILD_DIST)/{tumbler{,-common,-plugins-extra},libtumbler-1-{0,dev}}
	mkdir -p $(BUILD_DIST)/{tumbler{,-common,-plugins-extra},libtumbler-1-{0,dev}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/tumbler{,-plugins-extra}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/tumbler-1/plugins,share}
	mkdir -p $(BUILD_DIST)/libtumbler-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tumbler-1/plugins/cache
	mkdir -p $(BUILD_DIST)/tumbler-common/$(MEMO_PREFIX){,$(MEMO_SUB_PREFIX)/share}

	# tumbler.mk Prep tumbler
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tumbler-1/tumblerd $(BUILD_DIST)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tumbler-1
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tumbler-1/plugins/tumbler-{font,desktop,jpeg,pixbuf,poppler}-thumbnailer.so $(BUILD_DIST)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tumbler-1/plugins
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tumbler-1/plugins/cache/tumbler-{cache-plugin,xdg-cache}.so $(BUILD_DIST)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tumbler-1/plugins/cache
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dbus-1 $(BUILD_DIST)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# tumbler.mk Prep tumbler-common
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)/etc $(BUILD_DIST)/tumbler-common/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{locale,icons,gtk-doc} $(BUILD_DIST)/tumbler-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# tumbler.mk Prep tumbler-plugins-extra
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tumbler-1/plugins/tumbler-{cover,odf,ffmpeg,raw}-thumbnailer.so $(BUILD_DIST)/tumbler-plugins-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tumbler-1/plugins

	# tumbler.mk Prep libtumbler-1-0
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtumbler-1.0.dylib $(BUILD_DIST)/libtumbler-1-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# tumbler.mk Prep libtumbler-1-dev
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libtumbler-1.{dylib,a},pkgconfig} $(BUILD_DIST)/libtumbler-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/tumbler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libtumbler-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# tumbler.mk Sign
	$(call SIGN,tumbler,general.xml)
	$(call SIGN,libtumbler-1-0,general.xml)
	$(call SIGN,tumbler-plugins-extra,general.xml)

	# tumbler.mk Make .debs
	$(call PACK,tumbler,DEB_TUMBLER_V)
	$(call PACK,tumbler-plugins-extra,DEB_TUMBLER_V)
	$(call PACK,tumbler-common,DEB_TUMBLER_V)
	$(call PACK,libtumbler-1-0,DEB_TUMBLER_V)
	$(call PACK,libtumbler-1-dev,DEB_TUMBLER_V)

	# tumbler.mk Build cleanup
	rm -rf $(BUILD_DIST)/{tumbler{,-common,-plugins-extra},libtumbler-1-{0,dev}}

.PHONY: tumbler tumbler-package
