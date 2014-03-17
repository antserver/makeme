/*
    me.h -- MakeMe Configuration Header for windows-x86-default

    This header is created by Me during configuration. To change settings, re-run
    configure or define variables in your Makefile to override these default values.
 */

/* Settings */
#ifndef ME_AUTHOR
    #define ME_AUTHOR "Embedthis Software"
#endif
#ifndef ME_COMPANY
    #define ME_COMPANY "embedthis"
#endif
#ifndef ME_COMPATIBLE
    #define ME_COMPATIBLE "0.8.0"
#endif
#ifndef ME_DEBUG
    #define ME_DEBUG 1
#endif
#ifndef ME_DEPTH
    #define ME_DEPTH 1
#endif
#ifndef ME_DESCRIPTION
    #define ME_DESCRIPTION "Embedthis MakeMe"
#endif
#ifndef ME_EJS_DB
    #define ME_EJS_DB 0
#endif
#ifndef ME_EJS_MAIL
    #define ME_EJS_MAIL 0
#endif
#ifndef ME_EJS_MAPPER
    #define ME_EJS_MAPPER 0
#endif
#ifndef ME_EJS_SHELL
    #define ME_EJS_SHELL 1
#endif
#ifndef ME_EJS_TAR
    #define ME_EJS_TAR 1
#endif
#ifndef ME_EJS_TEMPLATE
    #define ME_EJS_TEMPLATE 0
#endif
#ifndef ME_EJS_WEB
    #define ME_EJS_WEB 0
#endif
#ifndef ME_EJS_ZLIB
    #define ME_EJS_ZLIB 1
#endif
#ifndef ME_EJS_ONE_MODULE
    #define ME_EJS_ONE_MODULE 1
#endif
#ifndef ME_EST_CAMELLIA
    #define ME_EST_CAMELLIA 0
#endif
#ifndef ME_EST_DES
    #define ME_EST_DES 0
#endif
#ifndef ME_EST_GEN_PRIME
    #define ME_EST_GEN_PRIME 0
#endif
#ifndef ME_EST_PADLOCK
    #define ME_EST_PADLOCK 0
#endif
#ifndef ME_EST_ROM_TABLES
    #define ME_EST_ROM_TABLES 0
#endif
#ifndef ME_EST_SSL_CLIENT
    #define ME_EST_SSL_CLIENT 0
#endif
#ifndef ME_EST_TEST_CERTS
    #define ME_EST_TEST_CERTS 0
#endif
#ifndef ME_EST_XTEA
    #define ME_EST_XTEA 0
#endif
#ifndef ME_EXTENSIONS_DISCOVER
    #define ME_EXTENSIONS_DISCOVER "dsi,man,man2html,pmaker,ssl,zip"
#endif
#ifndef ME_EXTENSIONS_OMIT
    #define ME_EXTENSIONS_OMIT "openssl,sqlite"
#endif
#ifndef ME_EXTENSIONS_REQUIRE
    #define ME_EXTENSIONS_REQUIRE "winsdk,compiler,lib,link,rc,osdep,ejs,mpr,http,pcre,zlib"
#endif
#ifndef ME_HAS_ATOMIC
    #define ME_HAS_ATOMIC 0
#endif
#ifndef ME_HAS_ATOMIC64
    #define ME_HAS_ATOMIC64 0
#endif
#ifndef ME_HAS_DYN_LOAD
    #define ME_HAS_DYN_LOAD 1
#endif
#ifndef ME_HAS_LIB_EDIT
    #define ME_HAS_LIB_EDIT 0
#endif
#ifndef ME_HAS_LIB_RT
    #define ME_HAS_LIB_RT 0
#endif
#ifndef ME_HAS_MMU
    #define ME_HAS_MMU 1
#endif
#ifndef ME_HAS_STACK_PROTECTOR
    #define ME_HAS_STACK_PROTECTOR 0
#endif
#ifndef ME_HAS_SYNC
    #define ME_HAS_SYNC 0
#endif
#ifndef ME_HAS_SYNC64
    #define ME_HAS_SYNC64 0
#endif
#ifndef ME_HAS_SYNC_CAS
    #define ME_HAS_SYNC_CAS 0
#endif
#ifndef ME_HAS_UNNAMED_UNIONS
    #define ME_HAS_UNNAMED_UNIONS 1
#endif
#ifndef ME_HTTP_PAM
    #define ME_HTTP_PAM 0
#endif
#ifndef ME_MANIFEST
    #define ME_MANIFEST "package/manifest.me"
#endif
#ifndef ME_MPR_LOGGING
    #define ME_MPR_LOGGING 1
#endif
#ifndef ME_NAME
    #define ME_NAME "me"
#endif
#ifndef ME_PLATFORMS
    #define ME_PLATFORMS "local"
#endif
#ifndef ME_PREFIXES
    #define ME_PREFIXES "package-prefixes"
#endif
#ifndef ME_STATIC
    #define ME_STATIC 0
#endif
#ifndef ME_TITLE
    #define ME_TITLE "Embedthis MakeMe"
#endif
#ifndef ME_TUNE
    #define ME_TUNE "speed"
#endif
#ifndef ME_VERSION
    #define ME_VERSION "0.8.0"
#endif

/* Prefixes */
#ifndef ME_ROOT_PREFIX
    #define ME_ROOT_PREFIX "C:"
#endif
#ifndef ME_PROGRAMFILES_PREFIX
    #define ME_PROGRAMFILES_PREFIX "C:/Program Files"
#endif
#ifndef ME_PROGRAMFILES32_PREFIX
    #define ME_PROGRAMFILES32_PREFIX "C:/Program Files"
#endif
#ifndef ME_BASE_PREFIX
    #define ME_BASE_PREFIX "C:/Program Files"
