include $(TOPDIR)/rules.mk

PKG_NAME:=libfaketime
PKG_VERSION:=0.9.12
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/wolfcw/libfaketime/archive/refs/tags/v$(PKG_VERSION).tar.gz
PKG_HASH:=4fc32218697c052adcdc5ee395581f2554ca56d086ac817ced2be0d6f1f8a9fa

PKG_MAINTAINER:=Maksim Ilich <m17mich123@mail.ru>
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING

include $(INCLUDE_DIR)/package.mk

define Package/libfaketime
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=libfaketime - fake system time for applications
  URL:=https://github.com/wolfcw/libfaketime
  DEPENDS:=@!USE_GLIBC
endef

define Package/libfaketime/description
  libfaketime allows you to control the system time for applications.
  It intercepts system calls and reports a faked time.
endef

# Musl-specific flags
TARGET_CFLAGS += -std=gnu99 -D_GNU_SOURCE -fPIC
TARGET_CFLAGS += -DFAKE_STAT -DFAKE_UTIME -DFAKE_SLEEP -DFAKE_TIMERS -DFAKE_INTERNAL_CALLS -DFAKE_PTHREAD
TARGET_CFLAGS += -DCLOCK_REALTIME_COARSE=5 -DCLOCK_MONOTONIC_COARSE=6

define Build/Configure
	# Fix PREFIX and LIBDIRNAME in Makefile
	$(SED) 's|^PREFIX.*=.*|PREFIX=/usr|' $(PKG_BUILD_DIR)/src/Makefile
	$(SED) 's|^LIBDIRNAME.*=.*|LIBDIRNAME=/lib|' $(PKG_BUILD_DIR)/src/Makefile
	# Direct fix for faketime.c - replace the problematic lines
	$(SED) 's|ftpl_path = PREFIX LIBDIRNAME "/libfaketimeMT.so.1"|ftpl_path = "/usr/lib/libfaketimeMT.so.1"|' $(PKG_BUILD_DIR)/src/faketime.c
	$(SED) 's|ftpl_path = PREFIX LIBDIRNAME "/libfaketime.so.1"|ftpl_path = "/usr/lib/libfaketime.so.1"|' $(PKG_BUILD_DIR)/src/faketime.c
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		PREFIX="/usr" \
		LIBDIRNAME="/lib" \
		LIBDIR="/usr/lib" \
		FAKETIME_COMPILE_CFLAGS="$(TARGET_CFLAGS)" \
		all
endef

define Package/libfaketime/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/libfaketime.so.1 $(1)/usr/lib/
	$(LN) libfaketime.so.1 $(1)/usr/lib/libfaketime.so
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/libfaketimeMT.so.1 $(1)/usr/lib/
	$(LN) libfaketimeMT.so.1 $(1)/usr/lib/libfaketimeMT.so
	
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/faketime $(1)/usr/bin/
	
	$(INSTALL_DIR) $(1)/usr/share/doc/libfaketime
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/README $(1)/usr/share/doc/libfaketime/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/COPYING $(1)/usr/share/doc/libfaketime/
endef

$(eval $(call BuildPackage,libfaketime))
