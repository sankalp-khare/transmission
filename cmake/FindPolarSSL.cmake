if(POLARSSL_PREFER_STATIC_LIB)
    set(POLARSSL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
    if(WIN32)
        set(CMAKE_FIND_LIBRARY_SUFFIXES .a .lib ${CMAKE_FIND_LIBRARY_SUFFIXES})
    else()
        set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
    endif()
endif()

if(UNIX)
    find_package(PkgConfig QUIET)
    pkg_check_modules(_MBEDTLS QUIET mbedtls)
endif()

find_path(MBEDTLS_INCLUDE_DIR NAMES mbedtls/version.h HINTS ${_MBEDTLS_INCLUDEDIR})
find_library(MBEDTLS_LIBRARY NAMES mbedtls HINTS ${_MBEDTLS_LIBDIR})
find_library(MBEDCRYPTO_LIBRARY NAMES mbedcrypto HINTS ${_MBEDTLS_LIBDIR})
if(MBEDTLS_INCLUDE_DIR AND MBEDTLS_LIBRARY)
    set(POLARSSL_INCLUDE_DIR ${MBEDTLS_INCLUDE_DIR})
    if(MBEDCRYPTO_LIBRARY)
        set(POLARSSL_LIBRARY ${MBEDTLS_LIBRARY} ${MBEDCRYPTO_LIBRARY})
    else()
        set(POLARSSL_LIBRARY ${MBEDTLS_LIBRARY})
    endif()
    set(POLARSSL_VERSION ${_MBEDTLS_VERSION})
    set(POLARSSL_IS_MBEDTLS ON)
else()
    if(UNIX)
        pkg_check_modules(_POLARSSL QUIET polarssl)
    endif()

    find_path(POLARSSL_INCLUDE_DIR NAMES polarssl/version.h HINTS ${_POLARSSL_INCLUDEDIR})
    find_library(POLARSSL_LIBRARY NAMES polarssl HINTS ${_POLARSSL_LIBDIR})
    set(POLARSSL_VERSION ${_POLARSSL_VERSION})
    set(POLARSSL_IS_MBEDTLS OFF)
endif()

if(NOT POLARSSL_VERSION AND POLARSSL_INCLUDE_DIR)
    if(POLARSSL_IS_MBEDTLS)
        file(STRINGS "${POLARSSL_INCLUDE_DIR}/mbedtls/version.h" POLARSSL_VERSION_STR REGEX "^#define[\t ]+MBEDTLS_VERSION_STRING[\t ]+\"[^\"]+\"")
    else()
        file(STRINGS "${POLARSSL_INCLUDE_DIR}/polarssl/version.h" POLARSSL_VERSION_STR REGEX "^#define[\t ]+POLARSSL_VERSION_STRING[\t ]+\"[^\"]+\"")
    endif()
    if(POLARSSL_VERSION_STR MATCHES "\"([^\"]+)\"")
        set(POLARSSL_VERSION "${CMAKE_MATCH_1}")
    endif()
endif()

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(PolarSSL
    REQUIRED_VARS
        POLARSSL_LIBRARY
        POLARSSL_INCLUDE_DIR
    VERSION_VAR
        POLARSSL_VERSION
)

mark_as_advanced(MBEDTLS_INCLUDE_DIR MBEDTLS_LIBRARY MBEDCRYPTO_LIBRARY POLARSSL_INCLUDE_DIR POLARSSL_LIBRARY)

if(POLARSSL_PREFER_STATIC_LIB)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${POLARSSL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})
    unset(POLARSSL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES)
endif()

if(PolarSSL_FOUND)
    set(POLARSSL_INCLUDE_DIRS ${POLARSSL_INCLUDE_DIR})
    set(POLARSSL_LIBRARIES ${POLARSSL_LIBRARY})

    if(NOT TARGET PolarSSL::PolarSSL)
        add_library(PolarSSL::PolarSSL INTERFACE IMPORTED)
        target_include_directories(PolarSSL::PolarSSL
            INTERFACE
                ${POLARSSL_INCLUDE_DIRS})
        target_link_libraries(PolarSSL::PolarSSL
            INTERFACE
                ${POLARSSL_LIBRARIES})
        target_compile_definitions(PolarSSL::PolarSSL
            INTERFACE
                $<$<BOOL:${POLARSSL_IS_MBEDTLS}>:POLARSSL_IS_MBEDTLS>)
    endif()
endif()
