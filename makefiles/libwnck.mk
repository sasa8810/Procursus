ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libwnck
LIBWNCK_VERSION := 40.0
DEB_LIBWNCK_V   ?= $(LIBWNCK_VERSION)

libwnck-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/libwnck/40/libwnck-40.0.tar.xz
	$(call EXTRACT_TAR,libwnck-$(LIBWNCK_VERSION).tar.xz,libwnck-$(LIBWNCK_VERSION),libwnck)
	mkdir -p $(BUILD_WORK)/libwnck/build
	echo -e "[host_machine]\n \
	system = 'darwin'\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	sys_root = '$(BUILD_BASE)'\n \
	objcpp_args = ['-arch', 'arm64']\n \
	objcpp_link_args = ['-arch', 'arm64']\n \
	[paths]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	sysconfdir='$(MEMO_PREFIX)/etc'\n \
	localstatedir='$(MEMO_PREFIX)/var'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n" > $(BUILD_WORK)/libwnck/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/libwnck/.build_complete),)
libwnck:
	@echo "Using previously built libwnck."
else
libwnck: libwnck-setup gtk+3 libxres cairo glib2.0 libx11 gettext libxext libxrender atk pango
	cd $(BUILD_WORK)/libwnck/build && PKG_CONFIG="$(BUILD_TOOLS)/cross-pkg-config" meson \
		--cross-file cross.txt \
		-Dintrospection=disabled \
		-Dstartup_notification=disabled \
		..
	sed -i 's/,--version-script//g' $(BUILD_WORK)/libwnck/build/build.ninja
	ninja -C $(BUILD_WORK)/libwnck/build
	+DESTDIR="$(BUILD_STAGE)/libwnck" ninja -C $(BUILD_WORK)/libwnck/build install
	$(call AFTER_BUILD,copy)
endif

libwnck-package: libwnck-stage

	# libwnck.mk Package Structure
	rm -rf $(BUILD_DIST)/libwnck-3-{0,common,dev}
	mkdir -p $(BUILD_DIST)/libwnck-3-{0,common,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/libwnck-3-{0,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libwnck-3-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libwnck.mk Prep libwnck-3-0
	cp -a $(BUILD_STAGE)/libwnck/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libwnck-3.0.dylib $(BUILD_DIST)/libwnck-3-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libwnck.mk Prep libwnck-3-dev
	cp -a $(BUILD_STAGE)/libwnck/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libwnck-3.dylib} $(BUILD_DIST)/libwnck-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libwnck/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,bin} $(BUILD_DIST)/libwnck-3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libwnck.mk Prep libwnck-3-common
	cp -a $(BUILD_STAGE)/libwnck/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libwnck-3-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libwnck.mk Sign
	$(call SIGN,libwnck-3-0,general.xml)

	# gtk+.mk Make .debs
	$(call PACK,libwnck-3-0,DEB_LIBWNCK_V)
	$(call PACK,libwnck-3-dev,DEB_LIBWNCK_V)
	$(call PACK,libwnck-3-common,DEB_LIBWNCK_V)

	# gtk+.mk Build cleanup
	rm -rf $(BUILD_DIST)/libwnck-3-{0,common,dev}

.PHONY: libwnck libwnck-package