#endif
#ifndef ME_APP_PREFIX
    #define ME_APP_PREFIX "C:/Program Files/Embedthis MakeMe"
#endif
#ifndef ME_VAPP_PREFIX
    #define ME_VAPP_PREFIX "C:/Program Files/Embedthis MakeMe"
#endif
#ifndef ME_DATA_PREFIX
    #define ME_DATA_PREFIX "C:/Program Files/Embedthis MakeMe"
#endif
#ifndef ME_STATE_PREFIX
    #define ME_STATE_PREFIX "C:/Program Files/Embedthis MakeMe"
#endif
#ifndef ME_BIN_PREFIX
    #define ME_BIN_PREFIX "C:/Program Files/Embedthis MakeMe/bin"
#endif
#ifndef ME_INC_PREFIX
    #define ME_INC_PREFIX "C:/Program Files/Embedthis MakeMe/inc"
#endif
#ifndef ME_LIB_PREFIX
    #define ME_LIB_PREFIX "C:/Program Files/Embedthis MakeMe/lib"
#endif
#ifndef ME_MAN_PREFIX
    #define ME_MAN_PREFIX "C:/Program Files/Embedthis MakeMe/man"
#endif
#ifndef ME_ETC_PREFIX
    #define ME_ETC_PREFIX "C:/Program Files/Embedthis MakeMe"
#endif
#ifndef ME_WEB_PREFIX
    #define ME_WEB_PREFIX "C:/Program Files/Embedthis MakeMe/web"
#endif
#ifndef ME_LOG_PREFIX
    #define ME_LOG_PREFIX "C:/Program Files/Embedthis MakeMe/log"
#endif
#ifndef ME_SPOOL_PREFIX
    #define ME_SPOOL_PREFIX "C:/Program Files/Embedthis MakeMe/tmp"
#endif
#ifndef ME_CACHE_PREFIX
    #define ME_CACHE_PREFIX "C:/Program Files/Embedthis MakeMe/cache"
#endif
#ifndef ME_SRC_PREFIX
    #define ME_SRC_PREFIX "C:/Program Files/Embedthis MakeMe/src"
#endif

/* Suffixes */
#ifndef ME_EXE
    #define ME_EXE ".exe"
#endif
#ifndef ME_SHLIB
    #define ME_SHLIB ".lib"
#endif
#ifndef ME_SHOBJ
    #define ME_SHOBJ ".dll"
#endif
#ifndef ME_LIB
    #define ME_LIB ".lib"
#endif
#ifndef ME_OBJ
    #define ME_OBJ ".obj"
#endif

/* Profile */
#ifndef ME_CONFIG_CMD
    #define ME_CONFIG_CMD "me -d -q -platform windows-x86-default -configure . -gen vs"
#endif
#ifndef ME_ME_PRODUCT
    #define ME_ME_PRODUCT 1
#endif
#ifndef ME_PROFILE
    #define ME_PROFILE "default"
#endif
#ifndef ME_TUNE_SPEED
    #define ME_TUNE_SPEED 1
#endif

/* Miscellaneous */
#ifndef ME_MAJOR_VERSION
    #define ME_MAJOR_VERSION 0
#endif
#ifndef ME_MINOR_VERSION
    #define ME_MINOR_VERSION 8
#endif
#ifndef ME_PATCH_VERSION
    #define ME_PATCH_VERSION 0
#endif
#ifndef ME_VNUM
    #define ME_VNUM 00
#endif

/* Extensions */
#ifndef ME_EXT_CC
    #define ME_EXT_CC 1
#endif
#ifndef ME_EXT_DSI
    #define ME_EXT_DSI 1
#endif
#ifndef ME_EXT_EJS
    #define ME_EXT_EJS 1
#endif
#ifndef ME_EXT_EST
    #define ME_EXT_EST 1
#endif
#ifndef ME_EXT_HTTP
    #define ME_EXT_HTTP 1
#endif
#ifndef ME_EXT_LIB
    #define ME_EXT_LIB 1
#endif
#ifndef ME_EXT_LINK
    #define ME_EXT_LINK 1
#endif
#ifndef ME_EXT_MAN
    #define ME_EXT_MAN 1
#endif
#ifndef ME_EXT_MAN2HTML
    #define ME_EXT_MAN2HTML 1
#endif
#ifndef ME_EXT_MATRIXSSL
    #define ME_EXT_MATRIXSSL 0
#endif
#ifndef ME_EXT_MPR
    #define ME_EXT_MPR 1
#endif
#ifndef ME_EXT_NANOSSL
    #define ME_EXT_NANOSSL 0
#endif
#ifndef ME_EXT_OPENSSL
    #define ME_EXT_OPENSSL 0
#endif
#ifndef ME_EXT_OSDEP
    #define ME_EXT_OSDEP 1
#endif
#ifndef ME_EXT_PCRE
    #define ME_EXT_PCRE 1
#endif
#ifndef ME_EXT_PMAKER
    #define ME_EXT_PMAKER 0
#endif
#ifndef ME_EXT_RC
    #define ME_EXT_RC 0
#endif
#ifndef ME_EXT_SQLITE
    #define ME_EXT_SQLITE 0
#endif
#ifndef ME_EXT_SSL
    #define ME_EXT_SSL 1
#endif
#ifndef ME_EXT_VXWORKS
    #define ME_EXT_VXWORKS 1
#endif
#ifndef ME_EXT_WINSDK
    #define ME_EXT_WINSDK 0
#endif
#ifndef ME_EXT_ZIP
    #define ME_EXT_ZIP 1
#endif
#ifndef ME_EXT_ZLIB
    #define ME_EXT_ZLIB 1
#endif
