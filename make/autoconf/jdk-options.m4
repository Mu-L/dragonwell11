#
# Copyright (c) 2011, 2023, Oracle and/or its affiliates. All rights reserved.
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
#
# This code is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 only, as
# published by the Free Software Foundation.  Oracle designates this
# particular file as subject to the "Classpath" exception as provided
# by Oracle in the LICENSE file that accompanied this code.
#
# This code is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# version 2 for more details (a copy is included in the LICENSE file that
# accompanied this code).
#
# You should have received a copy of the GNU General Public License version
# 2 along with this work; if not, write to the Free Software Foundation,
# Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
# or visit www.oracle.com if you need additional information or have any
# questions.
#

###############################################################################
# Check which variant of the JDK that we want to build.
# Currently we have:
#    normal:   standard edition
# but the custom make system may add other variants
#
# Effectively the JDK variant gives a name to a specific set of
# modules to compile into the JDK.
AC_DEFUN_ONCE([JDKOPT_SETUP_JDK_VARIANT],
[
  AC_MSG_CHECKING([which variant of the JDK to build])
  AC_ARG_WITH([jdk-variant], [AS_HELP_STRING([--with-jdk-variant],
      [JDK variant to build (normal) @<:@normal@:>@])])

  if test "x$with_jdk_variant" = xnormal || test "x$with_jdk_variant" = x; then
    JDK_VARIANT="normal"
  else
    AC_MSG_ERROR([The available JDK variants are: normal])
  fi

  AC_SUBST(JDK_VARIANT)

  AC_MSG_RESULT([$JDK_VARIANT])
])

###############################################################################
# Set the debug level
#    release: no debug information, all optimizations, no asserts.
#    optimized: no debug information, all optimizations, no asserts, HotSpot target is 'optimized'.
#    fastdebug: debug information (-g), all optimizations, all asserts
#    slowdebug: debug information (-g), no optimizations, all asserts
AC_DEFUN_ONCE([JDKOPT_SETUP_DEBUG_LEVEL],
[
  DEBUG_LEVEL="release"
  AC_MSG_CHECKING([which debug level to use])
  AC_ARG_ENABLE([debug], [AS_HELP_STRING([--enable-debug],
      [set the debug level to fastdebug (shorthand for --with-debug-level=fastdebug) @<:@disabled@:>@])],
      [
        ENABLE_DEBUG="${enableval}"
        DEBUG_LEVEL="fastdebug"
      ], [ENABLE_DEBUG="no"])

  AC_ARG_WITH([debug-level], [AS_HELP_STRING([--with-debug-level],
      [set the debug level (release, fastdebug, slowdebug, optimized) @<:@release@:>@])],
      [
        DEBUG_LEVEL="${withval}"
        if test "x$ENABLE_DEBUG" = xyes; then
          AC_MSG_ERROR([You cannot use both --enable-debug and --with-debug-level at the same time.])
        fi
      ])
  AC_MSG_RESULT([$DEBUG_LEVEL])

  if test "x$DEBUG_LEVEL" != xrelease && \
      test "x$DEBUG_LEVEL" != xoptimized && \
      test "x$DEBUG_LEVEL" != xfastdebug && \
      test "x$DEBUG_LEVEL" != xslowdebug; then
    AC_MSG_ERROR([Allowed debug levels are: release, fastdebug, slowdebug and optimized])
  fi

  # Translate DEBUG_LEVEL to debug level used by Hotspot
  HOTSPOT_DEBUG_LEVEL="$DEBUG_LEVEL"
  if test "x$DEBUG_LEVEL" = xrelease; then
    HOTSPOT_DEBUG_LEVEL="product"
  elif test "x$DEBUG_LEVEL" = xslowdebug; then
    HOTSPOT_DEBUG_LEVEL="debug"
  fi

  if test "x$DEBUG_LEVEL" = xoptimized; then
    # The debug level 'optimized' is a little special because it is currently only
    # applicable to the HotSpot build where it means to build a completely
    # optimized version of the VM without any debugging code (like for the
    # 'release' debug level which is called 'product' in the HotSpot build) but
    # with the exception that it can contain additional code which is otherwise
    # protected by '#ifndef PRODUCT' macros. These 'optimized' builds are used to
    # test new and/or experimental features which are not intended for customer
    # shipment. Because these new features need to be tested and benchmarked in
    # real world scenarios, we want to build the containing JDK at the 'release'
    # debug level.
    DEBUG_LEVEL="release"
  fi

  AC_SUBST(HOTSPOT_DEBUG_LEVEL)
  AC_SUBST(DEBUG_LEVEL)
])

