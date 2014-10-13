#
#   me-macosx-default.mk -- Makefile to build Embedthis MakeMe for macosx
#

NAME                  := me
VERSION               := 0.8.4
PROFILE               ?= default
ARCH                  ?= $(shell uname -m | sed 's/i.86/x86/;s/x86_64/x64/;s/arm.*/arm/;s/mips.*/mips/')
CC_ARCH               ?= $(shell echo $(ARCH) | sed 's/x86/i686/;s/x64/x86_64/')
OS                    ?= macosx
CC                    ?= clang
CONFIG                ?= $(OS)-$(ARCH)-$(PROFILE)
BUILD                 ?= build/$(CONFIG)
LBIN                  ?= $(BUILD)/bin
PATH                  := $(LBIN):$(PATH)

ME_COM_EJS            ?= 1
ME_COM_EST            ?= 1
ME_COM_HTTP           ?= 1
ME_COM_OPENSSL        ?= 0
ME_COM_OSDEP          ?= 1
ME_COM_PCRE           ?= 1
ME_COM_SQLITE         ?= 0
ME_COM_SSL            ?= 1
ME_COM_VXWORKS        ?= 0
ME_COM_WINSDK         ?= 1
ME_COM_ZLIB           ?= 1

ifeq ($(ME_COM_EST),1)
    ME_COM_SSL := 1
endif
ifeq ($(ME_COM_OPENSSL),1)
    ME_COM_SSL := 1
endif
ifeq ($(ME_COM_EJS),1)
    ME_COM_ZLIB := 1
endif

CFLAGS                += -g -w
DFLAGS                +=  $(patsubst %,-D%,$(filter ME_%,$(MAKEFLAGS))) -DME_COM_EJS=$(ME_COM_EJS) -DME_COM_EST=$(ME_COM_EST) -DME_COM_HTTP=$(ME_COM_HTTP) -DME_COM_OPENSSL=$(ME_COM_OPENSSL) -DME_COM_OSDEP=$(ME_COM_OSDEP) -DME_COM_PCRE=$(ME_COM_PCRE) -DME_COM_SQLITE=$(ME_COM_SQLITE) -DME_COM_SSL=$(ME_COM_SSL) -DME_COM_VXWORKS=$(ME_COM_VXWORKS) -DME_COM_WINSDK=$(ME_COM_WINSDK) -DME_COM_ZLIB=$(ME_COM_ZLIB) 
IFLAGS                += "-I$(BUILD)/inc"
LDFLAGS               += '-Wl,-rpath,@executable_path/' '-Wl,-rpath,@loader_path/'
LIBPATHS              += -L$(BUILD)/bin
LIBS                  += -ldl -lpthread -lm

DEBUG                 ?= debug
CFLAGS-debug          ?= -g
DFLAGS-debug          ?= -DME_DEBUG
LDFLAGS-debug         ?= -g
DFLAGS-release        ?= 
CFLAGS-release        ?= -O2
LDFLAGS-release       ?= 
CFLAGS                += $(CFLAGS-$(DEBUG))
DFLAGS                += $(DFLAGS-$(DEBUG))
LDFLAGS               += $(LDFLAGS-$(DEBUG))

ME_ROOT_PREFIX        ?= 
ME_BASE_PREFIX        ?= $(ME_ROOT_PREFIX)/usr/local
ME_DATA_PREFIX        ?= $(ME_ROOT_PREFIX)/
ME_STATE_PREFIX       ?= $(ME_ROOT_PREFIX)/var
ME_APP_PREFIX         ?= $(ME_BASE_PREFIX)/lib/$(NAME)
ME_VAPP_PREFIX        ?= $(ME_APP_PREFIX)/$(VERSION)
ME_BIN_PREFIX         ?= $(ME_ROOT_PREFIX)/usr/local/bin
ME_INC_PREFIX         ?= $(ME_ROOT_PREFIX)/usr/local/include
ME_LIB_PREFIX         ?= $(ME_ROOT_PREFIX)/usr/local/lib
ME_MAN_PREFIX         ?= $(ME_ROOT_PREFIX)/usr/local/share/man
ME_SBIN_PREFIX        ?= $(ME_ROOT_PREFIX)/usr/local/sbin
ME_ETC_PREFIX         ?= $(ME_ROOT_PREFIX)/etc/$(NAME)
ME_WEB_PREFIX         ?= $(ME_ROOT_PREFIX)/var/www/$(NAME)
ME_LOG_PREFIX         ?= $(ME_ROOT_PREFIX)/var/log/$(NAME)
ME_SPOOL_PREFIX       ?= $(ME_ROOT_PREFIX)/var/spool/$(NAME)
ME_CACHE_PREFIX       ?= $(ME_ROOT_PREFIX)/var/spool/$(NAME)/cache
ME_SRC_PREFIX         ?= $(ME_ROOT_PREFIX)$(NAME)-$(VERSION)


ifeq ($(ME_COM_EJS),1)
    TARGETS           += $(BUILD)/bin/ejs.mod
endif
TARGETS               += $(BUILD)/bin/ejs.testme.es
TARGETS               += $(BUILD)/bin/ejs.testme.mod
ifeq ($(ME_COM_EJS),1)
    TARGETS           += $(BUILD)/bin/ejs
endif
TARGETS               += $(BUILD)/bin/ca.crt
ifeq ($(ME_COM_HTTP),1)
    TARGETS           += $(BUILD)/bin/http
endif
ifeq ($(ME_COM_EST),1)
    TARGETS           += $(BUILD)/bin/libest.dylib
endif
TARGETS               += $(BUILD)/bin/libmprssl.dylib
TARGETS               += $(BUILD)/bin/libtestme.dylib
TARGETS               += $(BUILD)/bin/me
TARGETS               += $(BUILD)/bin/testme
TARGETS               += $(BUILD)/bin/testme.es

