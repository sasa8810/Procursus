ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += wine
WINE_VERSION := 7.11
DEB_WINE_V   ?= $(WINE_VERSION)

# Notice: Please do not use LLVM tools with mismatch version. It will cause issues here.

wine-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://dl.winehq.org/wine/source/7.x/wine-$(WINE_VERSION).tar.xz{,.sign}
	$(call PGP_VERIFY,wine-$(WINE_VERSION).tar.xz,sign)
	$(call EXTRACT_TAR,wine-$(WINE_VERSION).tar.xz,wine-$(WINE_VERSION),wine)
	$(call EXTRACT_TAR,wine-$(WINE_VERSION).tar.xz,wine-$(WINE_VERSION),../../native/wine)
	$(call DO_PATCH,wine,wine,-p1)
	$(call DO_PATCH,wine-tools,../../native/wine,-p1)

ifneq ($(call HAS_COMMAND,lld-link),1)
wine:
	$(error lld-link is required to build wine)
else ifneq ($(wildcard $(BUILD_WORK)/wine/.build_complete),)
wine:
	@echo "Using previously built wine."
else
wine: wine-setup gettext libtiff glib2.0 dbus fontconfig freetype glib2.0 gnutls libjpeg-turbo libpng16 mesa libx11 libxau libxaw libxcb libxcursor libxdamage libxdmcp libxext libxfont2 libxi libxinerama libxkbfile libxmu libxpm libxrandr libxrender libxres libxss libxt libxtst libxvidcore libxxf86vm sdl2 lcms2 libpcap libusb
	mkdir -p $(BUILD_WORK)/../../native/wine
	cd $(BUILD_WORK)/../../native/wine && unset CC CXX LD CFLAGS CPPFLAGS CXXFLAGS LDFLAGS && ./configure -C \
		--without-{alsa,capi,coreaudio,cups,dbus,gettext,gphoto,gnutls,gssapi,gstreamer,inotify,krb5,ldap,mingw,netapi,openal,opencl,opengl,osmesa,oss,pcap,pthread,pulse,sane,sdl,udev,unwind,usb,v4l2,vulkan,xcomposite,xcursor,xfixes,xinerama,xinput,xinput2,xrandr,xrender,xshape,xshm,xxf86vm} \
		--disable-win16 \
		--enable-win64 \
		--with-fontconfig \
		--with-freetype \
		ac_cv_mabi_ms=yes \
		CFLAGS='-Wall -Wextra -O3 -I/opt/procursus/include/freetype2 -I/opt/procursus/include/fontconfig -I/usr/include/freetype2 -I/usr/include/fontconfig -I/usr/include -DLD64_I_GUESS=\"$(LD)\" $(CFLAGS_FOR_BUILD)' \
		LDFLAGS='-L/opt/procursus/lib $(LDFLAGS_FOR_BUILD)'
	sed -i 's|header = read_file( path|header = read_file(getenv("LOCALE_NLS")|g' $(BUILD_WORK)/../../native/wine/tools/wrc/utils.c
	+$(MAKE) -C $(BUILD_WORK)/../../native/wine __tooldeps__
ifeq (,$(findstring darwin,$(MEMO_PREFIX)))
	sed -i -e 's/-framework ApplicationServices//' -e 's/-framework AppKit//' $(BUILD_WORK)/wine/configure
	#sed -i '/enable_advpack/d' $(BUILD_WORK)/wine/configure
endif
	cd $(BUILD_WORK)/wine && true -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-win16 \
		--enable-win64 \
		--x-includes=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		--x-libraries=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--disable-werror \
		--without-alsa \
		--without-capi \
		--with-coreaudio \
		--with-cups \
		--with-dbus \
		--with-float-abi=hard \
		--with-fontconfig \
		--without-gphoto \
		--with-gettext \
		--with-freetype \
		--without-gssapi \
		--with-gettextpo \
		--with-gnutls \
		--without-gstreamer \
		--without-inotify \
		--without-krb5 \
		--without-ldap \
		--with-mingw \
		--without-netapi \
		--without-openal \
		--without-opencl \
		--with-opengl \
		--with-osmesa \
		--without-oss \
		--with-pcap \
		--with-pthread \
		--without-sane \
		--with-sdl \
		--without-udev \
		--without-unwind \
		--without-usb \
		--without-v4l2 \
		--without-vulkan \
		--without-xcomposite \
		--with-xcursor \
		--with-xinerama \
		--without-xinput \
		--with-xinput2 \
		--with-xrandr \
		--with-xrender \
		--without-xshape \
		--without-xshm \
		--with-xxf86vm \
		--with-x \
		--disable-tests \
		--with-wine-tools=$(BUILD_WORK)/../../native/wine \
		CFLAGS="$(CFLAGS) -fembed-bitcode=off -fno-lto" \
		LDFLAGS="$(LDFLAGS) -fno-lto"
	+LOCALE_NLS="$(BUILD_WORK)/wine/nls/locale.nls" MEMO_ARCH='$(MEMO_ARCH)' PLATFORM_VERSION_MIN='$(PLATFORM_VERSION_MIN)' $(MAKE) -C $(BUILD_WORK)/wine
	+$(MAKE) -C $(BUILD_WORK)/wine install \
		DESTDIR=$(BUILD_STAGE)/wine
	$(call AFTER_BUILD,copy)
endif

wine-package: wine-stage
	# wine.mk Package Structure
	rm -rf $(BUILD_DIST)/wine

	# wine.mk Prep wine
	cp -a $(BUILD_STAGE)/wine $(BUILD_DIST)

	# wine.mk Sign
	$(call SIGN,wine,general.xml)

	# wine.mk Make .debs
	$(call PACK,wine,DEB_WINE_V)

	# wine.mk Build cleanup
	rm -rf $(BUILD_DIST)/wine

.PHONY: wine wine-package