###############################################################################
#
# Should we build only OpenJDK even if closed sources are present?
#
AC_DEFUN_ONCE([JDKOPT_SETUP_OPEN_OR_CUSTOM],
[
  AC_ARG_ENABLE([openjdk-only], [AS_HELP_STRING([--enable-openjdk-only],
      [suppress building custom source even if present @<:@disabled@:>@])],,[enable_openjdk_only="no"])

  AC_MSG_CHECKING([if custom source is suppressed (openjdk-only)])
  AC_MSG_RESULT([$enable_openjdk_only])
  if test "x$enable_openjdk_only" = "xyes"; then
    SUPPRESS_CUSTOM_EXTENSIONS="true"
  elif test "x$enable_openjdk_only" = "xno"; then
    SUPPRESS_CUSTOM_EXTENSIONS="false"
  else
    AC_MSG_ERROR([Invalid value for --enable-openjdk-only: $enable_openjdk_only])
  fi

  # custom-make-dir is deprecated. Please use your custom-hook.m4 to override
  # the IncludeCustomExtension macro.
  UTIL_DEPRECATED_ARG_WITH(custom-make-dir)
])

AC_DEFUN_ONCE([JDKOPT_SETUP_JDK_OPTIONS],
[
  # Should we build a JDK without a graphical UI?
  AC_MSG_CHECKING([headless only])
  AC_ARG_ENABLE([headless-only], [AS_HELP_STRING([--enable-headless-only],
      [only build headless (no GUI) support @<:@disabled@:>@])])

  if test "x$enable_headless_only" = "xyes"; then
    ENABLE_HEADLESS_ONLY="true"
    AC_MSG_RESULT([yes])
  elif test "x$enable_headless_only" = "xno"; then
    ENABLE_HEADLESS_ONLY="false"
    AC_MSG_RESULT([no])
  elif test "x$enable_headless_only" = "x"; then
    ENABLE_HEADLESS_ONLY="false"
    AC_MSG_RESULT([no])
  else
    AC_MSG_ERROR([--enable-headless-only can only take yes or no])
  fi

  AC_SUBST(ENABLE_HEADLESS_ONLY)

  # Should we build the complete docs, or just a lightweight version?
  AC_ARG_ENABLE([full-docs], [AS_HELP_STRING([--enable-full-docs],
      [build complete documentation @<:@enabled if all tools found@:>@])])

  # Verify dependencies
  AC_MSG_CHECKING([for graphviz dot])
  if test "x$DOT" != "x"; then
    AC_MSG_RESULT([yes])
  else
    AC_MSG_RESULT([no, cannot generate full docs])
    FULL_DOCS_DEP_MISSING=true
  fi

  AC_MSG_CHECKING([for pandoc])
  if test "x$PANDOC" != "x"; then
    AC_MSG_RESULT([yes])
  else
    AC_MSG_RESULT([no, cannot generate full docs])
    FULL_DOCS_DEP_MISSING=true
  fi

  AC_MSG_CHECKING([full docs])
  if test "x$enable_full_docs" = xyes; then
    if test "x$FULL_DOCS_DEP_MISSING" = "xtrue"; then
      AC_MSG_RESULT([no, missing dependencies])
      HELP_MSG_MISSING_DEPENDENCY([dot])
      AC_MSG_ERROR([Cannot enable full docs with missing dependencies. See above. $HELP_MSG])
    else
      ENABLE_FULL_DOCS=true
      AC_MSG_RESULT([yes, forced])
    fi
  elif test "x$enable_full_docs" = xno; then
    ENABLE_FULL_DOCS=false
    AC_MSG_RESULT([no, forced])
  elif test "x$enable_full_docs" = x; then
    # Check for prerequisites
    if test "x$FULL_DOCS_DEP_MISSING" = xtrue; then
      ENABLE_FULL_DOCS=false
      AC_MSG_RESULT([no, missing dependencies])
    else
      ENABLE_FULL_DOCS=true
      AC_MSG_RESULT([yes, dependencies present])
    fi
  else
    AC_MSG_ERROR([--enable-full-docs can only take yes or no])
  fi

  AC_SUBST(ENABLE_FULL_DOCS)

  # Choose cacerts source file
  AC_ARG_WITH(cacerts-file, [AS_HELP_STRING([--with-cacerts-file],
      [specify alternative cacerts file])])
  AC_MSG_CHECKING([for cacerts file])
  if test "x$with_cacerts_file" == x; then
    AC_MSG_RESULT([default])
  else
    CACERTS_FILE=$with_cacerts_file
    if test ! -f "$CACERTS_FILE"; then
      AC_MSG_RESULT([fail])
      AC_MSG_ERROR([Specified cacerts file "$CACERTS_FILE" does not exist])
    fi
    AC_MSG_RESULT([$CACERTS_FILE])
  fi
  AC_SUBST(CACERTS_FILE)

  # Enable or disable unlimited crypto
  AC_ARG_ENABLE(unlimited-crypto, [AS_HELP_STRING([--disable-unlimited-crypto],
      [Disable unlimited crypto policy @<:@enabled@:>@])],,
      [enable_unlimited_crypto=yes])
  if test "x$enable_unlimited_crypto" = "xyes"; then
    UNLIMITED_CRYPTO=true
  else
    UNLIMITED_CRYPTO=false
  fi
  AC_SUBST(UNLIMITED_CRYPTO)

  # Should we build the serviceability agent (SA)?
  INCLUDE_SA=true
  if HOTSPOT_CHECK_JVM_VARIANT(zero); then
    INCLUDE_SA=false
  fi
  if test "x$OPENJDK_TARGET_OS" = xaix ; then
    INCLUDE_SA=false
  fi
  if test "x$OPENJDK_TARGET_CPU" = xs390x ; then
    INCLUDE_SA=false
  fi
  AC_SUBST(INCLUDE_SA)

  # Compress jars
  COMPRESS_JARS=false

  AC_SUBST(COMPRESS_JARS)

  # Setup default copyright year. Mostly overridden when building close to a new year.
  AC_ARG_WITH(copyright-year, [AS_HELP_STRING([--with-copyright-year],
      [Set copyright year value for build @<:@current year@:>@])])
  if test "x$with_copyright_year" = xyes; then
    AC_MSG_ERROR([Copyright year must have a value])
  elif test "x$with_copyright_year" != x; then
    COPYRIGHT_YEAR="$with_copyright_year"
  else
    COPYRIGHT_YEAR=`$DATE +'%Y'`
  fi
  AC_SUBST(COPYRIGHT_YEAR)
])

