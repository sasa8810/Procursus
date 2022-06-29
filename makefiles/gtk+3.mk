ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gtk+3
GTK+3_VERSION := 3.24.29
DEB_GTK+3_V   ?= $(GTK+3_VERSION)

ifeq ($(UNAME),Darwin)
ifeq ($(shell sw_vers -productName),macOS)
GTK+3_HOST_PREFIX     := /opt/procursus
GTK+3_HOST_SUB_PREFIX :=
endif
else
GTK+3_HOST_SUB_PREFIX := /usr
endif

gtk+3-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/gtk+/$(shell echo $(GTK+3_VERSION) | cut -f-2 -d.)/gtk+-$(GTK+3_VERSION).tar.xz
	$(call EXTRACT_TAR,gtk+-$(GTK+3_VERSION).tar.xz,gtk+-$(GTK+3_VERSION),gtk+3)
	$(call DO_PATCH,gtk+,gtk+3,-p1)
	mkdir -p $(BUILD_WORK)/gtk+3/build

ifneq ($(call HAS_COMMAND,glib-compile-schemas),1)
gtk+3:
	$(error Install libglib2.o-dev-bin)

else ifneq ($(wildcard $(BUILD_WORK)/gtk+3/.build_complete),)
gtk+3:
	@echo "Using previously built gtk+3."
else
gtk+3: gtk+3-setup libx11 libxau libxmu xorgproto xxhash libepoxy at-spi2-atk pango gdk-pixbuf hicolor-icon-theme glib2.0 gettext libxdamage libxfixes libxinerama libxrandr libffi cairo fontconfig gdk-pixbuf libxext atk freetype libxinerama
	cd $(BUILD_WORK)/gtk+3/build && ../configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--enable-nls \
		--enable-xkb \
		--enable-xinerama \
		--enable-xrandr \
		--enable-xfixes \
		--enable-xdamage \
		--disable-quartz-backend \
		--enable-x11-backend \
		--enable-cups \
		--disable-gtk-doc \
		--disable-man \
		--with-xml-catalog=$(GTK+3_HOST_PREFIX)/etc/xml/catalog \
		PKG_CONFIG_FOR_BUILD="$$(command -v pkg-config)" \
		PKG_CONFIG="$(BUILD_TOOLS)/cross-pkg-config"
	+sed -i 's|/usr/bin/glib-|$(GTK+3_HOST_PREFIX)$(GTK+3_HOST_SUB_PREFIX)/bin/glib-|g' $$(find $(BUILD_WORK)/gtk+3/build -name Makefile)
	+$(MAKE) -C $(BUILD_WORK)/gtk+3/build
	+$(MAKE) -C $(BUILD_WORK)/gtk+3/build install \
		DESTDIR=$(BUILD_STAGE)/gtk+3
	$(call AFTER_BUILD,copy)
endif

