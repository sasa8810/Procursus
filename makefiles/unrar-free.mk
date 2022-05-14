ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += unrar-free
UNRAR_FREE_VERSION := 0.1.1
DEB_UNRAR_FREE_V   ?= $(UNRAR_FREE_VERSION)

unrar-free-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://gitlab.com/bgermann/unrar-free/-/archive/$(UNRAR_FREE_VERSION)/unrar-free-$(UNRAR_FREE_VERSION).tar.gz
	$(call EXTRACT_TAR,unrar-free-$(UNRAR_FREE_VERSION).tar.gz,unrar-free-$(UNRAR_FREE_VERSION),unrar-free)
	sed -i -e 's|#include <error.h>|#include <mach/error.h>|' -e 's|error (0, 0,|fprintf(stderr,|g' -e 's|error(0, 0,|fprintf(stderr,|g' $(BUILD_WORK)/unrar-free/src/{opts,unrar}.c
	sed -i '1s|^|void show_copyright ();const void* argp_program_version_hook = show_copyright; const char argp_program_bug_address[] = \"team@procurs.us\" ;\n|' $(BUILD_WORK)/unrar-free/src/unrar.c

ifneq ($(wildcard $(BUILD_WORK)/unrar-free/.build_complete),)
unrar-free:
	@echo "Using previously built unrar-free."
else
unrar-free: unrar-free-setup argp-standalone gettext libarchive
	cd $(BUILD_WORK)/unrar-free && autoreconf -i && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		LIBS="-largp -lintl" \
		CFLAGS='-Drpl_malloc=malloc -Drpl_realloc=realloc'
	+$(MAKE) -C $(BUILD_WORK)/unrar-free
	+$(MAKE) -C $(BUILD_WORK)/unrar-free install \
		DESTDIR=$(BUILD_STAGE)/unrar-free
	$(call AFTER_BUILD)
endif

unrar-free-package: unrar-free-stage
	# unrar-free.mk Package Structure
	rm -rf $(BUILD_DIST)/unrar-free

	# unrar-free.mk Prep unrar-free
	cp -a $(BUILD_STAGE)/unrar-free $(BUILD_DIST)

	# unrar-free.mk Sign
	$(call SIGN,unrar-free,general.xml)

	# unrar-free.mk Make .debs
	$(call PACK,unrar-free,DEB_UNRAR_FREE_V)

	# unrar-free.mk Build cleanup
	rm -rf $(BUILD_DIST)/unrar-free

.PHONY: unrar-free unrar-free-package
