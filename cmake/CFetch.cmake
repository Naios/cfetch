# Copyright(c) 2020 - 2022 Denis Blank <denis.blank at outlook dot com>
#
# MIT License:
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

include(GNUInstallDirs)

function(cfetch_archive_extract EXTRACT_SOURCE_DIR EXTRACT_DEST_DIR)
  set(arg_opt)
  set(arg_single INTO URL SHA512)
  set(arg_multi FILTER)
  cmake_parse_arguments(CFETCH_ARCHIVE_EXTRACT "${arg_opt}" "${arg_single}"
                        "${arg_multi}" ${ARGN})

  message(STATUS "CFetch: Extracting '${EXTRACT_SOURCE_DIR}'\n"
                 "        to '${EXTRACT_DEST_DIR}'...")

  foreach(FILTER_ENTRY IN LISTS CFETCH_ARCHIVE_EXTRACT_FILTER)
    message(STATUS "         * '${FILTER_ENTRY}'")
  endforeach()

  file(MAKE_DIRECTORY "${EXTRACT_DEST_DIR}")

  if(CMAKE_VERSION VERSION_LESS 3.18)
    execute_process(
      COMMAND "${CMAKE_COMMAND}" -E tar xzf "${EXTRACT_SOURCE_DIR}"
              ${CFETCH_ARCHIVE_EXTRACT_FILTER}
      WORKING_DIRECTORY "${EXTRACT_DEST_DIR}"
      RESULT_VARIABLE PROCESS_RESULT)

    if(NOT PROCESS_RESULT EQUAL 0)
      message(FATAL_ERROR "Extraction of '${EXTRACT_SOURCE_DIR}' has failed! "
                          "See the log for details.")
    endif()
  else()
    file(
      ARCHIVE_EXTRACT
      INPUT
      "${EXTRACT_SOURCE_DIR}"
      DESTINATION
      "${EXTRACT_DEST_DIR}"
      PATTERNS
      ${CFETCH_ARCHIVE_EXTRACT_FILTER})
  endif()
endfunction()

function(_cfetch_verify_checksum FILE_LOCATION ORIGIN SHA512_CHECKSUM)
  if(NOT SHA512_CHECKSUM STREQUAL "")
    file(SHA512 "${FILE_LOCATION}" FILE_CHECKSUM)
    if(FILE_CHECKSUM STREQUAL SHA512_CHECKSUM)
      message(STATUS "CFetch: Verified SHA512 of '${FILE_LOCATION}'")
    else()
      message(
        FATAL_ERROR
          "CFetch: Failed to verify SHA512 checksum of '${FILE_LOCATION}'!\n" #
          "  expected: '${SHA512_CHECKSUM}'\n" #
          "   but was: '${FILE_CHECKSUM}'")
    endif()

  else(NOT CFETCH_NO_MISSING_CHECKSUM_WARNING)
    # ^ If you really like to disable this, or use 'cmake -Wno-dev'

    # TODO Re-enable this
    #[[
    message(
      AUTHOR_WARNING
        "No SHA512 checksum present to verify\n" #
        "  file '${FILE_LOCATION}'\n" #
        "  from '${ORIGIN}'\n" #
        "  I will continue without it but consider adding one for integrity reasons!")
        ]]
  endif()
endfunction()

function(cfetch_download DOWNLOAD_URL DOWNLOAD_LOCATION)
  set(arg_opt)
  set(arg_single SHA512)
  cmake_parse_arguments(CFETCH_DOWNLOAD "${arg_opt}" "${arg_single}" "" ${ARGN})

  if(NOT EXISTS "${DOWNLOAD_LOCATION}")
    set(TEMP_DOWNLOAD_LOCATION "${DOWNLOAD_LOCATION}.tmp")
    if(EXISTS "${TEMP_DOWNLOAD_LOCATION}")
      file(REMOVE "${TEMP_DOWNLOAD_LOCATION}")
    endif()

    message(STATUS "CFetch: Downloading '${DOWNLOAD_URL}'\n"
                   "         to '${DOWNLOAD_LOCATION}'...")

    file(
      DOWNLOAD "${DOWNLOAD_URL}" "${TEMP_DOWNLOAD_LOCATION}"
      SHOW_PROGRESS
      STATUS PACKAGE_FETCH_RESULT)

    list(GET PACKAGE_FETCH_RESULT 0 PACKAGE_FETCH_STATUS_CODE)
    if(NOT PACKAGE_FETCH_STATUS_CODE EQUAL 0)
      message(
        FATAL_ERROR
          "Failed to download '${DOWNLOAD_URL}' to '${DOWNLOAD_LOCATION}'!")
    endif()

    _cfetch_verify_checksum("${TEMP_DOWNLOAD_LOCATION}" "${DOWNLOAD_URL}"
                            "${CFETCH_DOWNLOAD_SHA512}")

    file(RENAME "${TEMP_DOWNLOAD_LOCATION}" "${DOWNLOAD_LOCATION}")
  else()
    _cfetch_verify_checksum("${DOWNLOAD_LOCATION}" "${DOWNLOAD_URL}"
                            "${CFETCH_DOWNLOAD_SHA512}")
  endif()
endfunction()

function(cfetch_package_cache_dir OUT_CACHE_DIR)
  if(CFETCH_PACKAGE_CACHE)
    set(${OUT_CACHE_DIR}
        "${CFETCH_PACKAGE_CACHE}"
        PARENT_SCOPE)
  elseif(NOT "$ENV{CFETCH_PACKAGE_CACHE}" STREQUAL "")
    file(TO_CMAKE_PATH "$ENV{CFETCH_PACKAGE_CACHE}"
         CFETCH_PACKAGE_CACHE_NORMALIZED)

    set(${OUT_CACHE_DIR}
        "${CFETCH_PACKAGE_CACHE_NORMALIZED}"
        PARENT_SCOPE)
  else()
    set(${OUT_CACHE_DIR}
        "${CMAKE_BINARY_DIR}/cfetch"
        PARENT_SCOPE)
  endif()
endfunction()

function(cfetch_license_install_dir OUT_CACHE_DIR)
  set(${OUT_CACHE_DIR}
      "doc/license"
      PARENT_SCOPE)
endfunction()

