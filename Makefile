TARGET := iphone:clang:14.5:9.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = LocalDPI
PACKAGE_FORMAT ?= ipa
ADDITIONAL_OBJCFLAGS = -Wunguarded-availability

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = LocalDPI

LocalDPI_FILES = \
	       main.m \
	       RMAppDelegate.m \
	       RMSettingsViewController.m \
	       RMRootViewController.m \
	       RMStartStopButton.m \
	       UIBezierPath+gear.m \
	       UIBezierPath+house.m \
	       UIBezierPath+power.m
LocalDPI_FRAMEWORKS = UIKit CoreGraphics
LocalDPI_CFLAGS = -fobjc-arc
LocalDPI_CODESIGN_FLAGS = -Sentitlements.xml
include $(THEOS_MAKE_PATH)/application.mk
SUBPROJECTS += LocalDPIExt
include $(THEOS_MAKE_PATH)/aggregate.mk