unexport CDPATH

ifndef SHOW
.SILENT:
endif

all build compile: prep $(TARGETS)

.PHONY: prep

prep:
	@echo "      [Info] Use "make SHOW=1" to trace executed commands."
	@if [ "$(CONFIG)" = "" ] ; then echo WARNING: CONFIG not set ; exit 255 ; fi
	@if [ "$(ME_APP_PREFIX)" = "" ] ; then echo WARNING: ME_APP_PREFIX not set ; exit 255 ; fi
	@[ ! -x $(BUILD)/bin ] && mkdir -p $(BUILD)/bin; true
	@[ ! -x $(BUILD)/inc ] && mkdir -p $(BUILD)/inc; true
	@[ ! -x $(BUILD)/obj ] && mkdir -p $(BUILD)/obj; true
	@[ ! -f $(BUILD)/inc/me.h ] && cp projects/me-macosx-default-me.h $(BUILD)/inc/me.h ; true
	@if ! diff $(BUILD)/inc/me.h projects/me-macosx-default-me.h >/dev/null ; then\
		cp projects/me-macosx-default-me.h $(BUILD)/inc/me.h  ; \
	fi; true
	@if [ -f "$(BUILD)/.makeflags" ] ; then \
		if [ "$(MAKEFLAGS)" != "`cat $(BUILD)/.makeflags`" ] ; then \
			echo "   [Warning] Make flags have changed since the last build: "`cat $(BUILD)/.makeflags`"" ; \
		fi ; \
	fi
	@echo "$(MAKEFLAGS)" >$(BUILD)/.makeflags

clean:
	rm -f "$(BUILD)/obj/ejs.o"
	rm -f "$(BUILD)/obj/ejsLib.o"
	rm -f "$(BUILD)/obj/ejsc.o"
	rm -f "$(BUILD)/obj/estLib.o"
	rm -f "$(BUILD)/obj/http.o"
	rm -f "$(BUILD)/obj/httpLib.o"
	rm -f "$(BUILD)/obj/libtestme.o"
	rm -f "$(BUILD)/obj/me.o"
	rm -f "$(BUILD)/obj/mprLib.o"
	rm -f "$(BUILD)/obj/mprSsl.o"
	rm -f "$(BUILD)/obj/pcre.o"
	rm -f "$(BUILD)/obj/testme.o"
	rm -f "$(BUILD)/obj/zlib.o"
	rm -f "$(BUILD)/bin/ejs.testme.es"
	rm -f "$(BUILD)/bin/ejsc"
	rm -f "$(BUILD)/bin/ejs"
	rm -f "$(BUILD)/bin/ca.crt"
	rm -f "$(BUILD)/bin/http"
	rm -f "$(BUILD)/bin/libejs.dylib"
	rm -f "$(BUILD)/bin/libest.dylib"
	rm -f "$(BUILD)/bin/libhttp.dylib"
	rm -f "$(BUILD)/bin/libmpr.dylib"
	rm -f "$(BUILD)/bin/libmprssl.dylib"
	rm -f "$(BUILD)/bin/libpcre.dylib"
	rm -f "$(BUILD)/bin/libtestme.dylib"
	rm -f "$(BUILD)/bin/libzlib.dylib"
	rm -f "$(BUILD)/bin/testme"
	rm -f "$(BUILD)/bin/testme.es"

clobber: clean
	rm -fr ./$(BUILD)


#
#   me.h
#
$(BUILD)/inc/me.h: $(DEPS_1)

#
#   osdep.h
#
DEPS_2 += src/paks/osdep/osdep.h
DEPS_2 += $(BUILD)/inc/me.h

$(BUILD)/inc/osdep.h: $(DEPS_2)
	@echo '      [Copy] $(BUILD)/inc/osdep.h'
	mkdir -p "$(BUILD)/inc"
	cp src/paks/osdep/osdep.h $(BUILD)/inc/osdep.h

#
#   mpr.h
#
DEPS_3 += src/paks/mpr/mpr.h
DEPS_3 += $(BUILD)/inc/me.h
DEPS_3 += $(BUILD)/inc/osdep.h

$(BUILD)/inc/mpr.h: $(DEPS_3)
	@echo '      [Copy] $(BUILD)/inc/mpr.h'
	mkdir -p "$(BUILD)/inc"
	cp src/paks/mpr/mpr.h $(BUILD)/inc/mpr.h

#
#   http.h
#
DEPS_4 += src/paks/http/http.h
DEPS_4 += $(BUILD)/inc/mpr.h

$(BUILD)/inc/http.h: $(DEPS_4)
	@echo '      [Copy] $(BUILD)/inc/http.h'
	mkdir -p "$(BUILD)/inc"
	cp src/paks/http/http.h $(BUILD)/inc/http.h

#
#   ejs.slots.h
#
DEPS_5 += src/paks/ejs/ejs.slots.h

$(BUILD)/inc/ejs.slots.h: $(DEPS_5)
	@echo '      [Copy] $(BUILD)/inc/ejs.slots.h'
	mkdir -p "$(BUILD)/inc"
	cp src/paks/ejs/ejs.slots.h $(BUILD)/inc/ejs.slots.h

#
#   pcre.h
#
DEPS_6 += src/paks/pcre/pcre.h

$(BUILD)/inc/pcre.h: $(DEPS_6)
	@echo '      [Copy] $(BUILD)/inc/pcre.h'
	mkdir -p "$(BUILD)/inc"
	cp src/paks/pcre/pcre.h $(BUILD)/inc/pcre.h

#
#   zlib.h
#
DEPS_7 += src/paks/zlib/zlib.h
DEPS_7 += $(BUILD)/inc/me.h