function(_cfetch_package_download_url OUT_PACKAGE_URL PACKAGE_USER PACKAGE_NAME
         PACKAGE_VERSION)
  set(${OUT_PACKAGE_URL}
      "https://github.com/${PACKAGE_USER}/${PACKAGE_NAME}/archive/${PACKAGE_VERSION}.zip"
      PARENT_SCOPE)
endfunction()

function(cfetch_package_info PACKAGE OUT_USER OUT_NAME OUT_VERSION)
  string(REGEX MATCHALL
               "(^[A-Za-z0-9_-]+)|(/[A-Za-z0-9_-]+)|(@[A-Za-z0-9_.-]+$)"
               MATCHED "${PACKAGE}")

  list(LENGTH MATCHED MATCHED_SIZE)

  list(GET MATCHED 0 PARSED_USER)
  list(GET MATCHED 1 PARSED_NAME)
  string(SUBSTRING "${PARSED_NAME}" 1 -1 PARSED_NAME)

  if(${MATCHED_SIZE} GREATER_EQUAL 3)
    list(GET MATCHED 2 PARSED_VERSION)
    string(SUBSTRING "${PARSED_VERSION}" 1 -1 PARSED_VERSION)
  else()
    set(PARSED_VERSION)
  endif()

  set(${OUT_USER}
      "${PARSED_USER}"
      PARENT_SCOPE)
  set(${OUT_NAME}
      "${PARSED_NAME}"
      PARENT_SCOPE)
  set(${OUT_VERSION}
      "${PARSED_VERSION}"
      PARENT_SCOPE)
endfunction()

# The patch file can be created through something like: 'diff -c . ../other >
# ../mydiff.patch'
function(_cfetch_apply_patch WORKING_DIRECTORY PATCH_FILE)
  if(NOT Patch_EXECUTABLE)
    find_package(Patch REQUIRED)
  endif()

  message(STATUS "CFetch: Patching '${WORKING_DIRECTORY}'\n"
                 "    with '${PATCH_FILE}'...")

  execute_process(
    COMMAND "${Patch_EXECUTABLE}" "-p1" "-i" "${PATCH_FILE}"
    WORKING_DIRECTORY "${WORKING_DIRECTORY}"
    RESULT_VARIABLE PATCH_RESULT)

  if(NOT PATCH_RESULT EQUAL 0)
    message(
      FATAL_ERROR
        "Patching of '${WORKING_DIRECTORY}' has failed! "
        "  With command: ${Patch_EXECUTABLE} -p1 -i ${PATCH_FILE} "
        "  See the log for details.")
  endif()
endfunction()

function(_cfetch_remove_directory DIR)
  if(EXISTS "${DIR}")
    if(IS_DIRECTORY "${DIR}")
      message(STATUS "CFetch: Removing directory '${DIR}'")
      file(REMOVE_RECURSE "${DIR}")
    endif()
  endif()
endfunction()

function(_cfetch_write_protect_directory PROTECT_DIRECTORY)
  if(NOT IS_DIRECTORY "${PROTECT_DIRECTORY}")
    message(FATAL_ERROR "Something went wrong here, while trying to "
                        "write protect path '${PROTECT_DIRECTORY}'!")
  endif()

  message(STATUS "CFetch: Write protecting directory '${PROTECT_DIRECTORY}'")

  if(WIN32)
    execute_process(
      COMMAND "attrib" "+R" "/L" "/S" "/D"
      WORKING_DIRECTORY "${PROTECT_DIRECTORY}"
      RESULT_VARIABLE WRITE_PROTECT_RESULT)
  else()
    message("TODO: Implement write protection for this platform")
    set(WRITE_PROTECT_RESULT 0)
  endif()

  if(NOT WRITE_PROTECT_RESULT EQUAL 0)
    message(
      FATAL_ERROR "Write protecting of '${PROTECT_DIRECTORY}' has failed! "
                  "See the log for details.")
  endif()
endfunction()

function(_cfetch_directory_commit FROM TO)
  # Protect the directory against unintended file changes
  _cfetch_write_protect_directory("${FROM}")

  # Commit the prepared archive to the registry
  message(STATUS "CFetch: Committing directory '${TO}' to registry")

  if(NOT EXISTS "${TO}")
    file(RENAME "${FROM}" "${TO}")
  else()
    message(
      FATAL_ERROR
        "Ups, did multiple processes write to the "
        "same registry concurrently? Directory '${TO}' " "should not exist!")
  endif()
endfunction()

