ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                       += gsettings-desktop-schemas
GSETTINGS-DESKTOP-SCHEMAS_VERSION := 42.0
DEB_GSETTINGS-DESKTOP-SCHEMAS_V   ?= $(GSETTINGS-DESKTOP-SCHEMAS_VERSION)

gsettings-desktop-schemas-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/gsettings-desktop-schemas/$$(echo $(GSETTINGS-DESKTOP-SCHEMAS_VERSION) | cut -d. -f1)/gsettings-desktop-schemas-$(GSETTINGS-DESKTOP-SCHEMAS_VERSION).tar.xz
	$(call EXTRACT_TAR,gsettings-desktop-schemas-$(GSETTINGS-DESKTOP-SCHEMAS_VERSION).tar.xz,gsettings-desktop-schemas-$(GSETTINGS-DESKTOP-SCHEMAS_VERSION),gsettings-desktop-schemas)
	mkdir -p $(BUILD_WORK)/gsettings-desktop-schemas/build
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
	cpp = '$(CXX)'\n" > $(BUILD_WORK)/gsettings-desktop-schemas/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/gsettings-desktop-schemas/.build_complete),)
gsettings-desktop-schemas:
	@echo "Using previously built gsettings-desktop-schemas."
else
gsettings-desktop-schemas: gsettings-desktop-schemas-setup glib2.0
	cd $(BUILD_WORK)/gsettings-desktop-schemas/build && PKG_CONFIG="pkg-config" meson \
		--cross-file cross.txt \
		-Dintrospection=false \
		..
	ninja -C $(BUILD_WORK)/gsettings-desktop-schemas/build
	+DESTDIR="$(BUILD_STAGE)/gsettings-desktop-schemas" ninja -C $(BUILD_WORK)/gsettings-desktop-schemas/build install
	+DESTDIR="$(BUILD_BASE)" ninja -C $(BUILD_WORK)/gsettings-desktop-schemas/build install
	$(call AFTER_BUILD,copy)
endif

gsettings-desktop-schemas-package: gsettings-desktop-schemas-stage
	# gsettings-desktop-schemas.mk Package Structure
	rm -rf $(BUILD_DIST)/gsettings-desktop-schemas{,-dev}
	mkdir -p $(BUILD_DIST)/gsettings-desktop-schemas{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gsettings-desktop-schemas.mk Prep gsettings-desktop-schemas
	cp -a $(BUILD_STAGE)/gsettings-desktop-schemas/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{GConf,glib-2.0,locale} $(BUILD_DIST)/gsettings-desktop-schemas/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# gsettings-desktop-schemas.mk Prep gsettings-desktop-schemas-dev
	cp -a $(BUILD_STAGE)/gsettings-desktop-schemas/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/pkgconfig $(BUILD_DIST)/gsettings-desktop-schemas-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/gsettings-desktop-schemas/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/gsettings-desktop-schemas-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# gsettings-desktop-schemas.mk Make .debs
	$(call PACK,gsettings-desktop-schemas,DEB_GSETTINGS-DESKTOP-SCHEMAS_V)
	$(call PACK,gsettings-desktop-schemas-dev,DEB_GSETTINGS-DESKTOP-SCHEMAS_V)

	# gsettings-desktop-schemas.mk Build cleanup
	rm -rf $(BUILD_DIST)/gsettings-desktop-schemas{,-dev}

.PHONY: gsettings-desktop-schemas gsettings-desktop-schemas-package
