#.rst:
# ECMSetupVersion
# ---------------
#
# Handle library version information.
#
# ::
#
#   ecm_setup_version(<version>
#                     VARIABLE_PREFIX <prefix>
#                     [SOVERSION <soversion>]
#                     [VERSION_HEADER <filename>]
#                     [PACKAGE_VERSION_FILE <filename>
#                           [COMPATIBILITY <compat>
#                               [FIRST_PRERELEASE_VERSION <prerelease_version>]]] )
#
# This parses a version string and sets up a standard set of version variables.
# It can optionally also create a C version header file and a CMake package
# version file to install along with the library.
#
# If the ``<version>`` argument is of the form ``<major>.<minor>.<patch>``
# (or ``<major>.<minor>.<patch>.<tweak>``), The following CMake variables are
# set::
#
#   <prefix>_VERSION_MAJOR  - <major>
#   <prefix>_VERSION_MINOR  - <minor>
#   <prefix>_VERSION_PATCH  - <patch>
#   <prefix>_VERSION        - <version>
#   <prefix>_VERSION_STRING - <version> (for compatibility: use <prefix>_VERSION instead)
#   <prefix>_SOVERSION      - <soversion>, or <major> if SOVERSION was not given
#
# If CMake policy CMP0048 is not NEW, the following CMake variables will also
# be set:
#
#   PROJECT_VERSION_MAJOR   - <major>
#   PROJECT_VERSION_MINOR   - <minor>
#   PROJECT_VERSION_PATCH   - <patch>
#   PROJECT_VERSION         - <version>
#   PROJECT_VERSION_STRING  - <version> (for compatibility: use PROJECT_VERSION instead)
#
# If the VERSION_HEADER option is used, a simple C header is generated with the
# given filename. If filename is a relative path, it is interpreted as relative
# to CMAKE_CURRENT_BINARY_DIR.  The generated header contains the following
# macros::
#
#    <prefix>_VERSION_MAJOR  - <major> as an integer
#    <prefix>_VERSION_MINOR  - <minor> as an integer
#    <prefix>_VERSION_PATCH  - <patch> as an integer
#    <prefix>_VERSION_STRING - <version> as a C string
#    <prefix>_VERSION        - the version as an integer
#
# ``<prefix>_VERSION`` has ``<patch>`` in the bottom 8 bits, ``<minor>`` in the
# next 8 bits and ``<major>`` in the remaining bits.  Note that ``<patch>`` and
# ``<minor>`` must be less than 256.
#
# If the PACKAGE_VERSION_FILE option is used, a simple CMake package version
# file is created using the write_basic_package_version_file() macro provided by
# CMake. It should be installed in the same location as the Config.cmake file of
# the library so that it can be found by find_package().  If the filename is a
# relative path, it is interpreted as relative to CMAKE_CURRENT_BINARY_DIR.
#
# The optional COMPATIBILITY option is similar to that accepted by
# write_basic_package_version_file(), except that it defaults to
# AnyNewerVersion if it is omitted, and it also accepts
# ``SameMajorVersionWithPrereleases`` as a value, in which case the
# ``FIRST_PRERELEASE_VERSION`` option must also be given. This versioning
# system behaves like SameMajorVersion, except that it treats all x.y releases,
# where y is at least ``<prerelease_version>``, as (x+1) releases. So if
# ``<prerelease_version>`` is 90, a request for version 2.90.0 will be satisfied
# by 3.1.0, while a request for 2.89.0 will not be. Note that in this scenario,
# version 2.90.0 of the software will not satisfy requests for version 2, version
# version 2.1.1 *or* version 3 of the software, as prereleases are not considered
# unless explicitly requested.
#
# If CMake policy CMP0048 is NEW, an alternative form of the command is
# available::
#
#   ecm_setup_version(PROJECT
#                     [VARIABLE_PREFIX <prefix>]
#                     [SOVERSION <soversion>]
#                     [VERSION_HEADER <filename>]
#                     [PACKAGE_VERSION_FILE <filename>] )
#
# This will use the version information set by the project() command.
# VARIABLE_PREFIX defaults to the project name.  Note that PROJECT must be the
# first argument.  In all other respects, it behaves like the other form of the
# command.
#

