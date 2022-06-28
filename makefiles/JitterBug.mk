ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += jitterbugpair
JITTERBUG_VERSION := 1.3.0
DEB_JITTERBUG_V   ?= $(JITTERBUG_VERSION)

jitterbugpair-setup: setup
	$(call GIT_CLONE,https://github.com/osy/Jitterbug,v1.3.0,jitterbugpair)
	mkdir -p $(BUILD_WORK)/jitterbugpair/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/jitterbugpair/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/jitterbugpair/.build_complete),)
jitterbugpair:
	@echo "Using previously built JitterBug."
else
jitterbugpair: jitterbugpair-setup usbmuxd
	cd $(BUILD_WORK)/jitterbugpair/build && meson \
		--cross-file cross.txt \
		..
	+ninja -C $(BUILD_WORK)/jitterbugpair/build
	+DESTDIR="$(BUILD_STAGE)/jitterbugpair" ninja -C $(BUILD_WORK)/jitterbugpair/build install
	$(call AFTER_BUILD)
endif

jitterbugpair-package: jitterbugpair-stage
	# JitterBug.mk Package Structure
	rm -rf $(BUILD_DIST)/jitterbugpair

	# JitterBug.mk Prep JitterBug
	cp -a $(BUILD_STAGE)/jitterbugpair $(BUILD_DIST)

	# JitterBug.mk Sign
	$(call SIGN,jitterbugpair,general.xml)

	# JitterBug.mk Make .debs
	$(call PACK,jitterbugpair,DEB_JITTERBUG_V)

	# JitterBug.mk Build cleanup
	rm -rf $(BUILD_DIST)/jitterbugpair

.PHONY: jitterbugpair jitterbugpair-package