###############################################################################
#
# Enable or disable the elliptic curve crypto implementation
#
AC_DEFUN_ONCE([JDKOPT_DETECT_INTREE_EC],
[
  AC_MSG_CHECKING([if elliptic curve crypto implementation is present])

  if test -d "${TOPDIR}/src/jdk.crypto.ec/share/native/libsunec/impl"; then
    ENABLE_INTREE_EC=true
    AC_MSG_RESULT([yes])
  else
    ENABLE_INTREE_EC=false
    AC_MSG_RESULT([no])
  fi

  AC_SUBST(ENABLE_INTREE_EC)
])

AC_DEFUN_ONCE([JDKOPT_SETUP_DEBUG_SYMBOLS],
[
  #
  # Native debug symbols.
  # This must be done after the toolchain is setup, since we're looking at objcopy.
  #
  AC_MSG_CHECKING([what type of native debug symbols to use])
  AC_ARG_WITH([native-debug-symbols],
      [AS_HELP_STRING([--with-native-debug-symbols],
      [set the native debug symbol configuration (none, internal, external, zipped) @<:@varying@:>@])],
      [
        if test "x$OPENJDK_TARGET_OS" = xwindows; then
          if test "x$withval" = xinternal; then
            AC_MSG_ERROR([Windows does not support the parameter 'internal' for --with-native-debug-symbols])
          fi
        fi
      ],
      [
        if test "x$STATIC_BUILD" = xtrue; then
          with_native_debug_symbols="none"
        else
          with_native_debug_symbols="external"
        fi
      ])
  AC_MSG_RESULT([$with_native_debug_symbols])

  if test "x$with_native_debug_symbols" = xnone; then
    COMPILE_WITH_DEBUG_SYMBOLS=false
    COPY_DEBUG_SYMBOLS=false
    ZIP_EXTERNAL_DEBUG_SYMBOLS=false
  elif test "x$with_native_debug_symbols" = xinternal; then
    COMPILE_WITH_DEBUG_SYMBOLS=true
    COPY_DEBUG_SYMBOLS=false
    ZIP_EXTERNAL_DEBUG_SYMBOLS=false
  elif test "x$with_native_debug_symbols" = xexternal; then

    if test "x$OPENJDK_TARGET_OS" = xsolaris || test "x$OPENJDK_TARGET_OS" = xlinux; then
      if test "x$OBJCOPY" = x; then
        # enabling of enable-debug-symbols and can't find objcopy
        # this is an error
        AC_MSG_ERROR([Unable to find objcopy, cannot enable native debug symbols])
      fi
    fi

    COMPILE_WITH_DEBUG_SYMBOLS=true
    COPY_DEBUG_SYMBOLS=true
    ZIP_EXTERNAL_DEBUG_SYMBOLS=false
  elif test "x$with_native_debug_symbols" = xzipped; then

    if test "x$OPENJDK_TARGET_OS" = xsolaris || test "x$OPENJDK_TARGET_OS" = xlinux; then
      if test "x$OBJCOPY" = x; then
        # enabling of enable-debug-symbols and can't find objcopy
        # this is an error
        AC_MSG_ERROR([Unable to find objcopy, cannot enable native debug symbols])
      fi
    fi

    COMPILE_WITH_DEBUG_SYMBOLS=true
    COPY_DEBUG_SYMBOLS=true
    ZIP_EXTERNAL_DEBUG_SYMBOLS=true
  else
    AC_MSG_ERROR([Allowed native debug symbols are: none, internal, external, zipped])
  fi

  # --enable-debug-symbols is deprecated.
  # Please use --with-native-debug-symbols=[internal,external,zipped] .
  UTIL_DEPRECATED_ARG_ENABLE(debug-symbols, debug_symbols,
        [Please use --with-native-debug-symbols=[[internal,external,zipped]] .])

  # --enable-zip-debug-info is deprecated.
  # Please use --with-native-debug-symbols=zipped .
  UTIL_DEPRECATED_ARG_ENABLE(zip-debug-info, zip_debug_info,
                              [Please use --with-native-debug-symbols=zipped .])

  AC_SUBST(COMPILE_WITH_DEBUG_SYMBOLS)
  AC_SUBST(COPY_DEBUG_SYMBOLS)
  AC_SUBST(ZIP_EXTERNAL_DEBUG_SYMBOLS)

  # Should we add external native debug symbols to the shipped bundles?
  AC_MSG_CHECKING([if we should add external native debug symbols to the shipped bundles])
  AC_ARG_WITH([external-symbols-in-bundles],
      [AS_HELP_STRING([--with-external-symbols-in-bundles],
      [which type of external native debug symbol information shall be shipped in product bundles (none, public, full)
      (e.g. ship full/stripped pdbs on Windows) @<:@none@:>@])])

  if test "x$with_external_symbols_in_bundles" = x || test "x$with_external_symbols_in_bundles" = xnone ; then
    AC_MSG_RESULT([no])
  elif test "x$with_external_symbols_in_bundles" = xfull || test "x$with_external_symbols_in_bundles" = xpublic ; then
    if test "x$OPENJDK_TARGET_OS" != xwindows ; then
      AC_MSG_ERROR([--with-external-symbols-in-bundles currently only works on windows!])
    elif test "x$COPY_DEBUG_SYMBOLS" != xtrue ; then
      AC_MSG_ERROR([--with-external-symbols-in-bundles only works when --with-native-debug-symbols=external is used!])
    elif test "x$with_external_symbols_in_bundles" = xfull ; then
      AC_MSG_RESULT([full])
      SHIP_DEBUG_SYMBOLS=full
    else
      AC_MSG_RESULT([public])
      SHIP_DEBUG_SYMBOLS=public
    fi
  else
    AC_MSG_ERROR([$with_external_symbols_in_bundles is an unknown value for --with-external-symbols-in-bundles])
  fi

  AC_SUBST(SHIP_DEBUG_SYMBOLS)
])

