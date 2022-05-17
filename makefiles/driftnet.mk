ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += driftnet
DRIFTNET_VERSION := 1.4.0
DEB_DRIFTNET_V   ?= $(DRIFTNET_VERSION)

driftnet-setup: setup
	$(call GITHUB_ARCHIVE,deiv,driftnet,$(DRIFTNET_VERSION),v$(DRIFTNET_VERSION))
	$(call EXTRACT_TAR,driftnet-$(DRIFTNET_VERSION).tar.gz,driftnet-$(DRIFTNET_VERSION),driftnet)
	sed -i 's|options->enable_gtk_display|0|g' $(BUILD_WORK)/driftnet/src/{driftnet,options}.c

ifneq ($(wildcard $(BUILD_WORK)/driftnet/.build_complete),)
driftnet:
	@echo "Using previously built driftnet."
else
driftnet: driftnet-setup libpcap libjpeg-turbo libpng16 libwebp libgif libwebsockets
	cd $(BUILD_WORK)/driftnet && autoreconf -fi && \
	sed -i -e 's|#define realloc rpl_realloc|/* cum */|g' -e 's|#define malloc rpl_malloc|/* IDK */|g' $(BUILD_WORK)/driftnet/configure && \
	./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-debug \
		--disable-display \
		--enable-http-display \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=no \
		ac_cv_lib_gtk_x11_2_0_gtk_main=no \
		LIBS='-lwebp -lpng -ljpeg'
	+$(MAKE) -C $(BUILD_WORK)/driftnet
	+$(MAKE) -C $(BUILD_WORK)/driftnet install \
		DESTDIR=$(BUILD_STAGE)/driftnet
	$(call AFTER_BUILD)
endif

driftnet-package: driftnet-stage
	# driftnet.mk Package Structure
	rm -rf $(BUILD_DIST)/driftnet

	# driftnet.mk Prep driftnet
	cp -a $(BUILD_STAGE)/driftnet $(BUILD_DIST)

	# driftnet.mk Sign
	$(call SIGN,driftnet,general.xml)

	# driftnet.mk Make .debs
	$(call PACK,driftnet,DEB_DRIFTNET_V)

	# driftnet.mk Build cleanup
	rm -rf $(BUILD_DIST)/driftnet

.PHONY: driftnet driftnet-package