#=============================================================================
# Copyright 2014 Alex Merry <alex.merry@kde.org>
# Copyright 2012 Alexander Neundorf <neundorf@kde.org>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file COPYING-CMAKE-SCRIPTS for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of extra-cmake-modules, substitute the full
#  License text for the above reference.)

include(CMakePackageConfigHelpers)

# save the location of the header template while CMAKE_CURRENT_LIST_DIR
# has the value we want
set(_ECM_SETUP_VERSION_HEADER_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/ECMVersionHeader.h.in")
set(_ECM_PACKAGE_VERSION_TEMPLATE_DIR "${CMAKE_CURRENT_LIST_DIR}")

# like write_basic_package_version_file from CMake, but
# looks for our template files as well
function(ecm_write_package_version_file _filename)
  set(options )
  set(oneValueArgs VERSION COMPATIBILITY FIRST_PRERELEASE_VERSION)
  set(multiValueArgs )

  cmake_parse_arguments(CVF "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(CVF_UNPARSED_ARGUMENTS)
      message(FATAL_ERROR "Unknown keywords given to ecm_write_basic_package_version_file(): \"${CVF_UNPARSED_ARGUMENTS}\"")
  endif()

  set(versionTemplateFile "${_ECM_PACKAGE_VERSION_TEMPLATE_DIR}/BasicConfigVersion-${CVF_COMPATIBILITY}.cmake.in")
  if(NOT EXISTS "${versionTemplateFile}")
      write_basic_package_version_file("${_filename}" VERSION "${CVF_VERSION}" COMPATIBILITY "${CVF_COMPATIBILITY}")
      return()
  endif()

  if("${CVF_COMPATIBILITY}" STREQUAL "SameMajorVersionWithPrereleases")
      if("${CVF_FIRST_PRERELEASE_VERSION}" STREQUAL "")
          message(FATAL_ERROR "No FIRST_PRERELEASE_VERSION specified for ecm_write_basic_package_version_file()")
      endif()
  endif()

  if("${CVF_VERSION}" STREQUAL "")
      if ("${PROJECT_VERSION}" STREQUAL "")
          message(FATAL_ERROR "No VERSION specified for ecm_write_basic_package_version_file()")
      else()
          set(CVF_VERSION "${PROJECT_VERSION}")
      endif()
  endif()

  configure_file("${versionTemplateFile}" "${_filename}" @ONLY)
endfunction()

function(ecm_setup_version _version)
    set(options )
    set(oneValueArgs VARIABLE_PREFIX SOVERSION VERSION_HEADER PACKAGE_VERSION_FILE COMPATIBILITY FIRST_PRERELEASE_VERSION)
    set(multiValueArgs )

    cmake_parse_arguments(ESV "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})

    if(ESV_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown keywords given to ECM_SETUP_VERSION(): \"${ESV_UNPARSED_ARGUMENTS}\"")
    endif()

    set(project_manages_version FALSE)
    set(use_project_version FALSE)
    # CMP0048 only exists in CMake 3.0.0 and later
    if(CMAKE_VERSION VERSION_LESS 3.0.0)
        set(project_version_policy "OLD")
    else()
        cmake_policy(GET CMP0048 project_version_policy)
    endif()
    if(project_version_policy STREQUAL "NEW")
        set(project_manages_version TRUE)
        if(_version STREQUAL "PROJECT")
            set(use_project_version TRUE)
        endif()
    elseif(_version STREQUAL "PROJECT")
        message(FATAL_ERROR "ecm_setup_version given PROJECT argument, but CMP0048 is not NEW")
    endif()

    set(should_set_prefixed_vars TRUE)
    if(NOT ESV_VARIABLE_PREFIX)
        if(use_project_version)
            set(ESV_VARIABLE_PREFIX "${PROJECT_NAME}")
            set(should_set_prefixed_vars FALSE)
        else()
            message(FATAL_ERROR "Required argument PREFIX missing in ECM_SETUP_VERSION() call")
        endif()
    endif()

    if(use_project_version)
        set(_version "${PROJECT_VERSION}")
        set(_major "${PROJECT_VERSION_MAJOR}")
        set(_minor "${PROJECT_VERSION_MINOR}")
        set(_patch "${PROJECT_VERSION_PATCH}")
    else()
        string(REGEX REPLACE "^([0-9]+)\\.[0-9]+\\.[0-9]+.*" "\\1" _major "${_version}")
        string(REGEX REPLACE "^[0-9]+\\.([0-9]+)\\.[0-9]+.*" "\\1" _minor "${_version}")
        string(REGEX REPLACE "^[0-9]+\\.[0-9]+\\.([0-9]+).*" "\\1" _patch "${_version}")
    endif()

    if(NOT ESV_SOVERSION)
        set(ESV_SOVERSION ${_major})
    endif()

    if(should_set_prefixed_vars)
        set(${ESV_VARIABLE_PREFIX}_VERSION "${_version}")
        set(${ESV_VARIABLE_PREFIX}_VERSION_MAJOR ${_major})
        set(${ESV_VARIABLE_PREFIX}_VERSION_MINOR ${_minor})
        set(${ESV_VARIABLE_PREFIX}_VERSION_PATCH ${_patch})
    endif()

    set(${ESV_VARIABLE_PREFIX}_SOVERSION ${ESV_SOVERSION})

    if(NOT project_manages_version)
        set(PROJECT_VERSION "${_version}")
        set(PROJECT_VERSION_MAJOR "${_major}")
        set(PROJECT_VERSION_MINOR "${_minor}")
        set(PROJECT_VERSION_PATCH "${_patch}")
    endif()

    # compat
    set(PROJECT_VERSION_STRING "${PROJECT_VERSION}")
    set(${ESV_VARIABLE_PREFIX}_VERSION_STRING "${${ESV_VARIABLE_PREFIX}_VERSION}")

    if(ESV_VERSION_HEADER)
        set(HEADER_PREFIX "${ESV_VARIABLE_PREFIX}")
        set(HEADER_VERSION "${_version}")
        set(HEADER_VERSION_MAJOR "${_major}")
        set(HEADER_VERSION_MINOR "${_minor}")
        set(HEADER_VERSION_PATCH "${_patch}")
        configure_file("${_ECM_SETUP_VERSION_HEADER_TEMPLATE}" "${ESV_VERSION_HEADER}")
    endif()

    if(ESV_PACKAGE_VERSION_FILE)
        if(NOT ESV_COMPATIBILITY)
            set(ESV_COMPATIBILITY AnyNewerVersion)
        endif()
        ecm_write_package_version_file("${ESV_PACKAGE_VERSION_FILE}"
            VERSION ${_version}
            COMPATIBILITY ${ESV_COMPATIBILITY}
            FIRST_PRERELEASE_VERSION "${ESV_FIRST_PRERELEASE_VERSION}"
            )
    endif()

    if(should_set_prefixed_vars)
        set(${ESV_VARIABLE_PREFIX}_VERSION_MAJOR "${${ESV_VARIABLE_PREFIX}_VERSION_MAJOR}" PARENT_SCOPE)
        set(${ESV_VARIABLE_PREFIX}_VERSION_MINOR "${${ESV_VARIABLE_PREFIX}_VERSION_MINOR}" PARENT_SCOPE)
        set(${ESV_VARIABLE_PREFIX}_VERSION_PATCH "${${ESV_VARIABLE_PREFIX}_VERSION_PATCH}" PARENT_SCOPE)
        set(${ESV_VARIABLE_PREFIX}_VERSION       "${${ESV_VARIABLE_PREFIX}_VERSION}"       PARENT_SCOPE)
    endif()

    # always set the soversion
    set(${ESV_VARIABLE_PREFIX}_SOVERSION "${${ESV_VARIABLE_PREFIX}_SOVERSION}" PARENT_SCOPE)

    if(NOT project_manages_version)
        set(PROJECT_VERSION       "${PROJECT_VERSION}"       PARENT_SCOPE)
        set(PROJECT_VERSION_MAJOR "${PROJECT_VERSION_MAJOR}" PARENT_SCOPE)
        set(PROJECT_VERSION_MINOR "${PROJECT_VERSION_MINOR}" PARENT_SCOPE)
        set(PROJECT_VERSION_PATCH "${PROJECT_VERSION_PATCH}" PARENT_SCOPE)
    endif()

    # always set the compatibility variables
    set(PROJECT_VERSION_STRING "${PROJECT_VERSION_STRING}" PARENT_SCOPE)
    set(${ESV_VARIABLE_PREFIX}_VERSION_STRING "${${ESV_VARIABLE_PREFIX}_VERSION}" PARENT_SCOPE)

endfunction()
