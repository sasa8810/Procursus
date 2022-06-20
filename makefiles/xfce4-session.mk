ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += xfce4-session
XFCE4-SESSION_VERSION := 4.16.0
DEB_XFCE4-SESSION_V   ?= $(XFCE4-SESSION_VERSION)

xfce4-session-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.xfce.org/src/xfce/xfce4-session/$(shell echo $(XFCE4-SESSION_VERSION) | cut -f-2 -d.)//xfce4-session-$(XFCE4-SESSION_VERSION).tar.bz2
	$(call EXTRACT_TAR,xfce4-session-$(XFCE4-SESSION_VERSION).tar.bz2,xfce4-session-$(XFCE4-SESSION_VERSION),xfce4-session)
	$(call DO_PATCH,xfce4-session,xfce4-session,-p1)

ifneq ($(wildcard $(BUILD_WORK)/xfce4-session/.build_complete),)
xfce4-session:
	@echo "Using previously built xfce4-session."
else
xfce4-session: xfce4-session-setup libx11 x11-xserver-utils libice xfconf
	cd $(BUILD_WORK)/xfce4-session && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--x-libraries=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--x-includes=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--disable-polkit \
		--with-backend=darwin \
		--enable-debug=no \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes \
		ac_cv_path_ICEAUTH=$(BUILD_STAGE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/iceauth
	+$(MAKE) -C $(BUILD_WORK)/xfce4-session
	+$(MAKE) -C $(BUILD_WORK)/xfce4-session install \
		DESTDIR=$(BUILD_STAGE)/xfce4-session
	$(call AFTER_BUILD,copy)
endif

xfce4-session-package: xfce4-session-stage
	# xfce4-session.mk Package Structure
	rm -rf $(BUILD_DIST)/xfce4-session

	# xfce4-session.mk Prep xfce4-session
	cp -a $(BUILD_STAGE)/xfce4-session $(BUILD_DIST)

	# xfce4-session.mk Sign
	$(call SIGN,xfce4-session,general.xml)

	# xfce4-session.mk Make .debs
	$(call PACK,xfce4-session,DEB_XFCE4-SESSION_V)

	# xfce4-session.mk Build cleanup
	rm -rf $(BUILD_DIST)/xfce4-session

.PHONY: xfce4-session xfce4-session-package
