# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved.
# Copyright (c) 2011, 2018, 2019, MariaDB Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1335  USA

# This file includes build settings used for MySQL release

INCLUDE(CheckIncludeFiles)
INCLUDE(CheckLibraryExists)
INCLUDE(CheckTypeSize)
INCLUDE(misc)
INCLUDE(mysql_version)

# XXX package_name.cmake uses this too, move it somewhere global
CHECK_TYPE_SIZE("void *" SIZEOF_VOIDP)
IF(SIZEOF_VOIDP EQUAL 4)
  SET(32BIT 1)
ENDIF()
IF(SIZEOF_VOIDP EQUAL 8)
  SET(64BIT 1)
ENDIF()

# MENT-2 Binary information
SET(COMPILATION_COMMENT "MariaDB Enterprise Server")
SET(MYSQL_SERVER_SUFFIX "-enterprise")
SET(CPACK_PACKAGE_URL "http://mariadb.com")
SET(CPACK_PACKAGE_CONTACT "MariaDB Corporation <info@mariadb.com>")
SET(CPACK_PACKAGE_VENDOR "MariaDB Corporation")
SET(CPACK_PACKAGE_DESCRIPTION "MariaDB Enterprise Server: a very fast and robust SQL database server.
  MariaDB documentation can be found at https://mariadb.com/kb/en/
  MariaDB bug reports should be submitted through https://support.mariadb.com/")

# here we're going to unconditionally redefine default source package name
# set in mysql_version.cmake:87
SET(CPACK_SOURCE_PACKAGE_FILE_NAME "mariadb${MYSQL_SERVER_SUFFIX}-${VERSION}")

IF(WIN32)
  SET(MSVC_CRT_TYPE /MT CACHE STRING   "Runtime library - specify runtime library for linking (/MT,/MTd,/MD,/MDd)")
ENDIF()

SET(PLUGIN_S3 STATIC CACHE STRING "")
SET(PLUGIN_SPHINX NO CACHE STRING "")
SET(PLUGIN_TOKUDB NO CACHE STRING "")

# MENT-4 Place not supported plugins in a separate dir
SET(PLUGINS_NOT_SUPPORTED
  "archive"
  "audit_null"
  "auth_0x0100"
  "auth_test_plugin"
  "cassandra"
  "connect"
  "daemon_example"
  "debug_key_management"
  "dialog_examples"
  "example"
  "example_key_management"
  "federated"
  "federatedx"
  "ftexample"
  "handlersocket"
  "mroonga"
  "oqgraph"
  "qa_auth_client"
  "qa_auth_interface"
  "qa_auth_server"
  "query_cache_info"
  "simple_parser"
  "sphinx"
  "test_sql_discovery"
  "test_versioning"
  "tokudb"
  "wsrep_info"
)

# MENT-112 MariaDB Enterprise to use 128 indexes
SET(MAX_INDEXES 128)

# include aws_key_management plugin in release builds
OPTION(AWS_SDK_EXTERNAL_PROJECT  "Allow download and build AWS C++ SDK" ON)

SET(WITH_INNODB_SNAPPY OFF CACHE STRING "")
SET(WITH_NUMA 0 CACHE BOOL "")
IF(WIN32)
  SET(INSTALL_MYSQLTESTDIR "" CACHE STRING "")
  SET(INSTALL_SQLBENCHDIR  "" CACHE STRING "")
  SET(INSTALL_SUPPORTFILESDIR ""  CACHE STRING "")
ELSEIF(RPM)
  SET(WITH_SSL system CACHE STRING "")
  SET(WITH_ZLIB system CACHE STRING "")
  SET(CHECKMODULE /usr/bin/checkmodule CACHE FILEPATH "")
  SET(SEMODULE_PACKAGE /usr/bin/semodule_package CACHE FILEPATH "")
ELSEIF(DEB)
  SET(WITH_SSL system CACHE STRING "")
  SET(WITH_ZLIB system CACHE STRING "")
  SET(WITH_LIBWRAP ON)
  SET(HAVE_EMBEDDED_PRIVILEGE_CONTROL ON)
ELSE()
  SET(WITH_SSL bundled CACHE STRING "")
  SET(WITH_ZLIB bundled CACHE STRING "")
  SET(WITH_READLINE ON CACHE BOOL "")
ENDIF()

IF(NOT COMPILATION_COMMENT)
  SET(COMPILATION_COMMENT "MariaDB Server")
ENDIF()

IF(WIN32)
  IF(NOT CMAKE_USING_VC_FREE_TOOLS)
    # Sign executables with authenticode certificate
    SET(SIGNCODE 1 CACHE BOOL "")
  ENDIF()
ENDIF()

IF(UNIX)
  SET(WITH_EXTRA_CHARSETS all CACHE STRING "")

  IF(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    IF(NOT IGNORE_AIO_CHECK)
      # Ensure aio is available on Linux (required by InnoDB)
      CHECK_INCLUDE_FILES(libaio.h HAVE_LIBAIO_H)
      CHECK_LIBRARY_EXISTS(aio io_queue_init "" HAVE_LIBAIO)
      IF(NOT HAVE_LIBAIO_H OR NOT HAVE_LIBAIO)
        MESSAGE(FATAL_ERROR "
        aio is required on Linux, you need to install the required library:

          Debian/Ubuntu:              apt-get install libaio-dev
          RedHat/Fedora/Oracle Linux: yum install libaio-devel
          SuSE:                       zypper install libaio-devel

        If you really do not want it, pass -DIGNORE_AIO_CHECK to cmake.
        ")
      ENDIF()

      # Remove libaio dependency from mysqld
      #SET(XTRADB_PREFER_STATIC_LIBAIO 1)

      # Unfortunately, linking shared libmysqld with static aio
      # does not work,  unless we add also dynamic one. This also means
      # libmysqld.so will depend on libaio.so
      #SET(LIBMYSQLD_SO_EXTRA_LIBS aio)
    ENDIF()
  ENDIF()

ENDIF()

# Compiler options
IF(UNIX)

  # Default GCC flags
  IF(CMAKE_COMPILER_IS_GNUCC)
    SET(COMMON_C_FLAGS               "-g -static-libgcc -fno-omit-frame-pointer -fno-strict-aliasing  -Wno-uninitialized")
    SET(CMAKE_C_FLAGS_DEBUG          "-O ${COMMON_C_FLAGS}")
    SET(CMAKE_C_FLAGS_RELWITHDEBINFO "-O3 ${COMMON_C_FLAGS}")
  ENDIF()
  IF(CMAKE_COMPILER_IS_GNUCXX)
    SET(COMMON_CXX_FLAGS               "-g -static-libgcc -fno-omit-frame-pointer -fno-strict-aliasing -Wno-uninitialized")
    SET(CMAKE_CXX_FLAGS_DEBUG          "-O ${COMMON_CXX_FLAGS}")
    SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 ${COMMON_CXX_FLAGS}")
  ENDIF()

  # IBM Z flags
  IF(CMAKE_SYSTEM_PROCESSOR MATCHES "s390x")
    IF(RPM MATCHES "(rhel|centos)6" OR RPM MATCHES "(suse|sles)11")
      SET(z_flags "-funroll-loops -march=z9-109 -mtune=z10 ")
    ELSEIF(RPM MATCHES "(rhel|centos)7" OR RPM MATCHES "(suse|sles)12")
      SET(z_flags "-funroll-loops -march=z196 -mtune=zEC12 ")
    ELSE()
      SET(z_flags "")
    ENDIF()

    IF(CMAKE_COMPILER_IS_GNUCC)
      SET(CMAKE_C_FLAGS_RELWITHDEBINFO "${z_flags}${CMAKE_C_FLAGS_RELWITHDEBINFO}")
    ENDIF()
    IF(CMAKE_COMPILER_IS_GNUCXX)
      SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${z_flags}${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
    ENDIF()
    UNSET(z_flags)
  ENDIF()

  # HPUX flags
  IF(CMAKE_SYSTEM_NAME MATCHES "HP-UX")
    IF(CMAKE_C_COMPILER_ID MATCHES "HP")
      IF(CMAKE_SYSTEM_PROCESSOR MATCHES "ia64")
        SET(COMMON_C_FLAGS                 "+DSitanium2 -mt -AC99")
        SET(COMMON_CXX_FLAGS               "+DSitanium2 -mt -Aa")
        SET(CMAKE_C_FLAGS_DEBUG            "+O0 -g ${COMMON_C_FLAGS}")
        SET(CMAKE_CXX_FLAGS_DEBUG          "+O0 -g ${COMMON_CXX_FLAGS}")
	# We have seen compiler bugs with optimisation and -g, so disabled for now
        SET(CMAKE_C_FLAGS_RELWITHDEBINFO   "+O2 ${COMMON_C_FLAGS}")
        SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "+O2 ${COMMON_CXX_FLAGS}")
      ENDIF()
    ENDIF()
    SET(WITH_SSL no)
  ENDIF()

  # Linux flags
  IF(CMAKE_SYSTEM_NAME MATCHES "Linux")
    IF(CMAKE_C_COMPILER_ID MATCHES "Intel")
      SET(COMMON_C_FLAGS                 "-static-intel -static-libgcc -g -mp -restrict")
      SET(COMMON_CXX_FLAGS               "-static-intel -static-libgcc -g -mp -restrict -fno-exceptions -fno-rtti")
      IF(CMAKE_SYSTEM_PROCESSOR MATCHES "ia64")
        SET(COMMON_C_FLAGS               "${COMMON_C_FLAGS} -no-ftz -no-prefetch")
        SET(COMMON_CXX_FLAGS             "${COMMON_CXX_FLAGS} -no-ftz -no-prefetch")
      ENDIF()
      SET(CMAKE_C_FLAGS_DEBUG            "${COMMON_C_FLAGS}")
      SET(CMAKE_CXX_FLAGS_DEBUG          "${COMMON_CXX_FLAGS}")
      SET(CMAKE_C_FLAGS_RELWITHDEBINFO   "-O3 -unroll2 -ip ${COMMON_C_FLAGS}")
      SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 -unroll2 -ip ${COMMON_CXX_FLAGS}")
      SET(WITH_SSL no)
    ENDIF()
  ENDIF()

  # Default Clang flags
  IF(CMAKE_C_COMPILER_ID MATCHES "Clang")
    SET(COMMON_C_FLAGS               "-g -fno-omit-frame-pointer -fno-strict-aliasing")
    SET(CMAKE_C_FLAGS_DEBUG          "${COMMON_C_FLAGS}")
    SET(CMAKE_C_FLAGS_RELWITHDEBINFO "-O3 ${COMMON_C_FLAGS}")
  ENDIF()
  IF(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    SET(COMMON_CXX_FLAGS               "-g -fno-omit-frame-pointer -fno-strict-aliasing")
    SET(CMAKE_CXX_FLAGS_DEBUG          "${COMMON_CXX_FLAGS}")
    SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 ${COMMON_CXX_FLAGS}")
  ENDIF()

  # Solaris flags
  IF(CMAKE_SYSTEM_NAME MATCHES "SunOS")
    IF(CMAKE_SYSTEM_VERSION VERSION_GREATER "5.9")
      # Link mysqld with mtmalloc on Solaris 10 and later
      SET(WITH_MYSQLD_LDFLAGS "-lmtmalloc" CACHE STRING "")
    ENDIF()
    IF(CMAKE_C_COMPILER_ID MATCHES "SunPro")
      IF(CMAKE_SYSTEM_PROCESSOR MATCHES "i386")
        SET(COMMON_C_FLAGS                   "-g -mt -fsimple=1 -ftrap=%none -nofstore -xbuiltin=%all -xlibmil -xlibmopt -xtarget=generic")
        SET(COMMON_CXX_FLAGS                 "-g0 -mt -fsimple=1 -ftrap=%none -nofstore -xbuiltin=%all -features=no%except -xlibmil -xlibmopt -xtarget=generic")
        SET(CMAKE_C_FLAGS_DEBUG              "-xO1 ${COMMON_C_FLAGS}")
        SET(CMAKE_CXX_FLAGS_DEBUG            "-xO1 ${COMMON_CXX_FLAGS}")
        IF(32BIT)
          SET(CMAKE_C_FLAGS_RELWITHDEBINFO   "-xO2 ${COMMON_C_FLAGS}")
          SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-xO2 ${COMMON_CXX_FLAGS}")
        ELSEIF(64BIT)
          SET(CMAKE_C_FLAGS_RELWITHDEBINFO   "-xO3 ${COMMON_C_FLAGS}")
          SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-xO3 ${COMMON_CXX_FLAGS}")
        ENDIF()
      ELSE()
        # Assume !x86 is SPARC
        SET(COMMON_C_FLAGS                 "-g -Xa -xstrconst -mt")
        SET(COMMON_CXX_FLAGS               "-g0 -noex -mt")
        IF(32BIT)
          SET(COMMON_C_FLAGS               "${COMMON_C_FLAGS} -xarch=sparc")
          SET(COMMON_CXX_FLAGS             "${COMMON_CXX_FLAGS} -xarch=sparc")
	ENDIF()
        SET(CMAKE_C_FLAGS_DEBUG            "${COMMON_C_FLAGS}")
        SET(CMAKE_CXX_FLAGS_DEBUG          "${COMMON_CXX_FLAGS}")
        SET(CMAKE_C_FLAGS_RELWITHDEBINFO   "-xO3 ${COMMON_C_FLAGS}")
        SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-xO3 ${COMMON_CXX_FLAGS}")
      ENDIF()
    ENDIF()
  ENDIF()
ENDIF()