ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libglvnd
LIBGLVND_VERSION := 1.4.0
DEB_LIBGLVND_V   ?= $(LIBGLVND_VERSION)

libglvnd-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://gitlab.freedesktop.org/glvnd/libglvnd/-/archive/v$(LIBGLVND_VERSION)/libglvnd-v$(LIBGLVND_VERSION).tar.gz
	$(call EXTRACT_TAR,libglvnd-v$(LIBGLVND_VERSION).tar.gz,libglvnd-v$(LIBGLVND_VERSION),libglvnd)
	#$(call DO_PATCH,libglvnd,libglvnd,-p1)
	mkdir -p $(BUILD_WORK)/libglvnd/build
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
	cpp = '$(CXX)'\n \
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/libglvnd/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/libglvnd/.build_complete),)
libglvnd:
	@echo "Using previously built libglvnd."
else
libglvnd: libglvnd-setup libx11 libxext xorgproto
	cd $(BUILD_WORK)/libglvnd/build && meson \
		--cross-file cross.txt \
		..
	+ninja -C $(BUILD_WORK)/libglvnd/build
	+ninja -C $(BUILD_WORK)/libglvnd/build install \
		DESTDIR="$(BUILD_STAGE)/libglvnd"
	$(call AFTER_BUILD)
endif

libglvnd-package: libglvnd-stage
	# libglvnd.mk Package Structure
	rm -rf $(BUILD_DIST)/libglvnd

	# libglvnd.mk Prep libglvnd
	cp -a $(BUILD_STAGE)/libglvnd $(BUILD_DIST)

	# libglvnd.mk Sign
	$(call SIGN,libglvnd,general.xml)

	# libglvnd.mk Make .debs
	$(call PACK,libglvnd,DEB_LIBGLVND_V)

	# libglvnd.mk Build cleanup
	rm -rf $(BUILD_DIST)/libglvnd

.PHONY: libglvnd libglvnd-package
