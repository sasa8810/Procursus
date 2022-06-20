ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += vte
VTE_VERSION := 0.68.0
DEB_VTE_V   ?= $(VTE_VERSION)

vte-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/vte/$$(echo $(VTE_VERSION) | cut -d. -f-2)/vte-$(VTE_VERSION).tar.xz
	$(call EXTRACT_TAR,vte-$(VTE_VERSION).tar.xz,vte-$(VTE_VERSION),vte)
	mkdir -p $(BUILD_WORK)/vte/build
	echo -e "[host_machine]\n \
	system = 'darwin'\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	sysconfdir='$(MEMO_PREFIX)/etc'\n \
	localstatedir='$(MEMO_PREFIX)/var'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n" > $(BUILD_WORK)/vte/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/vte/.build_complete),)
vte:
	@echo "Using previously built vte."
else
vte: vte-setup gtk+3 pcre2 icu4c gnutls libfribidi pango pcre2 gettext gdk-pixbuf cairo atk
	cd $(BUILD_WORK)/vte/build && PKG_CONFIG="$(BUILD_TOOLS)/cross-pkg-config" meson \
		--cross-file cross.txt \
		-D_b_symbolic_functions=false \
		-Dgir=false \
		-Dglade=false \
		-D_systemd=false \
		-Ddocs=false \
		-Dvapi=false \
		..
	ninja -C $(BUILD_WORK)/vte/build
	+DESTDIR="$(BUILD_STAGE)/vte" ninja -C $(BUILD_WORK)/vte/build install
	+DESTDIR="$(BUILD_BASE)" ninja -C $(BUILD_WORK)/vte/build install
	$(call AFTER_BUILD,copy)
endif

vte-package: vte-stage
	# vte.mk Package Structure
	rm -rf $(BUILD_DIST)/libvte-2.91-{dev,common,0}
	mkdir -p $(BUILD_DIST)/libvte-2.91-{dev,common,0}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libvte-2.91-{dev,0}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libvte-2.91-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# vte.mk Prep libvte-2.91-dev
	cp -a $(BUILD_STAGE)/vte/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libvte-2.91-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/vte/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libvte-2.91.dylib} $(BUILD_DIST)/libvte-2.91-dev/$(MEMO_PREFIX)$(MEMO)

	# vte.mk Prep libvte-2.91-common
	cp -a $(BUILD_STAGE)/vte/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libvte-2.91-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/vte/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec $(BUILD_DIST)/libvte-2.91-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/vte/$(MEMO_PREFIX)/etc $(BUILD_DIST)/libvte-2.91-common/$(MEMO_PREFIX)

	# vte.mk Prep libvte-2.91-0
	cp -a $(BUILD_STAGE)/vte/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvte-2.91.0.dylib $(BUILD_DIST)/libvte-2.91-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# vte.mk Sign
	$(call SIGN,libvte-2.91-0,general.xml)
	$(call SIGN,libvte-2.91-common,general.xml)

	# vte.mk Make .debs
	$(call PACK,libvte-2.91-0,DEB_VTE_V)
	$(call PACK,libvte-2.91-common,DEB_VTE_V)
	$(call PACK,libvte-2.91-0,DEB_VTE_V)

	# vte.mk Build cleanup
	rm -rf $(BUILD_DIST)/libvte-2.91-{dev,common,0}

.PHONY: vte vte-package