$(BUILD)/inc/zlib.h: $(DEPS_7)
	@echo '      [Copy] $(BUILD)/inc/zlib.h'
	mkdir -p "$(BUILD)/inc"
	cp src/paks/zlib/zlib.h $(BUILD)/inc/zlib.h

#
#   ejs.h
#
DEPS_8 += src/paks/ejs/ejs.h
DEPS_8 += $(BUILD)/inc/me.h
DEPS_8 += $(BUILD)/inc/osdep.h
DEPS_8 += $(BUILD)/inc/mpr.h
DEPS_8 += $(BUILD)/inc/http.h
DEPS_8 += $(BUILD)/inc/ejs.slots.h
DEPS_8 += $(BUILD)/inc/pcre.h
DEPS_8 += $(BUILD)/inc/zlib.h

$(BUILD)/inc/ejs.h: $(DEPS_8)
	@echo '      [Copy] $(BUILD)/inc/ejs.h'
	mkdir -p "$(BUILD)/inc"
	cp src/paks/ejs/ejs.h $(BUILD)/inc/ejs.h

#
#   ejsByteGoto.h
#
DEPS_9 += src/paks/ejs/ejsByteGoto.h

$(BUILD)/inc/ejsByteGoto.h: $(DEPS_9)
	@echo '      [Copy] $(BUILD)/inc/ejsByteGoto.h'
	mkdir -p "$(BUILD)/inc"
	cp src/paks/ejs/ejsByteGoto.h $(BUILD)/inc/ejsByteGoto.h

#
#   est.h
#
DEPS_10 += src/paks/est/est.h
DEPS_10 += $(BUILD)/inc/me.h
DEPS_10 += $(BUILD)/inc/osdep.h

$(BUILD)/inc/est.h: $(DEPS_10)
	@echo '      [Copy] $(BUILD)/inc/est.h'
	mkdir -p "$(BUILD)/inc"
	cp src/paks/est/est.h $(BUILD)/inc/est.h

#
#   testme.h
#
DEPS_11 += src/tm/testme.h
DEPS_11 += $(BUILD)/inc/osdep.h

$(BUILD)/inc/testme.h: $(DEPS_11)
	@echo '      [Copy] $(BUILD)/inc/testme.h'
	mkdir -p "$(BUILD)/inc"
	cp src/tm/testme.h $(BUILD)/inc/testme.h

#
#   ejs.o
#
DEPS_12 += $(BUILD)/inc/ejs.h

$(BUILD)/obj/ejs.o: \
    src/paks/ejs/ejs.c $(DEPS_12)
	@echo '   [Compile] $(BUILD)/obj/ejs.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/ejs.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/paks/ejs/ejs.c

#
#   ejsLib.o
#
DEPS_13 += $(BUILD)/inc/ejs.h
DEPS_13 += $(BUILD)/inc/mpr.h
DEPS_13 += $(BUILD)/inc/pcre.h
DEPS_13 += $(BUILD)/inc/me.h

$(BUILD)/obj/ejsLib.o: \
    src/paks/ejs/ejsLib.c $(DEPS_13)
	@echo '   [Compile] $(BUILD)/obj/ejsLib.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/ejsLib.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/paks/ejs/ejsLib.c

#
#   ejsc.o
#
DEPS_14 += $(BUILD)/inc/ejs.h

$(BUILD)/obj/ejsc.o: \
    src/paks/ejs/ejsc.c $(DEPS_14)
	@echo '   [Compile] $(BUILD)/obj/ejsc.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/ejsc.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/paks/ejs/ejsc.c

#
#   estLib.o
#
DEPS_15 += $(BUILD)/inc/est.h

$(BUILD)/obj/estLib.o: \
    src/paks/est/estLib.c $(DEPS_15)
	@echo '   [Compile] $(BUILD)/obj/estLib.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/estLib.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/paks/est/estLib.c

#
#   http.o
#
DEPS_16 += $(BUILD)/inc/http.h

$(BUILD)/obj/http.o: \
    src/paks/http/http.c $(DEPS_16)
	@echo '   [Compile] $(BUILD)/obj/http.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/http.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/paks/http/http.c

#
#   httpLib.o
#
DEPS_17 += $(BUILD)/inc/http.h

$(BUILD)/obj/httpLib.o: \
    src/paks/http/httpLib.c $(DEPS_17)
	@echo '   [Compile] $(BUILD)/obj/httpLib.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/httpLib.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/paks/http/httpLib.c

#
#   libtestme.o
#
DEPS_18 += $(BUILD)/inc/testme.h

$(BUILD)/obj/libtestme.o: \
    src/tm/libtestme.c $(DEPS_18)
	@echo '   [Compile] $(BUILD)/obj/libtestme.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/libtestme.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/tm/libtestme.c

#
#   me.o
#
DEPS_19 += $(BUILD)/inc/ejs.h

$(BUILD)/obj/me.o: \
    src/me.c $(DEPS_19)
	@echo '   [Compile] $(BUILD)/obj/me.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/me.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/me.c

#
#   mprLib.o
#
DEPS_20 += $(BUILD)/inc/mpr.h

$(BUILD)/obj/mprLib.o: \
    src/paks/mpr/mprLib.c $(DEPS_20)
	@echo '   [Compile] $(BUILD)/obj/mprLib.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/mprLib.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/paks/mpr/mprLib.c

#
#   mprSsl.o
#
DEPS_21 += $(BUILD)/inc/me.h
DEPS_21 += $(BUILD)/inc/mpr.h

$(BUILD)/obj/mprSsl.o: \
    src/paks/mpr/mprSsl.c $(DEPS_21)
	@echo '   [Compile] $(BUILD)/obj/mprSsl.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/mprSsl.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) "-I$(ME_COM_OPENSSL_PATH)/include" src/paks/mpr/mprSsl.c

