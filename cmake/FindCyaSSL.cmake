if(CYASSL_PREFER_STATIC_LIB)
    set(CYASSL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
    if(WIN32)
        set(CMAKE_FIND_LIBRARY_SUFFIXES .a .lib ${CMAKE_FIND_LIBRARY_SUFFIXES})
    else()
        set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
    endif()
endif()

if(UNIX)
    find_package(PkgConfig QUIET)
    pkg_check_modules(_WOLFSSL QUIET wolfssl)
endif()

find_path(WOLFSSL_INCLUDE_DIR NAMES wolfssl/version.h HINTS ${_WOLFSSL_INCLUDEDIR})
find_library(WOLFSSL_LIBRARY NAMES wolfssl HINTS ${_WOLFSSL_LIBDIR})
if(WOLFSSL_INCLUDE_DIR AND WOLFSSL_LIBRARY)
    set(CYASSL_INCLUDE_DIR ${WOLFSSL_INCLUDE_DIR})
    set(CYASSL_LIBRARY ${WOLFSSL_LIBRARY})
    set(CYASSL_VERSION ${_WOLFSSL_VERSION})
    set(CYASSL_IS_WOLFSSL ON)
else()
    if(UNIX)
        pkg_check_modules(_CYASSL QUIET cyassl)
    endif()

    find_path(CYASSL_INCLUDE_DIR NAMES cyassl/version.h HINTS ${_CYASSL_INCLUDEDIR})
    find_library(CYASSL_LIBRARY NAMES cyassl HINTS ${_CYASSL_LIBDIR})
    set(CYASSL_VERSION ${_CYASSL_VERSION})
    set(CYASSL_IS_WOLFSSL OFF)
endif()

if(NOT CYASSL_VERSION AND CYASSL_INCLUDE_DIR)
    if(CYASSL_IS_WOLFSSL)
        file(STRINGS "${CYASSL_INCLUDE_DIR}/wolfssl/version.h" CYASSL_VERSION_STR REGEX "^#define[\t ]+LIBWOLFSSL_VERSION_STRING[\t ]+\"[^\"]+\"")
    else()
        file(STRINGS "${CYASSL_INCLUDE_DIR}/cyassl/version.h" CYASSL_VERSION_STR REGEX "^#define[\t ]+LIBCYASSL_VERSION_STRING[\t ]+\"[^\"]+\"")
    endif()
    if(CYASSL_VERSION_STR MATCHES "\"([^\"]+)\"")
        set(CYASSL_VERSION "${CMAKE_MATCH_1}")
    endif()
endif()

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(CyaSSL
    REQUIRED_VARS
        CYASSL_LIBRARY
        CYASSL_INCLUDE_DIR
    VERSION_VAR
        CYASSL_VERSION
)

mark_as_advanced(WOLFSSL_INCLUDE_DIR WOLFSSL_LIBRARY CYASSL_INCLUDE_DIR CYASSL_LIBRARY)

if(CYASSL_PREFER_STATIC_LIB)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CYASSL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})
    unset(CYASSL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES)
endif()

if(CyaSSL_FOUND)
    set(CYASSL_INCLUDE_DIRS ${CYASSL_INCLUDE_DIR})
    set(CYASSL_LIBRARIES ${CYASSL_LIBRARY})

    if(NOT TARGET CyaSSL::CyaSSL)
        add_library(CyaSSL::CyaSSL INTERFACE IMPORTED)
        target_include_directories(CyaSSL::CyaSSL
            INTERFACE
                ${CYASSL_INCLUDE_DIRS})
        target_link_libraries(CyaSSL::CyaSSL
            INTERFACE
                ${CYASSL_LIBRARIES})
        target_compile_definitions(CyaSSL::CyaSSL
            INTERFACE
                $<$<BOOL:${CYASSL_IS_WOLFSSL}>:CYASSL_IS_WOLFSSL>)
    endif()
endif()