################################################################################
#
# Gcov coverage data for hotspot
#
AC_DEFUN_ONCE([JDKOPT_SETUP_CODE_COVERAGE],
[
  AC_ARG_ENABLE(native-coverage, [AS_HELP_STRING([--enable-native-coverage],
      [enable native compilation with code coverage data@<:@disabled@:>@])])
  GCOV_ENABLED="false"
  if test "x$enable_native_coverage" = "xyes"; then
    if test "x$TOOLCHAIN_TYPE" = "xgcc"; then
      AC_MSG_CHECKING([if native coverage is enabled])
      AC_MSG_RESULT([yes])
      GCOV_CFLAGS="-fprofile-arcs -ftest-coverage -fno-inline"
      GCOV_LDFLAGS="-fprofile-arcs"
      JVM_CFLAGS="$JVM_CFLAGS $GCOV_CFLAGS"
      JVM_LDFLAGS="$JVM_LDFLAGS $GCOV_LDFLAGS"
      CFLAGS_JDKLIB="$CFLAGS_JDKLIB $GCOV_CFLAGS"
      CFLAGS_JDKEXE="$CFLAGS_JDKEXE $GCOV_CFLAGS"
      CXXFLAGS_JDKLIB="$CXXFLAGS_JDKLIB $GCOV_CFLAGS"
      CXXFLAGS_JDKEXE="$CXXFLAGS_JDKEXE $GCOV_CFLAGS"
      LDFLAGS_JDKLIB="$LDFLAGS_JDKLIB $GCOV_LDFLAGS"
      LDFLAGS_JDKEXE="$LDFLAGS_JDKEXE $GCOV_LDFLAGS"
      GCOV_ENABLED="true"
    else
      AC_MSG_ERROR([--enable-native-coverage only works with toolchain type gcc])
    fi
  elif test "x$enable_native_coverage" = "xno"; then
    AC_MSG_CHECKING([if native coverage is enabled])
    AC_MSG_RESULT([no])
  elif test "x$enable_native_coverage" != "x"; then
    AC_MSG_ERROR([--enable-native-coverage can only be assigned "yes" or "no"])
  fi

  AC_SUBST(GCOV_ENABLED)
])

