ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += xfce4
DEB_XFCE4_V := 4.16

xfce4: setup
	@echo "xfce4 is just a control file."

xfce4-package: xfce4-stage
	# xfce4.mk Prep xfce4
	mkdir -p $(BUILD_DIST)/xfce4

	# xfce4.mk Make .debs
	$(call PACK,xfce4,DEB_XFCE4_V)

	# xfce4.mk Build cleanup
	rm -rf $(BUILD_DIST)/xfce4

.PHONY: xfce4 xfce4-package
