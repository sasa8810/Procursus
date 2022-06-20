ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += xfce4-dev-tools
XFCE-DEV-TOOLS_VERSION := 4.17.0
DEB_XFCE-DEV-TOOLS_V   ?= $(XFCE-DEV-TOOLS_VERSION)

xfce4-dev-tools-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.al-us.xfce.org/src/xfce/xfce4-dev-tools/$(shell echo $(XFCE-DEV-TOOLS_VERSION) | cut -f-2 -d.)/xfce4-dev-tools-$(XFCE-DEV-TOOLS_VERSION).tar.bz2
	$(call EXTRACT_TAR,xfce4-dev-tools-$(XFCE-DEV-TOOLS_VERSION).tar.bz2,xfce4-dev-tools-$(XFCE-DEV-TOOLS_VERSION),xfce4-dev-tools)

ifneq ($(wildcard $(BUILD_WORK)/xfce4-dev-tools/.build_complete),)
xfce4-dev-tools:
	@echo "Using previously built xfce4-dev-tools."
else
xfce4-dev-tools: xfce4-dev-tools-setup glib2.0 # libx11 libxau libxmu xorgproto xxhash
	cd $(BUILD_WORK)/xfce4-dev-tools && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+sed -i 's/tests/docs/' $(BUILD_WORK)/xfce4-dev-tools/Makefile
	+$(MAKE) -C $(BUILD_WORK)/xfce4-dev-tools
	+$(MAKE) -C $(BUILD_WORK)/xfce4-dev-tools install \
		DESTDIR=$(BUILD_STAGE)/xfce4-dev-tools
	$(call AFTER_BUILD,copy)
endif

xfce4-dev-tools-package: xfce4-dev-tools-stage
	# xfce4-dev-tools.mk Package Structure
	rm -rf $(BUILD_DIST)/xfce4-dev-tools

	# xfce4-dev-tools.mk Prep xfce4-dev-tools
	cp -a $(BUILD_STAGE)/xfce4-dev-tools $(BUILD_DIST)

	# xfce4-dev-tools.mk Sign
	$(call SIGN,xfce4-dev-tools,general.xml)

	# xfce4-dev-tools.mk Make .debs
	$(call PACK,xfce4-dev-tools,DEB_XFCE-DEV-TOOLS_V)

	# xfce4-dev-tools.mk Build cleanup
	rm -rf $(BUILD_DIST)/xfce4-dev-tools

.PHONY: xfce4-dev-tools xfce4-dev-tools-package
