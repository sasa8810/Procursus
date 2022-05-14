ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += argp-standalone
ARGP_STANDALONE_VERSION := 1.4.1
DEB_ARGP_STANDALONE_V   ?= $(ARGP_STANDALONE_VERSION)

argp-standalone-setup: setup
	$(call GITHUB_ARCHIVE,ericonr,argp-standalone,$(ARGP_STANDALONE_VERSION),$(ARGP_STANDALONE_VERSION))
	$(call EXTRACT_TAR,argp-standalone-$(ARGP_STANDALONE_VERSION).tar.gz,argp-standalone-$(ARGP_STANDALONE_VERSION),argp-standalone)
	mkdir -p $(BUILD_STAGE)/argp-standalone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

ifneq ($(wildcard $(BUILD_WORK)/argp-standalone/.build_complete),)
argp-standalone:
	@echo "Using previously built argp-standalone."
else
argp-standalone: argp-standalone-setup gettext
	cd $(BUILD_WORK)/argp-standalone && autoreconf -i && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		LIBS=-lintl \
		CFLAGS='-Dfputs_unlocked=fputs -Dfwrite_unlocked=fwrite'
	+$(MAKE) -C $(BUILD_WORK)/argp-standalone libargp.a
	+$(INSTALL) -m644 $(BUILD_WORK)/argp-standalone/libargp.a $(BUILD_STAGE)/argp-standalone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	+$(INSTALL) -m644 $(BUILD_WORK)/argp-standalone/argp.h $(BUILD_STAGE)/argp-standalone/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	$(call AFTER_BUILD,copy)
endif

argp-standalone-package: argp-standalone-stage
	# argp-standalone.mk Package Structure
	rm -rf $(BUILD_DIST)/argp-standalone

	# argp-standalone.mk Prep argp-standalone
	cp -a $(BUILD_STAGE)/argp-standalone $(BUILD_DIST)

	# argp-standalone.mk Sign
	$(call SIGN,argp-standalone,general.xml)

	# argp-standalone.mk Make .debs
	$(call PACK,argp-standalone,DEB_ARGP_STANDALONE_V)

	# argp-standalone.mk Build cleanup
	rm -rf $(BUILD_DIST)/argp-standalone

.PHONY: argp-standalone argp-standalone-package