###############################################################################
#
# AddressSanitizer
#
AC_DEFUN_ONCE([JDKOPT_SETUP_ADDRESS_SANITIZER],
[
  AC_ARG_ENABLE(asan, [AS_HELP_STRING([--enable-asan],
      [enable AddressSanitizer if possible @<:@disabled@:>@])])
  ASAN_ENABLED="no"
  if test "x$enable_asan" = "xyes"; then
    case $TOOLCHAIN_TYPE in
      gcc | clang)
        AC_MSG_CHECKING([if asan is enabled])
        AC_MSG_RESULT([yes])
        ASAN_CFLAGS="-fsanitize=address -fno-omit-frame-pointer -Wno-stringop-truncation"
        ASAN_LDFLAGS="-fsanitize=address"
        JVM_CFLAGS="$JVM_CFLAGS $ASAN_CFLAGS"
        JVM_LDFLAGS="$JVM_LDFLAGS $ASAN_LDFLAGS"
        CFLAGS_JDKLIB="$CFLAGS_JDKLIB $ASAN_CFLAGS"
        CFLAGS_JDKEXE="$CFLAGS_JDKEXE $ASAN_CFLAGS"
        CXXFLAGS_JDKLIB="$CXXFLAGS_JDKLIB $ASAN_CFLAGS"
        CXXFLAGS_JDKEXE="$CXXFLAGS_JDKEXE $ASAN_CFLAGS"
        LDFLAGS_JDKLIB="$LDFLAGS_JDKLIB $ASAN_LDFLAGS"
        LDFLAGS_JDKEXE="$LDFLAGS_JDKEXE $ASAN_LDFLAGS"
        ASAN_ENABLED="yes"
        ;;
      *)
        AC_MSG_ERROR([--enable-asan only works with toolchain type gcc or clang])
        ;;
    esac
  elif test "x$enable_asan" = "xno"; then
    AC_MSG_CHECKING([if asan is enabled])
    AC_MSG_RESULT([no])
  elif test "x$enable_asan" != "x"; then
    AC_MSG_ERROR([--enable-asan can only be assigned "yes" or "no"])
  fi

  AC_SUBST(ASAN_ENABLED)
])

################################################################################
#
# Static build support.  When enabled will generate static
# libraries instead of shared libraries for all JDK libs.
#
AC_DEFUN_ONCE([JDKOPT_SETUP_STATIC_BUILD],
[
  AC_ARG_ENABLE([static-build], [AS_HELP_STRING([--enable-static-build],
    [enable static library build @<:@disabled@:>@])])
  STATIC_BUILD=false
  if test "x$enable_static_build" = "xyes"; then
    AC_MSG_CHECKING([if static build is enabled])
    AC_MSG_RESULT([yes])
    if test "x$OPENJDK_TARGET_OS" != "xmacosx"; then
      AC_MSG_ERROR([--enable-static-build is only supported for macosx builds])
    fi
    STATIC_BUILD_CFLAGS="-DSTATIC_BUILD=1"
    CFLAGS_JDKLIB_EXTRA="$CFLAGS_JDKLIB_EXTRA $STATIC_BUILD_CFLAGS"
    CXXFLAGS_JDKLIB_EXTRA="$CXXFLAGS_JDKLIB_EXTRA $STATIC_BUILD_CFLAGS"
    STATIC_BUILD=true
  elif test "x$enable_static_build" = "xno"; then
    AC_MSG_CHECKING([if static build is enabled])
    AC_MSG_RESULT([no])
  elif test "x$enable_static_build" != "x"; then
    AC_MSG_ERROR([--enable-static-build can only be assigned "yes" or "no"])
  fi

  AC_SUBST(STATIC_BUILD)
])

################################################################################
#
# jlink options.
# We always keep packaged modules in JDK image.
#
AC_DEFUN_ONCE([JDKOPT_SETUP_JLINK_OPTIONS],
[
  AC_ARG_ENABLE([keep-packaged-modules], [AS_HELP_STRING([--disable-keep-packaged-modules],
    [Do not keep packaged modules in jdk image @<:@enable@:>@])])

  AC_MSG_CHECKING([if packaged modules are kept])
  if test "x$enable_keep_packaged_modules" = "xyes"; then
    AC_MSG_RESULT([yes])
    JLINK_KEEP_PACKAGED_MODULES=true
  elif test "x$enable_keep_packaged_modules" = "xno"; then
    AC_MSG_RESULT([no])
    JLINK_KEEP_PACKAGED_MODULES=false
  elif test "x$enable_keep_packaged_modules" = "x"; then
    AC_MSG_RESULT([yes (default)])
    JLINK_KEEP_PACKAGED_MODULES=true
  else
    AC_MSG_RESULT([error])
    AC_MSG_ERROR([--enable-keep-packaged-modules accepts no argument])
  fi

  AC_SUBST(JLINK_KEEP_PACKAGED_MODULES)
])