#
#   pcre.o
#
DEPS_22 += $(BUILD)/inc/me.h
DEPS_22 += $(BUILD)/inc/pcre.h

$(BUILD)/obj/pcre.o: \
    src/paks/pcre/pcre.c $(DEPS_22)
	@echo '   [Compile] $(BUILD)/obj/pcre.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/pcre.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/paks/pcre/pcre.c

#
#   testme.o
#
DEPS_23 += $(BUILD)/inc/ejs.h

$(BUILD)/obj/testme.o: \
    src/tm/testme.c $(DEPS_23)
	@echo '   [Compile] $(BUILD)/obj/testme.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/testme.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/tm/testme.c

#
#   zlib.o
#
DEPS_24 += $(BUILD)/inc/me.h
DEPS_24 += $(BUILD)/inc/zlib.h

$(BUILD)/obj/zlib.o: \
    src/paks/zlib/zlib.c $(DEPS_24)
	@echo '   [Compile] $(BUILD)/obj/zlib.o'
	$(CC) -c $(DFLAGS) -o $(BUILD)/obj/zlib.o -arch $(CC_ARCH) $(CFLAGS) $(IFLAGS) src/paks/zlib/zlib.c

#
#   libmpr
#
DEPS_25 += $(BUILD)/inc/mpr.h
DEPS_25 += $(BUILD)/obj/mprLib.o

$(BUILD)/bin/libmpr.dylib: $(DEPS_25)
	@echo '      [Link] $(BUILD)/bin/libmpr.dylib'
	$(CC) -dynamiclib -o $(BUILD)/bin/libmpr.dylib -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) -install_name @rpath/libmpr.dylib -compatibility_version 0.8 -current_version 0.8 "$(BUILD)/obj/mprLib.o" $(LIBS) 

ifeq ($(ME_COM_PCRE),1)
#
#   libpcre
#
DEPS_26 += $(BUILD)/inc/pcre.h
DEPS_26 += $(BUILD)/obj/pcre.o

$(BUILD)/bin/libpcre.dylib: $(DEPS_26)
	@echo '      [Link] $(BUILD)/bin/libpcre.dylib'
	$(CC) -dynamiclib -o $(BUILD)/bin/libpcre.dylib -arch $(CC_ARCH) $(LDFLAGS) -compatibility_version 0.8 -current_version 0.8 $(LIBPATHS) -install_name @rpath/libpcre.dylib -compatibility_version 0.8 -current_version 0.8 "$(BUILD)/obj/pcre.o" $(LIBS) 
endif

ifeq ($(ME_COM_HTTP),1)
#
#   libhttp
#
DEPS_27 += $(BUILD)/bin/libmpr.dylib
ifeq ($(ME_COM_PCRE),1)
    DEPS_27 += $(BUILD)/bin/libpcre.dylib
endif
DEPS_27 += $(BUILD)/inc/http.h
DEPS_27 += $(BUILD)/obj/httpLib.o

LIBS_27 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_27 += -lpcre
endif

$(BUILD)/bin/libhttp.dylib: $(DEPS_27)
	@echo '      [Link] $(BUILD)/bin/libhttp.dylib'
	$(CC) -dynamiclib -o $(BUILD)/bin/libhttp.dylib -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) -install_name @rpath/libhttp.dylib -compatibility_version 0.8 -current_version 0.8 "$(BUILD)/obj/httpLib.o" $(LIBPATHS_27) $(LIBS_27) $(LIBS_27) $(LIBS) 
endif

ifeq ($(ME_COM_ZLIB),1)
#
#   libzlib
#
DEPS_28 += $(BUILD)/inc/zlib.h
DEPS_28 += $(BUILD)/obj/zlib.o

$(BUILD)/bin/libzlib.dylib: $(DEPS_28)
	@echo '      [Link] $(BUILD)/bin/libzlib.dylib'
	$(CC) -dynamiclib -o $(BUILD)/bin/libzlib.dylib -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) -install_name @rpath/libzlib.dylib -compatibility_version 0.8 -current_version 0.8 "$(BUILD)/obj/zlib.o" $(LIBS) 
endif

ifeq ($(ME_COM_EJS),1)
#
#   libejs
#
ifeq ($(ME_COM_HTTP),1)
    DEPS_29 += $(BUILD)/bin/libhttp.dylib
endif
ifeq ($(ME_COM_PCRE),1)
    DEPS_29 += $(BUILD)/bin/libpcre.dylib
endif
DEPS_29 += $(BUILD)/bin/libmpr.dylib
ifeq ($(ME_COM_ZLIB),1)
    DEPS_29 += $(BUILD)/bin/libzlib.dylib
endif
DEPS_29 += $(BUILD)/inc/ejs.h
DEPS_29 += $(BUILD)/inc/ejs.slots.h
DEPS_29 += $(BUILD)/inc/ejsByteGoto.h
DEPS_29 += $(BUILD)/obj/ejsLib.o

ifeq ($(ME_COM_HTTP),1)
    LIBS_29 += -lhttp
endif
LIBS_29 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_29 += -lpcre
endif
ifeq ($(ME_COM_ZLIB),1)
    LIBS_29 += -lzlib
endif

$(BUILD)/bin/libejs.dylib: $(DEPS_29)
	@echo '      [Link] $(BUILD)/bin/libejs.dylib'
	$(CC) -dynamiclib -o $(BUILD)/bin/libejs.dylib -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) -install_name @rpath/libejs.dylib -compatibility_version 0.8 -current_version 0.8 "$(BUILD)/obj/ejsLib.o" $(LIBPATHS_29) $(LIBS_29) $(LIBS_29) $(LIBS) 
endif

