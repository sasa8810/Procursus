ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += minetest
MINETEST_VERSION := 5.5.0
DEB_MINETEST_V   ?= $(MINETEST_VERSION)

# TODO: Minetest server
# TODO (another makefile): Minetest mods

minetest-setup: setup
	$(call GITHUB_ARCHIVE,minetest,minetest,$(MINETEST_VERSION),$(MINETEST_VERSION))
	$(call GITHUB_ARCHIVE,minetest,minetest_game,$(MINETEST_VERSION),$(MINETEST_VERSION))
	$(call EXTRACT_TAR,minetest-$(MINETEST_VERSION).tar.gz,minetest-$(MINETEST_VERSION),minetest)
	$(call EXTRACT_TAR,minetest_game-$(MINETEST_VERSION).tar.gz,minetest_game-$(MINETEST_VERSION),minetest/minetest_game)
	$(call DO_PATCH,minetest,minetest,-p1)
	sed -i '1s|^|#include "$(BUILD_MISC)/minetest/endian2.h"\n|' $(BUILD_WORK)/minetest/src/util/serialize.h
	sed -i 's|#include <OpenGL/|#include <GL/|g' $(BUILD_WORK)/minetest/src/client/shader.cpp
	sed -i 's|@PROCURSUS_DESTDIR@|$(BUILD_STAGE)/minetest/|g' $(BUILD_WORK)/minetest/src/CMakeLists.txt
	mkdir -p $(BUILD_WORK)/minetest/build

ifneq ($(wildcard $(BUILD_WORK)/minetest/.build_complete),)
minetest:
	@echo "Using previously built minetest."
else
minetest: minetest-setup mesa irrlichtmt freetype zstd libgmp10 libvorbis curl gettext luajit redis

	cd $(BUILD_WORK)/minetest/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DOPENGL_INCLUDE_DIR='$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/GL' \
		-DUSE_GETTEXT=1 \
		..
	+sed -i 's|-framework OpenGL|-lGL|g' $(BUILD_WORK)/minetest/build/src/CMakeFiles/minetest.dir/link.txt
	+$(MAKE) -C $(BUILD_WORK)/minetest/build
	+$(MAKE) -iC $(BUILD_WORK)/minetest/build install \
		DESTDIR="$(BUILD_STAGE)/minetest"
	mkdir -p $(BUILD_STAGE)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{games,share/games}
	$(LN_SR) $(BUILD_STAGE)/minetest/$(MEMO_PREFIX)/Applications/minetest.app/Contents/Resources $(BUILD_STAGE)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/games/minetest
	sed 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|' < $(BUILD_MISC)/minetest/minetest-wrapper > $(BUILD_STAGE)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/games/minetest
	chmod 755 $(BUILD_STAGE)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/games/minetest
	cp -a $(BUILD_WORK)/minetest/minetest_game $(BUILD_STAGE)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/minetest.app/Contents/Resources/games
	$(call AFTER_BUILD)
endif

minetest-package: minetest-stage
	# minetest.mk Package Structure
	rm -rf $(BUILD_DIST)/minetest{,-data}
	mkdir -p $(BUILD_DIST)/minetest{,-data}/$(MEMO_PREFIX)/Applications/minetest.app/Contents
	mkdir -p $(BUILD_DIST)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# minetest.mk Prep minetest
	cp -a $(BUILD_STAGE)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/minetest.app/Contents/MacOS $(BUILD_DIST)/minetest/$(MEMO_PREFIX)/Applications/minetest.app/Contents
	cp -af $(BUILD_STAGE)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{games,share} $(BUILD_DIST)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# minetest.mk Prep minetest-data
	cp -a $(BUILD_STAGE)/minetest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/minetest.app/Contents/Resources $(BUILD_DIST)/minetest-data/$(MEMO_PREFIX)/Applications/minetest.app/Contents

	# minetest.mk Sign
	$(call SIGN,minetest,minetest.xml)

	# minetest.mk Make .debs
	$(call PACK,minetest,DEB_MINETEST_V)
	$(call PACK,minetest-data,DEB_MINETEST_V)

	# minetest.mk Build cleanup
	rm -rf $(BUILD_DIST)/minetest{,-data}

.PHONY: minetest minetest-package
