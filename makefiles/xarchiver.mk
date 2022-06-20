ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += xarchiver
XARCHIVER_VERSION := 0.5.4.18
DEB_XARCHIVER_V   ?= $(XARCHIVER_VERSION)

xarchiver-setup: setup
	$(call GITHUB_ARCHIVE,ib,xarchiver,$(XARCHIVER_VERSION),$(XARCHIVER_VERSION))
	$(call EXTRACT_TAR,xarchiver-$(XARCHIVER_VERSION).tar.gz,xarchiver-$(XARCHIVER_VERSION),xarchiver)
	$(call DO_PATCH,xarchiver,xarchiver,-p1)

ifneq ($(wildcard $(BUILD_WORK)/xarchiver/.build_complete),)
xarchiver:
	@echo "Using previously built xarchiver."
else
xarchiver: xarchiver-setup gtk+3 atk cairo gdk-pixbuf glib2.0 harfbuzz gettext
	cd $(BUILD_WORK)/xarchiver && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xarchiver
	+$(MAKE) -C $(BUILD_WORK)/xarchiver install \
		DESTDIR=$(BUILD_STAGE)/xarchiver
	$(call AFTER_BUILD)
endif

xarchiver-package: xarchiver-stage
	# xarchiver.mk Package Structure
	rm -rf $(BUILD_DIST)/xarchiver

	# xarchiver.mk Prep xarchiver
	cp -a $(BUILD_STAGE)/xarchiver $(BUILD_DIST)

	# xarchiver.mk Sign
	$(call SIGN,xarchiver,general.xml)

	# xarchiver.mk Make .debs
	$(call PACK,xarchiver,DEB_XARCHIVER_V)

	# xarchiver.mk Build cleanup
	rm -rf $(BUILD_DIST)/xarchiver

.PHONY: xarchiver xarchiver-package