ifeq ($(ME_COM_EJS),1)
#
#   ejsc
#
DEPS_30 += $(BUILD)/bin/libejs.dylib
DEPS_30 += $(BUILD)/obj/ejsc.o

LIBS_30 += -lejs
ifeq ($(ME_COM_HTTP),1)
    LIBS_30 += -lhttp
endif
LIBS_30 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_30 += -lpcre
endif
ifeq ($(ME_COM_ZLIB),1)
    LIBS_30 += -lzlib
endif

$(BUILD)/bin/ejsc: $(DEPS_30)
	@echo '      [Link] $(BUILD)/bin/ejsc'
	$(CC) -o $(BUILD)/bin/ejsc -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) "$(BUILD)/obj/ejsc.o" $(LIBPATHS_30) $(LIBS_30) $(LIBS_30) $(LIBS) 
endif

ifeq ($(ME_COM_EJS),1)
#
#   ejs.mod
#
DEPS_31 += src/paks/ejs/ejs.es
DEPS_31 += $(BUILD)/bin/ejsc

$(BUILD)/bin/ejs.mod: $(DEPS_31)
	( \
	cd src/paks/ejs; \
	echo '   [Compile] ejs.mod' ; \
	../../../$(BUILD)/bin/ejsc --out ../../../$(BUILD)/bin/ejs.mod --optimize 9 --bind --require null ejs.es ; \
	)
endif

#
#   ejs.testme.es
#
DEPS_32 += src/tm/ejs.testme.es

$(BUILD)/bin/ejs.testme.es: $(DEPS_32)
	@echo '      [Copy] $(BUILD)/bin/ejs.testme.es'
	mkdir -p "$(BUILD)/bin"
	cp src/tm/ejs.testme.es $(BUILD)/bin/ejs.testme.es

#
#   ejs.testme.mod
#
DEPS_33 += src/tm/ejs.testme.es
ifeq ($(ME_COM_EJS),1)
    DEPS_33 += $(BUILD)/bin/ejs.mod
endif

$(BUILD)/bin/ejs.testme.mod: $(DEPS_33)
	( \
	cd src/tm; \
	echo '   [Compile] ejs.testme.mod' ; \
	../../$(BUILD)/bin/ejsc --debug --out ../../$(BUILD)/bin/ejs.testme.mod --optimize 9 ejs.testme.es ; \
	)

ifeq ($(ME_COM_EJS),1)
#
#   ejscmd
#
DEPS_34 += $(BUILD)/bin/libejs.dylib
DEPS_34 += $(BUILD)/obj/ejs.o

LIBS_34 += -lejs
ifeq ($(ME_COM_HTTP),1)
    LIBS_34 += -lhttp
endif
LIBS_34 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_34 += -lpcre
endif
ifeq ($(ME_COM_ZLIB),1)
    LIBS_34 += -lzlib
endif

$(BUILD)/bin/ejs: $(DEPS_34)
	@echo '      [Link] $(BUILD)/bin/ejs'
	$(CC) -o $(BUILD)/bin/ejs -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) "$(BUILD)/obj/ejs.o" $(LIBPATHS_34) $(LIBS_34) $(LIBS_34) $(LIBS) -ledit 
endif


#
#   http-ca-crt
#
DEPS_35 += src/paks/http/ca.crt

$(BUILD)/bin/ca.crt: $(DEPS_35)
	@echo '      [Copy] $(BUILD)/bin/ca.crt'
	mkdir -p "$(BUILD)/bin"
	cp src/paks/http/ca.crt $(BUILD)/bin/ca.crt

ifeq ($(ME_COM_HTTP),1)
#
#   httpcmd
#
DEPS_36 += $(BUILD)/bin/libhttp.dylib
DEPS_36 += $(BUILD)/obj/http.o

LIBS_36 += -lhttp
LIBS_36 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_36 += -lpcre
endif

$(BUILD)/bin/http: $(DEPS_36)
	@echo '      [Link] $(BUILD)/bin/http'
	$(CC) -o $(BUILD)/bin/http -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) "$(BUILD)/obj/http.o" $(LIBPATHS_36) $(LIBS_36) $(LIBS_36) $(LIBS) 
endif

ifeq ($(ME_COM_EST),1)
#
#   libest
#
DEPS_37 += $(BUILD)/inc/est.h
DEPS_37 += $(BUILD)/obj/estLib.o

$(BUILD)/bin/libest.dylib: $(DEPS_37)
	@echo '      [Link] $(BUILD)/bin/libest.dylib'
	$(CC) -dynamiclib -o $(BUILD)/bin/libest.dylib -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) -install_name @rpath/libest.dylib -compatibility_version 0.8 -current_version 0.8 "$(BUILD)/obj/estLib.o" $(LIBS) 
endif

#
#   libmprssl
#
DEPS_38 += $(BUILD)/bin/libmpr.dylib
DEPS_38 += $(BUILD)/obj/mprSsl.o

LIBS_38 += -lmpr
ifeq ($(ME_COM_OPENSSL),1)
    LIBS_38 += -lssl
    LIBPATHS_38 += -L$(ME_COM_OPENSSL_PATH)
endif
ifeq ($(ME_COM_OPENSSL),1)
    LIBS_38 += -lcrypto
    LIBPATHS_38 += -L$(ME_COM_OPENSSL_PATH)
endif
ifeq ($(ME_COM_EST),1)
    LIBS_38 += -lest
endif

$(BUILD)/bin/libmprssl.dylib: $(DEPS_38)
	@echo '      [Link] $(BUILD)/bin/libmprssl.dylib'
	$(CC) -dynamiclib -o $(BUILD)/bin/libmprssl.dylib -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS)  -install_name @rpath/libmprssl.dylib -compatibility_version 0.8 -current_version 0.8 "$(BUILD)/obj/mprSsl.o" $(LIBPATHS_38) $(LIBS_38) $(LIBS_38) $(LIBS) 