################################################################################
#
# Enable or disable generation of the classlist at build time
#
AC_DEFUN_ONCE([JDKOPT_ENABLE_DISABLE_GENERATE_CLASSLIST],
[
  AC_ARG_ENABLE([generate-classlist], [AS_HELP_STRING([--disable-generate-classlist],
      [forces enabling or disabling of the generation of a CDS classlist at build time.
      Default is to generate it when either the server or client JVMs are built and
      enable-cds is true.])])

  # Check if it's likely that it's possible to generate the classlist. Depending
  # on exact jvm configuration it could be possible anyway.
  if test "x$ENABLE_CDS" = "xtrue" && (HOTSPOT_CHECK_JVM_VARIANT(server) || HOTSPOT_CHECK_JVM_VARIANT(client)); then
    ENABLE_GENERATE_CLASSLIST_POSSIBLE="true"
  else
    ENABLE_GENERATE_CLASSLIST_POSSIBLE="false"
  fi

  AC_MSG_CHECKING([if the CDS classlist generation should be enabled])
  if test "x$enable_generate_classlist" = "xyes"; then
    AC_MSG_RESULT([yes, forced])
    ENABLE_GENERATE_CLASSLIST="true"
    if test "x$ENABLE_GENERATE_CLASSLIST_POSSIBLE" = "xfalse"; then
      AC_MSG_WARN([Generation of classlist might not be possible with JVM Variants $JVM_VARIANTS and enable-cds=$ENABLE_CDS])
    fi
  elif test "x$enable_generate_classlist" = "xno"; then
    AC_MSG_RESULT([no, forced])
    ENABLE_GENERATE_CLASSLIST="false"
  elif test "x$enable_generate_classlist" = "x"; then
    if test "x$ENABLE_GENERATE_CLASSLIST_POSSIBLE" = "xtrue"; then
      AC_MSG_RESULT([yes])
      ENABLE_GENERATE_CLASSLIST="true"
    else
      AC_MSG_RESULT([no])
      ENABLE_GENERATE_CLASSLIST="false"
    fi
  else
    AC_MSG_ERROR([Invalid value for --enable-generate-classlist: $enable_generate_classlist])
  fi

  AC_SUBST(ENABLE_GENERATE_CLASSLIST)
])

################################################################################
#
# Optionally filter resource translations
#
AC_DEFUN([JDKOPT_EXCLUDE_TRANSLATIONS],
[
  AC_ARG_WITH([exclude-translations], [AS_HELP_STRING([--with-exclude-translations],
      [a comma separated list of locales to exclude translations for. Default is
      to include all translations present in the source.])])

  EXCLUDE_TRANSLATIONS=""
  AC_MSG_CHECKING([if any translations should be excluded])
  if test "x$with_exclude_translations" != "x"; then
    EXCLUDE_TRANSLATIONS="${with_exclude_translations//,/ }"
    AC_MSG_RESULT([yes: $EXCLUDE_TRANSLATIONS])
  else
    AC_MSG_RESULT([no])
  fi

  AC_SUBST(EXCLUDE_TRANSLATIONS)
])

################################################################################
#
# Optionally disable man pages
#
AC_DEFUN([JDKOPT_ENABLE_DISABLE_MANPAGES],
[
  AC_ARG_ENABLE([manpages], [AS_HELP_STRING([--disable-manpages],
      [Set to disable building of man pages @<:@enabled@:>@])])

  BUILD_MANPAGES="true"
  AC_MSG_CHECKING([if man pages should be built])
  if test "x$enable_manpages" = "x"; then
    AC_MSG_RESULT([yes])
  elif test "x$enable_manpages" = "xyes"; then
    AC_MSG_RESULT([yes, forced])
  elif test "x$enable_manpages" = "xno"; then
    AC_MSG_RESULT([no, forced])
    BUILD_MANPAGES="false"
  else
    AC_MSG_RESULT([no])
    AC_MSG_ERROR([--enable-manpages can only yes/no or empty])
  fi

  AC_SUBST(BUILD_MANPAGES)
])

