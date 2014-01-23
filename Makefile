THEOS_DEVICE_IP = 192.168.1.106
ARCHS = armv7 arm64
SDKVERSION = 7.0

include theos/makefiles/common.mk

TWEAK_NAME = messagur
messagur_FILES = Tweak.xm
messagur_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