gtk+3-package: gtk+3-stage
	# gtk+3.mk Package Structure
	rm -rf $(BUILD_DIST)/{gtk-3-examples,gtk-update-icon-cache,libgail-3-0,libgail-3-dev,libgtk-3-{0,bin,common,dev}}
	mkdir -p $(BUILD_DIST)/{gtk-3-examples,gtk-update-icon-cache,libgail-3-0,libgail-3-dev,libgtk-3-{0,bin,common,dev}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/{gtk-3-examples,gtk-update-icon-cache,libgtk-3-bin}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	mkdir -p $(BUILD_DIST)/lib{gail-3-{0,dev},gtk-3-{0,bin,common,dev}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/lib{gail,gtk}-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	mkdir -p $(BUILD_DIST)/libgtk-3-{0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gtk-3.0/3.0.0/{immodules,printbackends}
	mkdir -p $(BUILD_DIST)/libgtk-3-{common,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gtk+3.mk Prep gtk-3-examples
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gtk3-{demo,demo-application,icon-browser,widget-factory} $(BUILD_DIST)/gtk-3-examples/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gtk3-{demo,demo-application,icon-browser,widget-factory}.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/gtk-3-examples/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{icons,applications} $(BUILD_DIST)/gtk-3-examples/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gtk+3.mk Prep gtk-update-icon-cache
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gtk-update-icon-cache $(BUILD_DIST)/gtk-update-icon-cache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gtk-update-icon-cache.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/gtk-update-icon-cache/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# gtk+3.mk Prep libgail-3-0
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgailutil-3.0.dylib $(BUILD_DIST)/libgail-3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# gtk+3.mk Prep libgail-3-dev
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgailutil-3.{dylib,a} $(BUILD_DIST)/libgail-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/gail-3.0.pc $(BUILD_DIST)/libgail-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# gtk+3.mk Prep libgtk-3-0
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libg{t,d}k-3.0.dylib $(BUILD_DIST)/libgtk-3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gtk-3.0/3.0.0/immodules/im-*.so $(BUILD_DIST)/libgtk-3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gtk-3.0/3.0.0/immodules
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gtk-3.0/3.0.0/printbackends/libprintbackend-{cups,file,lpr}.so $(BUILD_DIST)/libgtk-3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gtk-3.0/3.0.0/printbackends
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gtk-query-immodules-3.0 $(BUILD_DIST)/libgtk-3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# gtk+3.mk Prep libgtk-3-bin
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gtk-{query-settings,builder-tool,launch,encode-symbolic-svg} $(BUILD_DIST)/libgtk-3-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/gtk-{query-settings,builder-tool,launch,encode-symbolic-svg,query-immodules-3.0}.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/libgtk-3-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gettext $(BUILD_DIST)/libgtk-3-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gtk+3.mk Prep libgtk-3-common
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)/etc $(BUILD_DIST)/libgtk-3-common/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{glib-2.0,locale,themes} $(BUILD_DIST)/libgtk-3-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gtk+3.mk Prep libgtk-3-dev
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/{gtk+,gtk+-unix-print,gtk+-x11,gdk-x11,gdk}-3.0.pc $(BUILD_DIST)/libgtk-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libg{d,t}k-3.{dylib,a} $(BUILD_DIST)/libgtk-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgtk-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gtk-3.0/3.0.0/immodules/im-*.a $(BUILD_DIST)/libgtk-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gtk-3.0/3.0.0/immodules
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gtk-3.0/3.0.0/printbackends/libprintbackend-{cups,file,lpr}.a $(BUILD_DIST)/libgtk-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gtk-3.0/3.0.0/printbackends
	cp -a $(BUILD_STAGE)/gtk+3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal $(BUILD_DIST)/libgtk-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gtk+3.mk Sign
	$(call SIGN,gtk-3-examples,general.xml)
	$(call SIGN,gtk-update-icon-cache,general.xml)
	$(call SIGN,libgail-3-0,general.xml)
	$(call SIGN,libgtk-3-0,general.xml)
	$(call SIGN,libgtk-3-bin,general.xml)
	$(call SIGN,libgtk-3-dev,general.xml)

	# gtk+3.mk Make .debs
	$(call PACK,gtk-3-examples,DEB_GTK+3_V)
	$(call PACK,gtk-update-icon-cache,DEB_GTK+3_V)
	$(call PACK,libgail-3-0,DEB_GTK+3_V)
	$(call PACK,libgail-3-dev,DEB_GTK+3_V)
	$(call PACK,libgtk-3-0,DEB_GTK+3_V)
	$(call PACK,libgtk-3-bin,DEB_GTK+3_V)
	$(call PACK,libgtk-3-common,DEB_GTK+3_V)
	$(call PACK,libgtk-3-dev,DEB_GTK+3_V)

	# gtk+3.mk Build cleanup
	rm -rf $(BUILD_DIST)/{gtk-3-examples,gtk-update-icon-cache,libgail-3-0,libgail-3-dev,libgtk-3-{0,bin,common,dev}}

.PHONY: gtk+3 gtk+3-package