################################################################################
#
# Disallow any output from containing absolute paths from the build system.
# This setting defaults to allowed on debug builds and not allowed on release
# builds.
#
AC_DEFUN([JDKOPT_ALLOW_ABSOLUTE_PATHS_IN_OUTPUT],
[
  AC_ARG_ENABLE([absolute-paths-in-output],
      [AS_HELP_STRING([--disable-absolute-paths-in-output],
       [Set to disable to prevent any absolute paths from the build to end up in
        any of the build output. @<:@disabled in release builds, otherwise enabled@:>@])
      ])

  AC_MSG_CHECKING([if absolute paths should be allowed in the build output])
  if test "x$enable_absolute_paths_in_output" = "xno"; then
    AC_MSG_RESULT([no, forced])
    ALLOW_ABSOLUTE_PATHS_IN_OUTPUT="false"
  elif test "x$enable_absolute_paths_in_output" = "xyes"; then
    AC_MSG_RESULT([yes, forced])
    ALLOW_ABSOLUTE_PATHS_IN_OUTPUT="true"
  elif test "x$DEBUG_LEVEL" = "xrelease"; then
    AC_MSG_RESULT([no, release build])
    ALLOW_ABSOLUTE_PATHS_IN_OUTPUT="false"
  else
    AC_MSG_RESULT([yes, debug build])
    ALLOW_ABSOLUTE_PATHS_IN_OUTPUT="true"
  fi

  AC_SUBST(ALLOW_ABSOLUTE_PATHS_IN_OUTPUT)
])

################################################################################
#
# Check and set options related to reproducible builds.
#
AC_DEFUN_ONCE([JDKOPT_SETUP_REPRODUCIBLE_BUILD],
[
  AC_ARG_WITH([source-date], [AS_HELP_STRING([--with-source-date],
      [how to set SOURCE_DATE_EPOCH ('updated', 'current', 'version' a timestamp or an ISO-8601 date) @<:@updated@:>@])],
      [with_source_date_present=true], [with_source_date_present=false])

  AC_MSG_CHECKING([what source date to use])

  if test "x$with_source_date" = xyes; then
    AC_MSG_ERROR([--with-source-date must have a value])
  elif test "x$with_source_date" = xupdated || test "x$with_source_date" = x; then
    # Tell the makefiles to update at each build
    SOURCE_DATE=updated
    AC_MSG_RESULT([determined at build time, from 'updated'])
  elif test "x$with_source_date" = xcurrent; then
    # Set the current time
    SOURCE_DATE=$($DATE +"%s")
    AC_MSG_RESULT([$SOURCE_DATE, from 'current'])
  elif test "x$with_source_date" = xversion; then
    # Use the date from version-numbers
    UTIL_GET_EPOCH_TIMESTAMP(SOURCE_DATE, $DEFAULT_VERSION_DATE)
    if test "x$SOURCE_DATE" = x; then
      AC_MSG_RESULT([unavailable])
      AC_MSG_ERROR([Cannot convert DEFAULT_VERSION_DATE to timestamp])
    fi
    AC_MSG_RESULT([$SOURCE_DATE, from 'version'])
  else
    # It's a timestamp, an ISO-8601 date, or an invalid string
    # Additional [] needed to keep m4 from mangling shell constructs.
    if [ [[ "$with_source_date" =~ ^[0-9][0-9]*$ ]] ] ; then
      SOURCE_DATE=$with_source_date
      AC_MSG_RESULT([$SOURCE_DATE, from timestamp on command line])
    else
      UTIL_GET_EPOCH_TIMESTAMP(SOURCE_DATE, $with_source_date)
      if test "x$SOURCE_DATE" != x; then
        AC_MSG_RESULT([$SOURCE_DATE, from ISO-8601 date on command line])
      else
        AC_MSG_RESULT([unavailable])
        AC_MSG_ERROR([Cannot parse date string "$with_source_date"])
      fi
    fi
  fi

  REPRODUCIBLE_BUILD_DEFAULT=$with_source_date_present

  if test "x$OPENJDK_BUILD_OS" = xwindows && \
      test "x$ALLOW_ABSOLUTE_PATHS_IN_OUTPUT" = xfalse; then
    # To support banning absolute paths on Windows, we must use the -pathmap
    # method, which requires reproducible builds.
    REPRODUCIBLE_BUILD_DEFAULT=true
  fi

  UTIL_ARG_ENABLE(NAME: reproducible-build, DEFAULT: $REPRODUCIBLE_BUILD_DEFAULT,
      RESULT: ENABLE_REPRODUCIBLE_BUILD,
      DESC: [enable reproducible builds (not yet fully functional)],
      DEFAULT_DESC: [enabled if --with-source-date is given or on Windows without absolute paths])

  if test "x$OPENJDK_BUILD_OS" = xwindows && \
      test "x$ALLOW_ABSOLUTE_PATHS_IN_OUTPUT" = xfalse && \
      test "x$ENABLE_REPRODUCIBLE_BUILD" = xfalse; then
    AC_MSG_NOTICE([On Windows it is not possible to combine  --disable-reproducible-builds])
    AC_MSG_NOTICE([with --disable-absolute-paths-in-output.])
    AC_MSG_ERROR([Cannot continue])
  fi

  AC_SUBST(SOURCE_DATE)
  AC_SUBST(ENABLE_REPRODUCIBLE_BUILD)
])

