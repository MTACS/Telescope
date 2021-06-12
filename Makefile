TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = MobileSlideShow Camera
ARCHS = arm64 arm64e
SYSROOT = $(THEOS)/sdks/iPhoneOS14.2.sdk
DEBUG = 1
FINALPACKAGE = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Telescope

Telescope_FILES = Tweak.xm
Telescope_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