function(_cfetch_package_pull_ex PACKAGE_USER PACKAGE_NAME PACKAGE_VERSION)
  set(arg_opt NO_LICENSE_FILE)
  set(arg_single INTO URL SHA512 LICENSE_FILE BASE_DIR ARCHIVE_EXTENSION)
  set(arg_multi FILTER RENAME PATCH)
  cmake_parse_arguments(CFETCH_PACKAGE_PULL "${arg_opt}" "${arg_single}"
                        "${arg_multi}" ${ARGN})

  cfetch_package_cache_dir(PACKAGE_CACHE_DIR)

  # Setup a default github assets pull URL
  if(NOT CFETCH_PACKAGE_PULL_URL)
    _cfetch_package_download_url(CFETCH_PACKAGE_PULL_URL "${PACKAGE_USER}"
                                 "${PACKAGE_NAME}" "${PACKAGE_VERSION}")
  endif()
  string(SHA1 CFETCH_PACKAGE_PULL_URL_SHA1 "${CFETCH_PACKAGE_PULL_URL}")

  if(NOT CFETCH_PACKAGE_PULL_ARCHIVE_EXTENSION)
    get_filename_component(CFETCH_PACKAGE_PULL_ARCHIVE_EXTENSION
                           "${CFETCH_PACKAGE_PULL_URL}" LAST_EXT)
  endif()

  # Setup the default github zip archive basedir (archive root dir)
  if(NOT DEFINED CFETCH_PACKAGE_PULL_BASE_DIR)
    set(CFETCH_PACKAGE_PULL_BASE_DIR "${PACKAGE_NAME}-${PACKAGE_VERSION}")
  endif()

  set(PATCH_CHECKSUMS)
  foreach(PATCH_ENTRY IN LISTS CFETCH_PACKAGE_PULL_PATCH)
    if(NOT EXISTS "${PATCH_ENTRY}")
      message(FATAL_ERROR "Patch file ${PATCH_ENTRY} does not exist!")
    endif()

    file(MD5 "${PATCH_ENTRY}" PATCH_ENTRY_CHECKSUMS)
    list(APPEND PATCH_CHECKSUMS "${PATCH_ENTRY_CHECKSUMS}")
  endforeach()

  string(
    SHA1 PACKAGE_LOCATION_HASH
         "${CFETCH_PACKAGE_PULL_URL}${CFETCH_PACKAGE_PULL_BASE_DIR}/${CFETCH_PACKAGE_PULL_FILTER}${CFETCH_PACKAGE_PULL_LICENSE_FILE}${CFETCH_PACKAGE_PULL_RENAME}"
  )

  # Build the hash here which contains all unique operations allpied to the
  # extracted archive
  string(
    SHA1 PACKAGE_LOCATION_HASH
         "${CFETCH_PACKAGE_PULL_URL}${CFETCH_PACKAGE_PULL_BASE_DIR}/${CFETCH_PACKAGE_PULL_FILTER}${CFETCH_PACKAGE_PULL_LICENSE_FILE}${CFETCH_PACKAGE_PULL_RENAME}${PATCH_CHECKSUMS}"
  )

  set(PACKAGE_ROOT_LOCATION
      "${PACKAGE_CACHE_DIR}/packages/${PACKAGE_LOCATION_HASH}")
  set(PACKAGE_LOCATION "${PACKAGE_ROOT_LOCATION}/${PACKAGE_NAME}")
  if(NOT EXISTS "${PACKAGE_LOCATION}")
    # Download the package
    if(NOT CFETCH_PACKAGE_PULL_URL)
      _cfetch_package_download_url(CFETCH_PACKAGE_PULL_URL "${PACKAGE_USER}"
                                   "${PACKAGE_NAME}" "${PACKAGE_VERSION}")
    endif()

    set(PACKAGE_DOWNLOAD_FILENAME
        "${CFETCH_PACKAGE_PULL_URL_SHA1}${CFETCH_PACKAGE_PULL_ARCHIVE_EXTENSION}"
    )
    set(PACKAGE_DOWNLOAD_LOCATION
        "${PACKAGE_CACHE_DIR}/downloads/${PACKAGE_DOWNLOAD_FILENAME}")
    if(EXISTS "${PACKAGE_DOWNLOAD_LOCATION}")
      _cfetch_verify_checksum(
        "${PACKAGE_DOWNLOAD_LOCATION}" "${CFETCH_PACKAGE_PULL_URL}"
        "${CFETCH_PACKAGE_PULL_SHA512}")
    else()
      cfetch_download(
        "${CFETCH_PACKAGE_PULL_URL}" "${PACKAGE_DOWNLOAD_LOCATION}" SHA512
        "${CFETCH_PACKAGE_PULL_SHA512}")
    endif()

    if(CFETCH_PACKAGE_PULL_FILTER)
      set(ARCHIVE_FILTER)

      if(CFETCH_PACKAGE_PULL_BASE_DIR)
        foreach(ARCHIVE_PATTERN IN LISTS CFETCH_PACKAGE_PULL_FILTER
                                         CFETCH_PACKAGE_PULL_LICENSE_FILE)
          list(APPEND ARCHIVE_FILTER
               "${CFETCH_PACKAGE_PULL_BASE_DIR}/${ARCHIVE_PATTERN}")
        endforeach()
      else()
        list(APPEND ARCHIVE_FILTER ${CFETCH_PACKAGE_PULL_FILTER}
             ${CFETCH_PACKAGE_PULL_LICENSE_FILE})
      endif()
    endif()

    set(TEMP_ROOT_LOCATION
        "${PACKAGE_CACHE_DIR}/packages/tmp_${PACKAGE_LOCATION_HASH}")
    set(TEMP_LOCATION "${TEMP_ROOT_LOCATION}/${CFETCH_PACKAGE_PULL_BASE_DIR}")

    # Setup a temporary extraction location, delete it if it exists.
    if(EXISTS "${TEMP_ROOT_LOCATION}")
      # This indicates that the previous registry transaction has failed.
      file(REMOVE_RECURSE "${TEMP_ROOT_LOCATION}")
    endif()

    # Extract the package
    cfetch_archive_extract("${PACKAGE_DOWNLOAD_LOCATION}"
                           "${TEMP_ROOT_LOCATION}" FILTER ${ARCHIVE_FILTER})

    if(NOT EXISTS "${TEMP_LOCATION}")
      message(
        FATAL_ERROR
          "Archive base directory '${TEMP_LOCATION}' doesn't exist! Make sure "
          "to specify the base directory by specifying BASE_DIR!")
    endif()

    if(CFETCH_PACKAGE_PULL_RENAME)
      foreach(RENAME_ENTRY IN LISTS CFETCH_PACKAGE_PULL_RENAME)
        string(REPLACE "=" ";" RENAME_ENTRY ${RENAME_ENTRY})
        list(GET RENAME_ENTRY 0 RENAME_FROM)
        set(RENAME_FROM "${TEMP_LOCATION}/${RENAME_FROM}")

        list(GET RENAME_ENTRY 1 RENAME_TO)
        set(RENAME_TO "${TEMP_LOCATION}/${RENAME_TO}")

        get_filename_component(RENAME_TO_DIR "${RENAME_TO}" DIRECTORY)
        if(RENAME_TO_DIR AND NOT EXISTS "${RENAME_TO_DIR}")
          message(STATUS "CFetch: Creating directory '${RENAME_TO_DIR}'")
          file(MAKE_DIRECTORY "${RENAME_TO_DIR}")
        endif()

        message(STATUS "CFetch: Renaming file '${RENAME_FROM}'\n"
                       "           to '${RENAME_TO}'")
        file(RENAME "${RENAME_FROM}" "${RENAME_TO}")
      endforeach()
    endif()

    if(CFETCH_PACKAGE_PULL_PATCH)
      foreach(PATCH_ENTRY IN LISTS CFETCH_PACKAGE_PULL_PATCH)
        _cfetch_apply_patch("${TEMP_LOCATION}" "${PATCH_ENTRY}")
      endforeach()
    endif()

    if(NOT CFETCH_PACKAGE_PULL_BASE_DIR STREQUAL PACKAGE_NAME)
      message(STATUS "CFetch: Renaming archive base directory\n"
                     "        from '${TEMP_LOCATION}'\n"
                     "        to   '${TEMP_ROOT_LOCATION}/${PACKAGE_NAME}'")

      file(RENAME "${TEMP_LOCATION}" "${TEMP_ROOT_LOCATION}/${PACKAGE_NAME}")
    endif()

    _cfetch_directory_commit("${TEMP_ROOT_LOCATION}" "${PACKAGE_ROOT_LOCATION}")
  endif()

  if(CFETCH_PACKAGE_PULL_LICENSE_FILE)
    string(TOLOWER "${PACKAGE_NAME}" LICENSE_FILE_NAME)

    cfetch_license_install_dir(CFETCH_LICENSE_INSTALL_DIR)

    install(
      FILES "${PACKAGE_LOCATION}/${CFETCH_PACKAGE_PULL_LICENSE_FILE}"
      DESTINATION "${CFETCH_LICENSE_INSTALL_DIR}"
      RENAME "license-${LICENSE_FILE_NAME}.txt")
  elseif(NOT CFETCH_PACKAGE_PULL_NO_LICENSE_FILE)
    message(
      AUTHOR_WARNING
        "'${PACKAGE}' has no license file specified! "
        "Use cfetch_package_pull(... \"LICENSE_FILE LICENSE_FILE.txt\")!")
  endif()

  # Set the result variable
  if(CFETCH_PACKAGE_PULL_INTO)
    set(${CFETCH_PACKAGE_PULL_INTO}
        ${PACKAGE_LOCATION}
        PARENT_SCOPE)
  endif()