#
#   libtestme
#
DEPS_39 += $(BUILD)/inc/testme.h
DEPS_39 += $(BUILD)/obj/libtestme.o

$(BUILD)/bin/libtestme.dylib: $(DEPS_39)
	@echo '      [Link] $(BUILD)/bin/libtestme.dylib'
	$(CC) -dynamiclib -o $(BUILD)/bin/libtestme.dylib -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) -install_name @rpath/libtestme.dylib -compatibility_version 0.8 -current_version 0.8 "$(BUILD)/obj/libtestme.o" $(LIBS) 

#
#   me.mod
#
DEPS_40 += src/Builder.es
DEPS_40 += src/Loader.es
DEPS_40 += src/MakeMe.es
DEPS_40 += src/Me.es
DEPS_40 += src/Script.es
DEPS_40 += src/Target.es
DEPS_40 += src/paks/ejs-version/Version.es
ifeq ($(ME_COM_EJS),1)
    DEPS_40 += $(BUILD)/bin/ejs.mod
endif

$(BUILD)/bin/me.mod: $(DEPS_40)
	( \
	cd .; \
	echo '   [Compile] me.mod' ; \
	./$(BUILD)/bin/ejsc --debug --out ./$(BUILD)/bin/me.mod --optimize 9 src/Builder.es src/Loader.es src/MakeMe.es src/Me.es src/Script.es src/Target.es src/paks/ejs-version/Version.es ; \
	)

#
#   runtime
#
DEPS_41 += src/runtime/configure/appweb.me
DEPS_41 += src/runtime/configure/compiler.me
DEPS_41 += src/runtime/configure/lib.me
DEPS_41 += src/runtime/configure/link.me
DEPS_41 += src/runtime/configure/rc.me
DEPS_41 += src/runtime/configure/testme.me
DEPS_41 += src/runtime/configure/vxworks.me
DEPS_41 += src/runtime/configure/winsdk.me
DEPS_41 += src/runtime/master-main.me
DEPS_41 += src/runtime/master-start.me
DEPS_41 += src/runtime/os/freebsd.me
DEPS_41 += src/runtime/os/gcc.me
DEPS_41 += src/runtime/os/linux.me
DEPS_41 += src/runtime/os/macosx.me
DEPS_41 += src/runtime/os/solaris.me
DEPS_41 += src/runtime/os/unix.me
DEPS_41 += src/runtime/os/vxworks.me
DEPS_41 += src/runtime/os/windows.me
DEPS_41 += src/runtime/plugins/Configure.es
DEPS_41 += src/runtime/plugins/Generator.es
DEPS_41 += src/runtime/plugins/Vstudio.es
DEPS_41 += src/runtime/plugins/Xcode.es
DEPS_41 += src/runtime/simple.me
DEPS_41 += src/runtime/standard.me

$(BUILD)/.modify-runtime: $(DEPS_41)
	@echo '      [Copy] $(BUILD)/bin'
	mkdir -p "$(BUILD)/bin/configure"
	cp src/runtime/configure/appweb.me $(BUILD)/bin/configure/appweb.me
	cp src/runtime/configure/compiler.me $(BUILD)/bin/configure/compiler.me
	cp src/runtime/configure/lib.me $(BUILD)/bin/configure/lib.me
	cp src/runtime/configure/link.me $(BUILD)/bin/configure/link.me
	cp src/runtime/configure/rc.me $(BUILD)/bin/configure/rc.me
	cp src/runtime/configure/testme.me $(BUILD)/bin/configure/testme.me
	cp src/runtime/configure/vxworks.me $(BUILD)/bin/configure/vxworks.me
	cp src/runtime/configure/winsdk.me $(BUILD)/bin/configure/winsdk.me
	mkdir -p "$(BUILD)/bin"
	cp src/runtime/master-main.me $(BUILD)/bin/master-main.me
	cp src/runtime/master-start.me $(BUILD)/bin/master-start.me
	mkdir -p "$(BUILD)/bin/os"
	cp src/runtime/os/freebsd.me $(BUILD)/bin/os/freebsd.me
	cp src/runtime/os/gcc.me $(BUILD)/bin/os/gcc.me
	cp src/runtime/os/linux.me $(BUILD)/bin/os/linux.me
	cp src/runtime/os/macosx.me $(BUILD)/bin/os/macosx.me
	cp src/runtime/os/solaris.me $(BUILD)/bin/os/solaris.me
	cp src/runtime/os/unix.me $(BUILD)/bin/os/unix.me
	cp src/runtime/os/vxworks.me $(BUILD)/bin/os/vxworks.me
	cp src/runtime/os/windows.me $(BUILD)/bin/os/windows.me
	mkdir -p "$(BUILD)/bin/plugins"
	cp src/runtime/plugins/Configure.es $(BUILD)/bin/plugins/Configure.es
	cp src/runtime/plugins/Generator.es $(BUILD)/bin/plugins/Generator.es
	cp src/runtime/plugins/Vstudio.es $(BUILD)/bin/plugins/Vstudio.es
	cp src/runtime/plugins/Xcode.es $(BUILD)/bin/plugins/Xcode.es
	cp src/runtime/simple.me $(BUILD)/bin/simple.me
	cp src/runtime/standard.me $(BUILD)/bin/standard.me
	touch "./$(BUILD)/.modify-runtime"

#
#   me
#
DEPS_42 += $(BUILD)/bin/libmpr.dylib
ifeq ($(ME_COM_HTTP),1)
    DEPS_42 += $(BUILD)/bin/libhttp.dylib
endif
ifeq ($(ME_COM_EJS),1)
    DEPS_42 += $(BUILD)/bin/libejs.dylib
