ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libopenraw
LIBOPENRAW_VERSION := 0.3.1
DEB_LIBOPENRAW_V   ?= $(LIBOPENRAW_VERSION)

libopenraw-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://libopenraw.freedesktop.org/download/libopenraw-$(LIBOPENRAW_VERSION).tar.xz
	$(call EXTRACT_TAR,libopenraw-$(LIBOPENRAW_VERSION).tar.xz,libopenraw-$(LIBOPENRAW_VERSION),libopenraw)

ifneq ($(wildcard $(BUILD_WORK)/libopenraw/.build_complete),)
libopenraw:
	@echo "Using previously built libopenraw."
else
libopenraw: libopenraw-setup gdk-pixbuf libboost libjpeg-turbo gettext glib2.0 gettext
	cd $(BUILD_WORK)/libopenraw && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libopenraw
	+$(MAKE) -C $(BUILD_WORK)/libopenraw install \
		DESTDIR=$(BUILD_STAGE)/libopenraw
	$(call AFTER_BUILD,copy)
endif

libopenraw-package: libopenraw-stage
	# libopenraw.mk Package Structure
	rm -rf $(BUILD_DIST)/libopenraw{{gnome,}{9,-dev},-gdk-pixbuf}
	mkdir -p $(BUILD_DIST)/libopenraw{gnome,}{9,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libopenraw{gnome,}-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/libopenraw-$$(echo $(LIBOPENRAW_VERSION) | cut -d. -f-2),lib/pkgconfig}
	mkdir -p $(BUILD_DIST)/libopenraw-gdk-pixbuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gdk-pixbuf-2.0/2.10.0/loaders

	# libopenraw.mk Prep libopenraw9
	cp -a $(BUILD_STAGE)/libopenraw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libopenraw.9.dylib $(BUILD_DIST)/libopenraw9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libopenraw.mk Prep libopenrawgnome9
	cp -a $(BUILD_STAGE)/libopenraw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libopenrawgnome.9.dylib $(BUILD_DIST)/libopenrawgnome9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libopenraw.mk Prep libopenraw-dev
	cp -a $(BUILD_STAGE)/libopenraw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libopenraw-$$(echo $(LIBOPENRAW_VERSION) | cut -d. -f-2)/libopenraw $(BUILD_DIST)/libopenraw-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libopenraw-$$(echo $(LIBOPENRAW_VERSION) | cut -d. -f-2)

	# libopenraw.mk Prep libopenrawgnome-dev
	cp -a $(BUILD_STAGE)/libopenraw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libopenraw-$$(echo $(LIBOPENRAW_VERSION) | cut -d. -f-2)/libopenraw-gnome $(BUILD_DIST)/libopenraw-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libopenraw-$$(echo $(LIBOPENRAW_VERSION) | cut -d. -f-2)

	# libopenraw.mk Prep libopenraw-gdk-pixbuf
	cp -a $(BUILD_STAGE)/libopenraw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gdk-pixbuf-2.0/2.10.0/loaders/libopenraw_pixbuf.so $(BUILD_DIST)/libopenraw-gdk-pixbuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gdk-pixbuf-2.0/2.10.0/loaders

	# libopenraw.mk Sign
	$(call SIGN,libopenraw9,general.xml)
	$(call SIGN,libopenrawgnome9,general.xml)
	$(call SIGN,libopenraw-gdk-pixbuf,general.xml)

	# libopenraw.mk Make .debs
	$(call PACK,libopenraw9,DEB_LIBOPENRAW_V)
	$(call PACK,libopenrawgnome9,DEB_LIBOPENRAW_V)
	$(call PACK,libopenraw-dev,DEB_LIBOPENRAW_V)
	$(call PACK,libopenrawgnome-dev,DEB_LIBOPENRAW_V)
	$(call PACK,libopenraw-gdk-pixbuf,DEB_LIBOPENRAW_V)

	# libopenraw.mk Build cleanup
	rm -rf $(BUILD_DIST)/libopenraw{{gnome,}{9,-dev},-gdk-pixbuf}

.PHONY: libopenraw libopenraw-package
