ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += exo
EXO_VERSION := 4.17.2
DEB_EXO_V   ?= $(EXO_VERSION)

exo-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.al-us.xfce.org/src/xfce/exo/$(shell echo $(EXO_VERSION) | cut -f-2 -d.)/exo-$(EXO_VERSION).tar.bz2
	$(call EXTRACT_TAR,exo-$(EXO_VERSION).tar.bz2,exo-$(EXO_VERSION),exo)

ifneq ($(wildcard $(BUILD_WORK)/exo/.build_complete),)
exo:
	@echo "Using previously built exo."
else
exo: exo-setup libx11 libxau libxmu xorgproto xxhash gtk+3 libxfce4ui libxfce4util glib2.0 gtk-doc
	cd $(BUILD_WORK)/exo && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--x-libraries=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--disable-visibility \
		--x-includes=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--disable-debug
	+$(MAKE) -C $(BUILD_WORK)/exo
	+$(MAKE) -C $(BUILD_WORK)/exo install \
		DESTDIR="$(BUILD_STAGE)/exo"
	$(call AFTER_BUILD,copy)
endif

exo-package: exo-stage
	# exo.mk Package Structure
	rm -rf $(BUILD_DIST)/{exo-utils,libexo-2-0,libexo-2-dev,libexo-common}
	mkdir -p $(BUILD_DIST)/{exo-utils,libexo-{2,2-dev,common}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libexo-2-{0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share}
	mkdir -p $(BUILD_DIST)/{libexo-2-common,exo-utils}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# exo.mk Prep exo-utils
	cp -a $(BUILD_STAGE)/exo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/exo-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/exo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/exo-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# exo.mk Prep libexo-2-0
	cp -a $(BUILD_STAGE)/exo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libexo-2.0.dylib $(BUILD_DIST)/libexo-2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/exo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libexo-2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# exo.mk Prep libexo-2-dev
	cp -a $(BUILD_STAGE)/exo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gtk-doc $(BUILD_DIST)/libexo-2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/exo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libexo-2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/exo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libexo-2.{dylib,a}} $(BUILD_DIST)/libexo-2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# exo.mk Prep libexo-common
	cp -a $(BUILD_STAGE)/exo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/pixmaps $(BUILD_DIST)/libexo-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# exo.mk Sign
	$(call SIGN,exo-utils,general.xml)
	$(call SIGN,libexo-2-0,general.xml)

	# exo.mk Make .debs
	$(call PACK,exo-utils,DEB_EXO_V)
	$(call PACK,libexo-2-0,DEB_EXO_V)
	$(call PACK,libexo-2-dev,DEB_EXO_V)
	$(call PACK,libexo-common,DEB_EXO_V)

	# exo.mk Build cleanup
	rm -rf $(BUILD_DIST)/{exo-utils,libexo-2-0,libexo-2-dev,libexo-common}

.PHONY: exo exo-package