endif
DEPS_42 += $(BUILD)/bin/me.mod
DEPS_42 += $(BUILD)/.modify-runtime
DEPS_42 += $(BUILD)/obj/me.o

LIBS_42 += -lmpr
ifeq ($(ME_COM_HTTP),1)
    LIBS_42 += -lhttp
endif
ifeq ($(ME_COM_PCRE),1)
    LIBS_42 += -lpcre
endif
ifeq ($(ME_COM_EJS),1)
    LIBS_42 += -lejs
endif
ifeq ($(ME_COM_ZLIB),1)
    LIBS_42 += -lzlib
endif

$(BUILD)/bin/me: $(DEPS_42)
	@echo '      [Link] $(BUILD)/bin/me'
	$(CC) -o $(BUILD)/bin/me -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) "$(BUILD)/obj/me.o" $(LIBPATHS_42) $(LIBS_42) $(LIBS_42) $(LIBS) 

#
#   testme.mod
#
DEPS_43 += src/tm/testme.es
ifeq ($(ME_COM_EJS),1)
    DEPS_43 += $(BUILD)/bin/ejs.mod
endif

$(BUILD)/bin/testme.mod: $(DEPS_43)
	( \
	cd src/tm; \
	echo '   [Compile] testme.mod' ; \
	../../$(BUILD)/bin/ejsc --debug --out ../../$(BUILD)/bin/testme.mod --optimize 9 testme.es ; \
	)

#
#   testme
#
ifeq ($(ME_COM_EJS),1)
    DEPS_44 += $(BUILD)/bin/libejs.dylib
endif
DEPS_44 += $(BUILD)/bin/testme.mod
DEPS_44 += $(BUILD)/bin/ejs.testme.mod
DEPS_44 += $(BUILD)/obj/testme.o

ifeq ($(ME_COM_EJS),1)
    LIBS_44 += -lejs
endif
ifeq ($(ME_COM_HTTP),1)
    LIBS_44 += -lhttp
endif
LIBS_44 += -lmpr
ifeq ($(ME_COM_PCRE),1)
    LIBS_44 += -lpcre
endif
ifeq ($(ME_COM_ZLIB),1)
    LIBS_44 += -lzlib
endif

$(BUILD)/bin/testme: $(DEPS_44)
	@echo '      [Link] $(BUILD)/bin/testme'
	$(CC) -o $(BUILD)/bin/testme -arch $(CC_ARCH) $(LDFLAGS) $(LIBPATHS) "$(BUILD)/obj/testme.o" $(LIBPATHS_44) $(LIBS_44) $(LIBS_44) $(LIBS) 

#
#   testme.es
#
DEPS_45 += src/tm/testme.es

$(BUILD)/bin/testme.es: $(DEPS_45)
	@echo '      [Copy] $(BUILD)/bin/testme.es'
	mkdir -p "$(BUILD)/bin"
	cp src/tm/testme.es $(BUILD)/bin/testme.es