endfunction()

macro(cfetch_package_pull PACKAGE)
  cfetch_package_info("${PACKAGE}" PACKAGE_USER PACKAGE_NAME PACKAGE_VERSION)

  _cfetch_package_pull_ex("${PACKAGE_USER}" "${PACKAGE_NAME}"
                          "${PACKAGE_VERSION}" ${ARGN})
endmacro()

macro(cfetch_enable_packages)
  if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/dep")
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/dep")

    if(NOT PACKAGE_CACHE_DIR)
      cfetch_package_cache_dir(PACKAGE_CACHE_DIR)

      if((NOT DEFINED CFETCH_PACKAGE_CACHE) AND ("$ENV{CFETCH_PACKAGE_CACHE}"
                                                 STREQUAL ""))
        message(
          "I will use the build dir as cache directory for dependencies.\n"
          " - Enable a cross project build cache by defining CFETCH_PACKAGE_CACHE "
          "as environment variable or CMake variable!")

        if(WIN32)
          message(
            " - 'C:/Users/$ENV{USERNAME}/AppData/Local/cfetch/cache' is recommended!"
          )
        else()
          message(" - '~/.cfetch/cache' is recommended!")
        endif()
      else()
        message(
          STATUS "CFetch: Using '${PACKAGE_CACHE_DIR}' as package cache dir")
      endif()
    endif()
  endif()
endmacro()

function(cfetch_target_name TARGET_NAMESPACE_NAME OUT_VAR)
  string(REPLACE "::" ";" TARGET_NAMESPACE_NAME "${TARGET_NAMESPACE_NAME}")
  list(REVERSE TARGET_NAMESPACE_NAME)
  list(GET TARGET_NAMESPACE_NAME 0 TARGET_NAMESPACE_NAME)
  set(${OUT_VAR}
      "${TARGET_NAMESPACE_NAME}"
      PARENT_SCOPE)
endfunction()

function(cfetch_target_namespace TARGET_NAMESPACE_NAME OUT_VAR)
  string(REPLACE "::" ";" TARGET_NAMESPACE_NAME "${TARGET_NAMESPACE_NAME}")
  list(LENGTH TARGET_NAMESPACE_NAME TARGET_NAMESPACE_NAME_LENGTH)

  if(TARGET_NAMESPACE_NAME_LENGTH GREATER 1)
    list(GET TARGET_NAMESPACE_NAME 0 TARGET_NAMESPACE_NAME)
    set(${OUT_VAR}
        "${TARGET_NAMESPACE_NAME}::"
        PARENT_SCOPE)
  else()
    set(${OUT_VAR}
        ""
        PARENT_SCOPE)
  endif()
endfunction()

function(cfetch_find_link_libraries TARGET)
  get_property(
    LINK_LIBRARIES_SET
    TARGET "${TARGET}"
    PROPERTY INTERFACE_LINK_LIBRARIES
    SET)

  if(NOT LINK_LIBRARIES_SET)
    return()
  endif()

  get_target_property(LINK_LIBRARIES "${TARGET}" INTERFACE_LINK_LIBRARIES)

  foreach(LINK_LIBRARY IN LISTS LINK_LIBRARIES)
    if(TARGET ${LINK_LIBRARY})
      continue()
    endif()

    cfetch_target_name("${LINK_LIBRARY}" LINK_LIBRARY_NAME)
    find_package(${LINK_LIBRARY_NAME} REQUIRED)
    cfetch_find_link_libraries(${LINK_LIBRARY})
  endforeach()
endfunction()

function(_cfetch_check_dependency_version LIBRARY_NAME PACKAGE_VERSION
         FIND_VERSION PIN_VERSION)

  if((NOT PACKAGE_VERSION) AND (NOT FIND_VERSION))
    message(
      FATAL_ERROR
        "You didn't specify any find version for 'find_package(${LIBRARY_NAME} ...)'! "
        "Make sure to provide either a pinned version in 'cfetch_dependency(\"${PACKAGE}\" \"<version>\")' or "
        "use find_package with an explicit requested version: 'find_package(${LIBRARY_NAME} 1.0.0)'. "
        "For version strings incompatible with CMake you can define the ${LIBRARY_NAME}_FIND_VERSION variable "
        "before calling 'find_package(${LIBRARY_NAME} ...)' such as 'set(${LIBRARY_NAME}_FIND_VERSION \"<version>\")'."
    )
  endif()

  if(FIND_VERSION AND PIN_VERSION)
    if(PACKAGE_VERSION AND (NOT PACKAGE_VERSION VERSION_EQUAL FIND_VERSION))
      message(
        FATAL_ERROR
          "Required a version for find_package(${LIBRARY_NAME} ${FIND_VERSION}), "
          "that is not compatible with the pinned cfetch_dependency(\"${PACKAGE}\") version!"
      )
    endif()
  endif()
