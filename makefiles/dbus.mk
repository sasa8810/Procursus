ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += dbus
DBUS_VERSION := 1.14.0
DEB_DBUS_V   ?= $(DBUS_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
DBUS_PROFILE := /etc/profile.d
endif

dbus-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dbus.freedesktop.org/releases/dbus/dbus-$(DBUS_VERSION).tar.xz{,.asc}
	$(call PGP_VERIFY,dbus-$(DBUS_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,dbus-$(DBUS_VERSION).tar.xz,dbus-$(DBUS_VERSION),dbus)
	$(call DO_PATCH,dbus,dbus,-p1)

ifneq ($(wildcard $(BUILD_WORK)/dbus/.build_complete),)
dbus:
	@echo "Using previously built dbus."
else
dbus: dbus-setup expat glib2.0 libx11 libsm libice pcre2 zstd lz4 gnupg libxcb libxau libmd libxdmcp
	cd $(BUILD_WORK)/dbus && autoreconf -fiv
	cd $(BUILD_WORK)/dbus && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-doxygen-docs \
		--disable-ducktype-docs \
		--disable-xml-docs \
		--disable-systemd \
		--disable-selinux \
		--disable-apparmor \
		--disable-inotify \
		--enable-launchd \
		--enable-x11-autolaunch \
		--disable-tests \
		--with-launchd-agent-dir=$(MEMO_PREFIX)/Library/LaunchAgents \
		--with-system-pid-file=$(MEMO_PREFIX)/var/run/dbus/pid \
		--with-system-socket=$(MEMO_PREFIX)/var/run/dbus/system_bus_socket \
		--with-dbus-session-bus-listen-address=unix:runtime=yes \
		--with-x \
		--x-libraries=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--x-includes=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		have_x11=yes \
		PKG_CONFIG=$(BUILD_WORK)/cross-pkg-config
	+$(MAKE) -C $(BUILD_WORK)/dbus
	+$(MAKE) -C $(BUILD_WORK)/dbus install \
		DESTDIR=$(BUILD_STAGE)/dbus
	$(call AFTER_BUILD,copy)
endif

dbus-package: dbus-stage
	# dbus.mk Package Structure
	rm -rf $(BUILD_DIST)/dbus{-bin,-daemon,-session-bus-common,-system-bus-common,-x11,} \
		$(BUILD_DIST)/libdbus-{1-3,1-dev}

	mkdir -p $(BUILD_DIST)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec \
		$(BUILD_DIST)/dbus-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/dbus-daemon/{$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin,$(MEMO_PREFIX)/Library/LaunchAgents,$(DBUS_PROFILE)} \
		$(BUILD_DIST)/dbus-session-bus-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dbus-1/services \
		$(BUILD_DIST)/dbus-system-bus-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dbus-1/system-services \
		$(BUILD_DIST)/dbus-x11/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/libdbus-1-3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libdbus-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include} \
	
	# dbus.mk Prep dbus
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec \
		$(BUILD_DIST)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec

	# dbus.mk Prep dbus-bin
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dbus-{cleanup-sockets,monitor,send,update-activation-environment,uuidgen} \
		$(BUILD_DIST)/dbus-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# dbus.mk Prep dbus-daemon
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{dbus-daemon,dbus-run-session} \
		$(BUILD_DIST)/dbus-daemon/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)/Library/LaunchAgents \
		$(BUILD_DIST)/dbus-daemon/$(MEMO_PREFIX)/Library/
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	cp -a $(BUILD_MISC)/dbus/dbus.sh $(BUILD_DIST)/dbus-daemon/etc/profile.d
endif

	# dbus.mk Prep dbus-session-bus-common
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dbus-1/session.conf \
		$(BUILD_DIST)/dbus-session-bus-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dbus-1/


	# dbus.mk Prep dbus-system-bus-common
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dbus-1/system.conf \
		$(BUILD_DIST)/dbus-system-bus-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/dbus-1/

	# dbus.mk Prep dbus-x11
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dbus-launch \
		$(BUILD_DIST)/dbus-x11/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# dbus.mk Prep libdbus-1-3
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libdbus-1{.3,}.dylib \
		$(BUILD_DIST)/libdbus-1-3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# dbus.mk Prep libdbus-1-dev
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		$(BUILD_DIST)/libdbus-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/dbus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*.dylib) \
		$(BUILD_DIST)/libdbus-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# dbus.mk Sign
	$(call SIGN,dbus,general.xml)
	$(call SIGN,dbus-bin,general.xml)
	$(call SIGN,dbus-daemon,general.xml)
	$(call SIGN,dbus-x11,general.xml)
	$(call SIGN,libdbus-1-3,general.xml)
	
	# dbus.mk Make .debs
	$(call PACK,dbus,DEB_DBUS_V)
	$(call PACK,dbus-bin,DEB_DBUS_V)
	$(call PACK,dbus-daemon,DEB_DBUS_V)
	$(call PACK,dbus-session-bus-common,DEB_DBUS_V)
	$(call PACK,dbus-system-bus-common,DEB_DBUS_V)
	$(call PACK,dbus-x11,DEB_DBUS_V)
	$(call PACK,libdbus-1-3,DEB_DBUS_V)
	$(call PACK,libdbus-1-dev,DEB_DBUS_V)
	
	# dbus.mk Build cleanup
	rm -rf $(BUILD_DIST)/dbus{-bin,-daemon,-session-bus-common,-system-bus-common,-x11,} \
		$(BUILD_DIST)/libdbus-{1-3,1-dev}

.PHONY: dbus dbus-package