#
#   installBinary
#
installBinary: $(DEPS_46)
	( \
	cd .; \
	mkdir -p "$(ME_APP_PREFIX)" ; \
	rm -f "$(ME_APP_PREFIX)/latest" ; \
	ln -s "0.8.4" "$(ME_APP_PREFIX)/latest" ; \
	mkdir -p "$(ME_VAPP_PREFIX)/bin" ; \
	cp $(BUILD)/bin/me $(ME_VAPP_PREFIX)/bin/me ; \
	mkdir -p "$(ME_BIN_PREFIX)" ; \
	rm -f "$(ME_BIN_PREFIX)/me" ; \
	ln -s "$(ME_VAPP_PREFIX)/bin/me" "$(ME_BIN_PREFIX)/me" ; \
	cp $(BUILD)/bin/testme $(ME_VAPP_PREFIX)/bin/testme ; \
	mkdir -p "$(ME_BIN_PREFIX)" ; \
	rm -f "$(ME_BIN_PREFIX)/testme" ; \
	ln -s "$(ME_VAPP_PREFIX)/bin/testme" "$(ME_BIN_PREFIX)/testme" ; \
	mkdir -p "$(ME_VAPP_PREFIX)/bin" ; \
	cp $(BUILD)/bin/ejs $(ME_VAPP_PREFIX)/bin/ejs ; \
	cp $(BUILD)/bin/ejsc $(ME_VAPP_PREFIX)/bin/ejsc ; \
	cp $(BUILD)/bin/http $(ME_VAPP_PREFIX)/bin/http ; \
	mkdir -p "$(ME_VAPP_PREFIX)/bin" ; \
	cp $(BUILD)/bin/libejs.dylib $(ME_VAPP_PREFIX)/bin/libejs.dylib ; \
	cp $(BUILD)/bin/libhttp.dylib $(ME_VAPP_PREFIX)/bin/libhttp.dylib ; \
	cp $(BUILD)/bin/libmpr.dylib $(ME_VAPP_PREFIX)/bin/libmpr.dylib ; \
	cp $(BUILD)/bin/libmprssl.dylib $(ME_VAPP_PREFIX)/bin/libmprssl.dylib ; \
	cp $(BUILD)/bin/libpcre.dylib $(ME_VAPP_PREFIX)/bin/libpcre.dylib ; \
	cp $(BUILD)/bin/libzlib.dylib $(ME_VAPP_PREFIX)/bin/libzlib.dylib ; \
	cp $(BUILD)/bin/libtestme.dylib $(ME_VAPP_PREFIX)/bin/libtestme.dylib ; \
	if [ "$(ME_COM_EST)" = 1 ]; then true ; \
	mkdir -p "$(ME_VAPP_PREFIX)/bin" ; \
	cp $(BUILD)/bin/libest.dylib $(ME_VAPP_PREFIX)/bin/libest.dylib ; \
	fi ; \
	if [ "$(ME_COM_OPENSSL)" = 1 ]; then true ; \
	mkdir -p "$(ME_VAPP_PREFIX)/bin" ; \
	cp $(BUILD)/bin/libssl*.dylib* $(ME_VAPP_PREFIX)/bin/libssl*.dylib* ; \
	cp $(BUILD)/bin/libcrypto*.dylib* $(ME_VAPP_PREFIX)/bin/libcrypto*.dylib* ; \
	fi ; \
	mkdir -p "$(ME_VAPP_PREFIX)/bin" ; \
	cp $(BUILD)/bin/ca.crt $(ME_VAPP_PREFIX)/bin/ca.crt ; \
	cp $(BUILD)/bin/ejs.mod $(ME_VAPP_PREFIX)/bin/ejs.mod ; \
	cp $(BUILD)/bin/me.mod $(ME_VAPP_PREFIX)/bin/me.mod ; \
	cp $(BUILD)/bin/testme.mod $(ME_VAPP_PREFIX)/bin/testme.mod ; \
	cp $(BUILD)/bin/ejs.testme.mod $(ME_VAPP_PREFIX)/bin/ejs.testme.mod ; \
	mkdir -p "$(ME_VAPP_PREFIX)/inc" ; \
	cp src/tm/testme.h $(ME_VAPP_PREFIX)/inc/testme.h ; \
	mkdir -p "/usr/src/runtime" ; \
	cp src/runtime/configure /usr/src/runtime/configure ; \
	mkdir -p "/usr/src/runtime/configure" ; \
	cp src/runtime/configure/appweb.me /usr/src/runtime/configure/appweb.me ; \
	cp src/runtime/configure/compiler.me /usr/src/runtime/configure/compiler.me ; \
	cp src/runtime/configure/lib.me /usr/src/runtime/configure/lib.me ; \
	cp src/runtime/configure/link.me /usr/src/runtime/configure/link.me ; \
	cp src/runtime/configure/rc.me /usr/src/runtime/configure/rc.me ; \
	cp src/runtime/configure/testme.me /usr/src/runtime/configure/testme.me ; \
	cp src/runtime/configure/vxworks.me /usr/src/runtime/configure/vxworks.me ; \
	cp src/runtime/configure/winsdk.me /usr/src/runtime/configure/winsdk.me ; \
	cp src/runtime/master-main.me /usr/src/runtime/master-main.me ; \
	cp src/runtime/master-start.me /usr/src/runtime/master-start.me ; \
	cp src/runtime/os /usr/src/runtime/os ; \
	mkdir -p "/usr/src/runtime/os" ; \
	cp src/runtime/os/freebsd.me /usr/src/runtime/os/freebsd.me ; \
	cp src/runtime/os/gcc.me /usr/src/runtime/os/gcc.me ; \
	cp src/runtime/os/linux.me /usr/src/runtime/os/linux.me ; \
	cp src/runtime/os/macosx.me /usr/src/runtime/os/macosx.me ; \
	cp src/runtime/os/solaris.me /usr/src/runtime/os/solaris.me ; \
	cp src/runtime/os/unix.me /usr/src/runtime/os/unix.me ; \
	cp src/runtime/os/vxworks.me /usr/src/runtime/os/vxworks.me ; \
	cp src/runtime/os/windows.me /usr/src/runtime/os/windows.me ; \
	cp src/runtime/plugins /usr/src/runtime/plugins ; \
	mkdir -p "/usr/src/runtime/plugins" ; \
	cp src/runtime/plugins/Configure.es /usr/src/runtime/plugins/Configure.es ; \
	cp src/runtime/plugins/Generator.es /usr/src/runtime/plugins/Generator.es ; \
	cp src/runtime/plugins/Vstudio.es /usr/src/runtime/plugins/Vstudio.es ; \
	cp src/runtime/plugins/Xcode.es /usr/src/runtime/plugins/Xcode.es ; \
	cp src/runtime/simple.me /usr/src/runtime/simple.me ; \
	cp src/runtime/standard.me /usr/src/runtime/standard.me ; \
	mkdir -p "$(ME_VAPP_PREFIX)/doc/man/man1" ; \
	cp doc/public/man/me.1 $(ME_VAPP_PREFIX)/doc/man/man1/me.1 ; \
	mkdir -p "$(ME_MAN_PREFIX)/man1" ; \
	rm -f "$(ME_MAN_PREFIX)/man1/me.1" ; \
	ln -s "$(ME_VAPP_PREFIX)/doc/man/man1/me.1" "$(ME_MAN_PREFIX)/man1/me.1" ; \
	cp doc/public/man/testme.1 $(ME_VAPP_PREFIX)/doc/man/man1/testme.1 ; \
	mkdir -p "$(ME_MAN_PREFIX)/man1" ; \
	rm -f "$(ME_MAN_PREFIX)/man1/testme.1" ; \
	ln -s "$(ME_VAPP_PREFIX)/doc/man/man1/testme.1" "$(ME_MAN_PREFIX)/man1/testme.1" ; \
	)


#
#   install
#
DEPS_47 += stop
DEPS_47 += installBinary
DEPS_47 += start

install: $(DEPS_47)

#
#   uninstall
#
DEPS_48 += stop

uninstall: $(DEPS_48)
	( \
	cd .; \
	rm -fr "$(ME_VAPP_PREFIX)" ; \
	rm -f "$(ME_APP_PREFIX)/latest" ; \
	rmdir -p "$(ME_APP_PREFIX)" 2>/dev/null ; true ; \
	)

#
#   version
#
version: $(DEPS_49)
	( \
	cd .; \
	echo 0.8.4 ; \
	)