################################################################################
#
# Setup signing on macOS. This can either be setup to sign with a real identity
# and enabling the hardened runtime, or it can simply add the debug entitlement
# com.apple.security.get-task-allow without actually signing any binaries. The
# latter is needed to be able to debug processes and dump core files on modern
# versions of macOS. It can also be skipped completely.
#
# Check if codesign will run with the given parameters
# $1: Parameters to run with
# $2: Checking message
# Sets CODESIGN_SUCCESS=true/false
AC_DEFUN([JDKOPT_CHECK_CODESIGN_PARAMS],
[
  PARAMS="$1"
  MESSAGE="$2"
  CODESIGN_TESTFILE="$CONFIGURESUPPORT_OUTPUTDIR/codesign-testfile"
  $RM "$CODESIGN_TESTFILE"
  $TOUCH "$CODESIGN_TESTFILE"
  CODESIGN_SUCCESS=false
  eval \"$CODESIGN\" $PARAMS \"$CODESIGN_TESTFILE\" 2>&AS_MESSAGE_LOG_FD \
      >&AS_MESSAGE_LOG_FD && CODESIGN_SUCCESS=true
  $RM "$CODESIGN_TESTFILE"
  AC_MSG_CHECKING([$MESSAGE])
  if test "x$CODESIGN_SUCCESS" = "xtrue"; then
    AC_MSG_RESULT([yes])
  else
    AC_MSG_RESULT([no])
  fi
])

AC_DEFUN([JDKOPT_CHECK_CODESIGN_HARDENED],
[
  JDKOPT_CHECK_CODESIGN_PARAMS([-s \"$MACOSX_CODESIGN_IDENTITY\" --option runtime],
      [if codesign with hardened runtime is possible])
])

AC_DEFUN([JDKOPT_CHECK_CODESIGN_DEBUG],
[
  JDKOPT_CHECK_CODESIGN_PARAMS([-s -], [if debug mode codesign is possible])
])

AC_DEFUN([JDKOPT_SETUP_MACOSX_SIGNING],
[
  ENABLE_CODESIGN=false
  if test "x$OPENJDK_TARGET_OS" = "xmacosx" && test "x$CODESIGN" != "x"; then

    UTIL_ARG_WITH(NAME: macosx-codesign, TYPE: literal, OPTIONAL: true,
        VALID_VALUES: [hardened debug auto], DEFAULT: auto,
        ENABLED_DEFAULT: true,
        CHECKING_MSG: [for macosx code signing mode],
        DESC: [set the macosx code signing mode (hardened, debug, auto)]
    )

    MACOSX_CODESIGN_MODE=disabled
    if test "x$MACOSX_CODESIGN_ENABLED" = "xtrue"; then

      # Check for user provided code signing identity.
      UTIL_ARG_WITH(NAME: macosx-codesign-identity, TYPE: string,
          DEFAULT: openjdk_codesign, CHECK_VALUE: UTIL_CHECK_STRING_NON_EMPTY,
          DESC: [specify the macosx code signing identity],
          CHECKING_MSG: [for macosx code signing identity]
      )
      AC_SUBST(MACOSX_CODESIGN_IDENTITY)

      if test "x$MACOSX_CODESIGN" = "xauto"; then
        # Only try to default to hardened signing on release builds
        if test "x$DEBUG_LEVEL" = "xrelease"; then
          JDKOPT_CHECK_CODESIGN_HARDENED
          if test "x$CODESIGN_SUCCESS" = "xtrue"; then
            MACOSX_CODESIGN_MODE=hardened
          fi
        fi
        if test "x$MACOSX_CODESIGN_MODE" = "xdisabled"; then
          JDKOPT_CHECK_CODESIGN_DEBUG
          if test "x$CODESIGN_SUCCESS" = "xtrue"; then
            MACOSX_CODESIGN_MODE=debug
          fi
        fi
        AC_MSG_CHECKING([for macosx code signing mode])
        AC_MSG_RESULT([$MACOSX_CODESIGN_MODE])
      elif test "x$MACOSX_CODESIGN" = "xhardened"; then
        JDKOPT_CHECK_CODESIGN_HARDENED
        if test "x$CODESIGN_SUCCESS" = "xfalse"; then
          AC_MSG_ERROR([Signing with hardened runtime is not possible])
        fi
        MACOSX_CODESIGN_MODE=hardened
      elif test "x$MACOSX_CODESIGN" = "xdebug"; then
        JDKOPT_CHECK_CODESIGN_DEBUG
        if test "x$CODESIGN_SUCCESS" = "xfalse"; then
          AC_MSG_ERROR([Signing in debug mode is not possible])
        fi
        MACOSX_CODESIGN_MODE=debug
      else
        AC_MSG_ERROR([unknown value for --with-macosx-codesign: $MACOSX_CODESIGN])
      fi
    fi
    AC_SUBST(MACOSX_CODESIGN_IDENTITY)
    AC_SUBST(MACOSX_CODESIGN_MODE)
  fi
])