endfunction()

function(_cfetch_install_shared_library_target TARGET)
  if(TARGET "${TARGET}")
    get_target_property(TARGET_TYPE ${TARGET} TYPE)
    if(TARGET_TYPE STREQUAL SHARED_LIBRARY)
      install(FILES "$<TARGET_FILE:${TARGET}>"
              DESTINATION "${CMAKE_INSTALL_PREFIX}")
    endif()
  endif()
endfunction()

function(_cfetch_dependency_ex PACKAGE)
  set(arg_opt NO_LICENSE_FILE EXTERNAL NO_FIND_PACKAGE DRY_RUN PIN_VERSION)
  set(arg_single
      CD
      AS
      LICENSE_FILE
      SUBDIRECTORY
      URL
      SHA512
      BASE_DIR)
  set(arg_multi
      OPTIONS
      FILTER
      PATCH
      RENAME
      INSTALL_RUNTIME
      CONFIGURATIONS
      TARGETS
      HINTS)
  cmake_parse_arguments(CFETCH_DEPENDENCY "${arg_opt}" "${arg_single}"
                        "${arg_multi}" ${ARGN})

  cfetch_package_info("${PACKAGE}" PACKAGE_USER PACKAGE_NAME PACKAGE_VERSION)

  if(CFETCH_DEPENDENCY_AS)
    set(LIBRARY_NAME ${CFETCH_DEPENDENCY_AS})
  else()
    set(LIBRARY_NAME ${PACKAGE_NAME})
  endif()

  if(TARGET ${LIBRARY_NAME})
    return()
  endif()

  cfetch_package_cache_dir(PACKAGE_CACHE_DIR)

  _cfetch_check_dependency_version(
    "${LIBRARY_NAME}" "${PACKAGE_VERSION}" "${${LIBRARY_NAME}_FIND_VERSION}"
    "${CFETCH_DEPENDENCY_PIN_VERSION}")

  if(${LIBRARY_NAME}_FIND_VERSION)
    set(PACKAGE_VERSION "${${LIBRARY_NAME}_FIND_VERSION}")
  endif()

  if(CFETCH_DEPENDENCY_NO_LICENSE_FILE)
    set(CFETCH_DEPENDENCY_NO_LICENSE_FILE NO_LICENSE_FILE)
  endif()

  _cfetch_package_pull_ex(
    "${PACKAGE_USER}"
    "${PACKAGE_NAME}"
    "${PACKAGE_VERSION}"
    INTO
    PACKAGE_LOCATION
    URL
    ${CFETCH_DEPENDENCY_URL}
    SHA512
    ${CFETCH_DEPENDENCY_SHA512}
    BASE_DIR
    ${CFETCH_DEPENDENCY_BASE_DIR}
    LICENSE_FILE
    ${CFETCH_DEPENDENCY_LICENSE_FILE}
    ${CFETCH_DEPENDENCY_NO_LICENSE_FILE}
    RENAME
    ${CFETCH_DEPENDENCY_RENAME}
    FILTER
    ${CFETCH_DEPENDENCY_FILTER}
    PATCH
    ${CFETCH_DEPENDENCY_PATCH})

  if(CFETCH_DEPENDENCY_CD)
    set(PACKAGE_WORKING_DIRECTORY "${PACKAGE_LOCATION}/${CFETCH_DEPENDENCY_CD}")
  else()
    set(PACKAGE_WORKING_DIRECTORY "${PACKAGE_LOCATION}")
  endif()

  if(CFETCH_DEPENDENCY_EXTERNAL)
    set(PACKAGE_COMMAND_LINE_ARGS)

    if(CMAKE_C_COMPILER)
      list(APPEND PACKAGE_COMMAND_LINE_ARGS
           "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}")
    endif()
    if(CMAKE_CXX_COMPILER)
      list(APPEND PACKAGE_COMMAND_LINE_ARGS
           "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}")
    endif()

    # get_property(IS_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

    # ALways use the default CMake generator for now
    if(WIN32 AND MSVC)
      set(IS_MULTI_CONFIG ON)
    else()
      set(IS_MULTI_CONFIG OFF)
    endif()

    if(IS_MULTI_CONFIG)
      if(CMAKE_CONFIGURATION_TYPES)
        set(CONFIGURATION_TYPES_LIST ${CMAKE_CONFIGURATION_TYPES})
      else()
        # non multi config generator -> multi config generator
        set(CONFIGURATION_TYPES_LIST "Debug;Release;MinSizeRel;RelWithDebInfo")
      endif()

      if(CFETCH_DEPENDENCY_CONFIGURATIONS)
        set(CURRENT_CONFIGURATION_TYPE)

        foreach(CURRENT_CONFIGURATION IN LISTS CONFIGURATION_TYPES_LIST)
          list(FIND CFETCH_DEPENDENCY_CONFIGURATIONS "${CURRENT_CONFIGURATION}"
               FIND_RESULT)

          if(NOT FIND_RESULT EQUAL -1)
            list(APPEND CURRENT_CONFIGURATION_TYPES "${CURRENT_CONFIGURATION}")
          endif()
        endforeach()
      else()
        set(CURRENT_CONFIGURATION_TYPES ${CMAKE_CONFIGURATION_TYPES})
      endif()
    else()
      list(APPEND PACKAGE_COMMAND_LINE_ARGS
           "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")

      set(CURRENT_CONFIGURATION_TYPES ${CMAKE_BUILD_TYPE})
    endif()

    if(NOT CURRENT_CONFIGURATION_TYPES)
      if(IS_MULTI_CONFIG)
        message(
          FATAL_ERROR
            "There are no configurations to build "
            "(GENERATOR_IS_MULTI_CONFIG=ON, "
            "CMAKE_CONFIGURATION_TYPES=${CMAKE_CONFIGURATION_TYPES}, "
            "CFETCH_DEPENDENCY_CONFIGURATIONS=${CFETCH_DEPENDENCY_CONFIGURATIONS})!"
        )
      else()
        message(
          FATAL_ERROR
            "There are no configurations to build (IS_MULTI_CONFIG=OFF)!")
      endif()
    endif()

    foreach(CURRENT_OPTION IN LISTS CFETCH_DEPENDENCY_OPTIONS)
      string(REPLACE "@" "\\;" CURRENT_OPTION "${CURRENT_OPTION}")
      list(APPEND PACKAGE_COMMAND_LINE_ARGS "-D${CURRENT_OPTION}")
    endforeach()

    string(
      SHA1 PACKAGE_COMMAND_LINE_ARGS_HASH
           "${PACKAGE_USER}@${PACKAGE_NAME}@${PACKAGE_VERSION}@${PACKAGE_COMMAND_LINE_ARGS}"
    )

    set(INSTALL_PACKAGE_LOCATION
        "${PACKAGE_CACHE_DIR}/installs/${PACKAGE_COMMAND_LINE_ARGS_HASH}")

    set(CFETCH_COMMIT_FILENAME COMMITTED)
    if(NOT EXISTS "${INSTALL_PACKAGE_LOCATION}/${CFETCH_COMMIT_FILENAME}")
      string(
        SHA1 BUILD_HASH
             "${PACKAGE_USER}@${PACKAGE_NAME}@${PACKAGE_VERSION}@${PACKAGE_COMMAND_LINE_ARGS}"
      )

      _cfetch_remove_directory("${INSTALL_PACKAGE_LOCATION}")

      set(BUILD_PACKAGE_LOCATION "${PACKAGE_CACHE_DIR}/build/${BUILD_HASH}")

      file(MAKE_DIRECTORY "${BUILD_PACKAGE_LOCATION}")

      # Unhashed args:
      if(CMAKE_MODULE_PATH)
        string(REPLACE ";" "\\;" CURRENT_MODULE_PATH "${CMAKE_MODULE_PATH}")

        list(APPEND PACKAGE_COMMAND_LINE_ARGS
             "-DCMAKE_MODULE_PATH=${CURRENT_MODULE_PATH}")
      endif()

      message(STATUS "CFetch: Building ${PACKAGE}\n"
                     "     into '${BUILD_PACKAGE_LOCATION}'...")
      foreach(CURRENT_ARG IN LISTS PACKAGE_COMMAND_LINE_ARGS)
        message(STATUS "CFetch:      with: ${CURRENT_ARG}")
      endforeach()

      if(CFETCH_DEPENDENCY_DRY_RUN)
        message(FATAL_ERROR "Skipping CMake invocation (dry run)")
        return()
      endif()

      execute_process(
        COMMAND
          "${CMAKE_COMMAND}" "${PACKAGE_WORKING_DIRECTORY}"
          # "-G" "${CMAKE_GENERATOR}"
          "-DCMAKE_INSTALL_PREFIX=${INSTALL_PACKAGE_LOCATION}"
          ${CURRENT_BUILD_TYPE} ${PACKAGE_COMMAND_LINE_ARGS}
        WORKING_DIRECTORY "${BUILD_PACKAGE_LOCATION}"
        RESULT_VARIABLE PROCESS_RESULT)

      if(NOT PROCESS_RESULT EQUAL 0)
        message(FATAL_ERROR "CMake generation has failed!"
                            "See the log for details.")
      endif()

      if(IS_MULTI_CONFIG)
        message(STATUS "CFetch: Installing configurations through multi-config "
                       "generator: ${CURRENT_CONFIGURATION_TYPES}")
      else()
        message(
          STATUS "Installing configuration: ${CURRENT_CONFIGURATION_TYPES}")
      endif()

      if(NOT CFETCH_DEPENDENCY_TARGETS)
        if(MSVC)
          list(APPEND CFETCH_DEPENDENCY_TARGETS "INSTALL")
        else()
          list(APPEND CFETCH_DEPENDENCY_TARGETS "install")
        endif()
      endif()

      foreach(CURRENT_CONFIGURATION IN LISTS CURRENT_CONFIGURATION_TYPES)
        foreach(CURRENT_TARGET IN LISTS CFETCH_DEPENDENCY_TARGETS)
          message(
            STATUS
              "Building target ${CURRENT_TARGET} of ${PACKAGE} (${CURRENT_CONFIGURATION})\n"
              "     into '${INSTALL_PACKAGE_LOCATION}'...")
          execute_process(
            COMMAND
              "${CMAKE_COMMAND}" "--build" "${BUILD_PACKAGE_LOCATION}"
              "--target" "${CURRENT_TARGET}" "--config"
              "${CURRENT_CONFIGURATION}"
            WORKING_DIRECTORY "${BUILD_PACKAGE_LOCATION}"
            RESULT_VARIABLE PROCESS_RESULT)

          if(NOT PROCESS_RESULT EQUAL 0)
            message(FATAL_ERROR "The build has failed! "
                                "See the log for details.")
          endif()
        endforeach()
      endforeach()

      message(
        STATUS "Committing directory '${INSTALL_PACKAGE_LOCATION}' to registry")
      file(TOUCH "${INSTALL_PACKAGE_LOCATION}/${CFETCH_COMMIT_FILENAME}")
      _cfetch_write_protect_directory("${INSTALL_PACKAGE_LOCATION}")

      message(
        STATUS
          "Build directory '${BUILD_PACKAGE_LOCATION}'\n    was installed "
          "and is not needed anymore.\n    It is kept for caching reasons, "
          "feel free to delete it.")
    endif()

    set(FIND_HINTS)
    foreach(HINT IN LISTS CFETCH_DEPENDENCY_HINTS)
      list(APPEND FIND_HINTS "${INSTALL_PACKAGE_LOCATION}/${HINT}")
    endforeach()

    set(${LIBRARY_NAME}_DIR "${INSTALL_PACKAGE_LOCATION}")
    set(${LIBRARY_NAME}_ROOT "${INSTALL_PACKAGE_LOCATION}")
    set(${LIBRARY_NAME}_FOUND ON)

    if(NOT CFETCH_DEPENDENCY_NO_FIND_PACKAGE)
      set(CFETCH_DEPENDENCY_FIND_PACKAGE_ARGS
          "${LIBRARY_NAME}" "REQUIRED" "HINTS" ${FIND_HINTS} "PATHS"
          "${INSTALL_PACKAGE_LOCATION}"
          PARENT_SCOPE)
    endif()
  else() # NOT CFETCH_DEPENDENCY_EXTERNAL
    cmake_policy(PUSH)
    cmake_policy(SET CMP0077 NEW)
    set(OLD_CMAKE_POLICY_DEFAULT_CMP0077 ${CMAKE_POLICY_DEFAULT_CMP0077})
    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)

    set(${LIBRARY_NAME}_DIR "${PACKAGE_LOCATION}")
    set(${LIBRARY_NAME}_ROOT "${PACKAGE_LOCATION}")
    set(${LIBRARY_NAME}_FOUND ON)

    # Set all CMake options that were specified
    foreach(CURRENT_OPTION IN LISTS CFETCH_DEPENDENCY_OPTIONS)
      string(REPLACE "=" ";" CURRENT_OPTION ${CURRENT_OPTION})
      list(GET CURRENT_OPTION 0 OPTION_KEY)
      list(GET CURRENT_OPTION 1 OPTION_VALUE)
      string(REPLACE "@" "\\;" OPTION_VALUE "${OPTION_VALUE}")
      set(${OPTION_KEY} ${OPTION_VALUE})
    endforeach()

    set(CFETCH_IN_TREE_BINARY_DIR
        "${CMAKE_BINARY_DIR}/cfetch_build/${LIBRARY_NAME}")

    if(CFETCH_DEPENDENCY_SUBDIRECTORY)
      add_subdirectory("${CFETCH_DEPENDENCY_SUBDIRECTORY}"
                       "${CFETCH_IN_TREE_BINARY_DIR}")
    else()
      add_subdirectory("${PACKAGE_WORKING_DIRECTORY}"
                       "${CFETCH_IN_TREE_BINARY_DIR}" EXCLUDE_FROM_ALL)
    endif()

    set(CMAKE_POLICY_DEFAULT_CMP0077 ${OLD_CMAKE_POLICY_DEFAULT_CMP0077})
    cmake_policy(POP)

    if(TARGET ${LIBRARY_NAME})
      get_target_property(LIBRARY_TARGET_TYPE ${LIBRARY_NAME} TYPE)
      if(NOT LIBRARY_TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
        set_target_properties(${LIBRARY_NAME} PROPERTIES FOLDER "dep")
      endif()
    endif()
  endif()

  if(CFETCH_DEPENDENCY_INSTALL_RUNTIME)
    foreach(CURRENT_INSTALL_RUNTIME IN LISTS CFETCH_DEPENDENCY_INSTALL_RUNTIME)
      _cfetch_install_shared_library_target("${CURRENT_INSTALL_RUNTIME}"
                                            "${CMAKE_INSTALL_PREFIX}")

    endforeach()
  endif()

  if(NOT CFETCH_SILENT)
    set(CFETCH_LINK_LIST_MESSAGE)

    if(CMAKE_FIND_PACKAGE_NAME AND ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
      foreach(COMPONENT IN LISTS ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
        list(APPEND CFETCH_LINK_LIST_MESSAGE
             " ${CMAKE_FIND_PACKAGE_NAME}::${COMPONENT}")
      endforeach()
    endif()

    if(NOT CFETCH_LINK_LIST_MESSAGE)
      set(CFETCH_LINK_LIST_MESSAGE " ${LIBRARY_NAME}::${LIBRARY_NAME}")
    endif()

    message(
      STATUS
        "CFetch provides targets from ${LIBRARY_NAME}: target_link_library(main PUBLIC${CFETCH_LINK_LIST_MESSAGE})"
    )
  endif()

  # Pass PACKAGE_DIR and PACKAGE_FOUND downwards
  set(${LIBRARY_NAME}_DIR
      "${${LIBRARY_NAME}_DIR}"
      PARENT_SCOPE)
  set(${LIBRARY_NAME}_ROOT
      "${${LIBRARY_NAME}_ROOT}"
      PARENT_SCOPE)
  set(${LIBRARY_NAME}_FOUND
      "${${LIBRARY_NAME}_FOUND}"
      PARENT_SCOPE)
endfunction()

macro(cfetch_dependency)
  _cfetch_dependency_ex(${ARGN})

  if(CFETCH_DEPENDENCY_FIND_PACKAGE_ARGS)
    cmake_policy(PUSH)

    if(POLICY CMP0074)
      cmake_policy(SET CMP0074 NEW) # Use PACKAGE_ROOT variables
    endif()

    find_package(${CFETCH_DEPENDENCY_FIND_PACKAGE_ARGS})
    unset(CFETCH_DEPENDENCY_FIND_PACKAGE_ARGS)

    cmake_policy(POP)
  endif()

  if(CMAKE_FIND_PACKAGE_NAME AND ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
    foreach(COMPONENT IN LISTS ${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS)
      _cfetch_install_shared_library_target(
        "${CMAKE_FIND_PACKAGE_NAME}::${COMPONENT}")
    endforeach()
  endif()
endmacro()

function(cfetch_header_dependency PACKAGE)
  set(arg_opt INSTALL EXPORT NO_LICENSE_FILE PIN_VERSION)
  set(arg_single AS SHA512 LICENSE_FILE URL BASE_DIR)
  set(arg_multi
      INCLUDE_DIRECTORIES
      DEFINITIONS
      FEATURES
      FILTER
      RENAME
      LINK_LIBRARIES
      PATCH)
  cmake_parse_arguments(CFETCH_HEADER_DEPENDENCY "${arg_opt}" "${arg_single}"
                        "${arg_multi}" ${ARGN})

  cfetch_package_info("${PACKAGE}" PACKAGE_USER PACKAGE_NAME PACKAGE_VERSION)

  if(CFETCH_HEADER_DEPENDENCY_AS)
    cfetch_target_name("${CFETCH_HEADER_DEPENDENCY_AS}" LIBRARY_NAME)
    cfetch_target_namespace("${CFETCH_HEADER_DEPENDENCY_AS}" LIBRARY_NAMESPACE)
  else()
    set(LIBRARY_NAME "${PACKAGE_NAME}")
    set(LIBRARY_NAMESPACE "${PACKAGE_NAME}::")
  endif()

  set(TARGET_NAME "${LIBRARY_NAMESPACE}${LIBRARY_NAME}")

  if(TARGET ${TARGET_NAME})
    return()
  endif()

  cfetch_package_cache_dir(PACKAGE_CACHE_DIR)

  _cfetch_check_dependency_version(
    "${LIBRARY_NAME}" "${PACKAGE_VERSION}" "${${LIBRARY_NAME}_FIND_VERSION}"
    "${CFETCH_HEADER_DEPENDENCY_PIN_VERSION}")

  if(${LIBRARY_NAME}_FIND_VERSION)
    set(PACKAGE_VERSION "${${LIBRARY_NAME}_FIND_VERSION}")
  endif()

  if(NOT CFETCH_HEADER_DEPENDENCY_INCLUDE_DIRECTORIES)
    set(CFETCH_HEADER_DEPENDENCY_INCLUDE_DIRECTORIES "include")
    list(APPEND CFETCH_HEADER_DEPENDENCY_FILTER "include")
  endif()

  if(CFETCH_HEADER_DEPENDENCY_NO_LICENSE_FILE)
    set(CFETCH_HEADER_DEPENDENCY_NO_LICENSE_FILE NO_LICENSE_FILE)
  endif()

  _cfetch_package_pull_ex(
    "${PACKAGE_USER}"
    "${PACKAGE_NAME}"
    "${PACKAGE_VERSION}"
    INTO
    PACKAGE_LOCATION
    URL
    ${CFETCH_HEADER_DEPENDENCY_URL}
    BASE_DIR
    ${CFETCH_HEADER_DEPENDENCY_BASE_DIR}
    FILTER
    ${CFETCH_HEADER_DEPENDENCY_FILTER}
    LICENSE_FILE
    ${CFETCH_HEADER_DEPENDENCY_LICENSE_FILE}
    ${CFETCH_HEADER_DEPENDENCY_NO_LICENSE_FILE}
    SHA512
    ${CFETCH_HEADER_DEPENDENCY_SHA512}
    RENAME
    ${CFETCH_HEADER_DEPENDENCY_RENAME}
    PATCH
    ${CFETCH_HEADER_DEPENDENCY_PATCH})

  set(INCLUDE_DIRS)
  foreach(INCLUDE_DIR IN LISTS CFETCH_HEADER_DEPENDENCY_INCLUDE_DIRECTORIES)
    list(APPEND INCLUDE_DIRS
         "$<BUILD_INTERFACE:${PACKAGE_LOCATION}/${INCLUDE_DIR}>"
         "$<INSTALL_INTERFACE:${INCLUDE_DIR}>")
  endforeach()

  add_library(${LIBRARY_NAME} INTERFACE)

  target_include_directories(${LIBRARY_NAME} INTERFACE ${INCLUDE_DIRS})

  if(CFETCH_HEADER_DEPENDENCY_DEFINITIONS)
    target_compile_definitions(
      ${LIBRARY_NAME} INTERFACE ${CFETCH_HEADER_DEPENDENCY_DEFINITIONS})
  endif()

  if(CFETCH_HEADER_DEPENDENCY_FEATURES)
    target_compile_features(${LIBRARY_NAME}
                            INTERFACE ${CFETCH_HEADER_DEPENDENCY_FEATURES})
  endif()

  if(CFETCH_HEADER_DEPENDENCY_LINK_LIBRARIES)
    foreach(LINK_LIBRARY IN LISTS CFETCH_HEADER_DEPENDENCY_LINK_LIBRARIES)
      cfetch_target_name("${LINK_LIBRARY}" FIND_LINK_LIBRARY)

      find_package(${FIND_LINK_LIBRARY} REQUIRED)
      target_link_libraries(${LIBRARY_NAME} INTERFACE ${LINK_LIBRARY})
    endforeach()
  endif()

  # TODO: Use CMAKE_INSTALL_INCLUDEDIR maybe
  if(CFETCH_HEADER_DEPENDENCY_INSTALL OR CFETCH_HEADER_DEPENDENCY_EXPORT)
    foreach(INCLUDE_DIR IN LISTS CFETCH_HEADER_DEPENDENCY_INCLUDE_DIRECTORIES)
      install(DIRECTORY "${PACKAGE_LOCATION}/${INCLUDE_DIR}"
              DESTINATION "${CMAKE_INSTALL_PREFIX}")
    endforeach()
  endif()

  if(CFETCH_HEADER_DEPENDENCY_EXPORT)
    include(CMakePackageConfigHelpers)

    set(EXPORT_NAME "${LIBRARY_NAME}-export")

    install(TARGETS "${LIBRARY_NAME}" EXPORT ${EXPORT_NAME})

    install(
      EXPORT ${EXPORT_NAME}
      NAMESPACE ${LIBRARY_NAMESPACE}
      DESTINATION "${CMAKE_INSTALL_PREFIX}/share/cmake"
      FILE "Find${LIBRARY_NAME}.cmake"
      EXPORT_LINK_INTERFACE_LIBRARIES)
  endif()

  if(NOT TARGET_NAME STREQUAL LIBRARY_NAME)
    add_library(${TARGET_NAME} ALIAS ${LIBRARY_NAME})
  endif()

  #[[if(NOT TARGET_NAME STREQUAL LIBRARY_NAME)
    add_library(${TARGET_NAME} INTERFACE IMPORTED GLOBAL)
    target_link_libraries(${TARGET_NAME} INTERFACE ${LIBRARY_NAME})
  endif()]]

  set(${LIBRARY_NAME}_DIR
      "${PACKAGE_LOCATION}"
      PARENT_SCOPE)
  set(${LIBRARY_NAME}_FOUND
      ON
      PARENT_SCOPE)

  if(NOT CFETCH_SILENT)
    message(
      STATUS
        "CFetch provides ${LIBRARY_NAME}: target_link_library(main PUBLIC ${TARGET_NAME})"
    )
  endif()
endfunction()
