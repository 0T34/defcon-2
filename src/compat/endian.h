// Copyright (c) 2014 The Bitcoin developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef BITCOIN_COMPAT_ENDIAN_H
#define BITCOIN_COMPAT_ENDIAN_H

#include <stdint.h>

#include "compat/byteswap.h"

#if defined(OS_MACOSX)
    #include <machine/endian.h>
#elif defined(OS_SOLARIS)
    #include <sys/isa_defs.h>
    #ifdef _LITTLE_ENDIAN
        #define LITTLE_ENDIAN
    #elif defined(_BIG_ENDIAN)
        #define BIG_ENDIAN
    #endif
#elif defined(OS_FREEBSD) || defined(OS_OPENBSD) || defined(OS_NETBSD) ||\
      defined(OS_DRAGONFLYBSD)
    #include <sys/endian.h>
#else
    #include <endian.h>
#endif

#if defined(BIG_ENDIAN)

#if !defined(htobe16)
inline uint16_t htobe16(uint16_t host_16bits)
{
    return host_16bits;
}
#endif

#if !defined(htole16)
inline uint16_t htole16(uint16_t host_16bits)
{
    return bswap_16(host_16bits);
}
#endif

#if !defined(be16toh)
inline uint16_t be16toh(uint16_t big_endian_16bits)
{
    return big_endian_16bits;
}
#endif

#if !defined(le16toh)
inline uint16_t le16toh(uint16_t little_endian_16bits)
{
    return bswap_16(little_endian_16bits);
}
#endif

#if !defined(htobe32)
inline uint32_t htobe32(uint32_t host_32bits)
{
    return host_32bits;
}
#endif

#if !defined(htole32)
inline uint32_t htole32(uint32_t host_32bits)
{
    return bswap_32(host_32bits);
}
#endif

#if !defined(be32toh)
inline uint32_t be32toh(uint32_t big_endian_32bits)
{
    return big_endian_32bits;
}
#endif

#if !defined(le32toh)
inline uint32_t le32toh(uint32_t little_endian_32bits)
{
    return bswap_32(little_endian_32bits);
}
#endif

#if !defined(htobe64)
inline uint64_t htobe64(uint64_t host_64bits)
{
    return host_64bits;
}
#endif

#if !defined(htole64)
inline uint64_t htole64(uint64_t host_64bits)
{
    return bswap_64(host_64bits);
}
#endif

#if !defined(be64toh)
inline uint64_t be64toh(uint64_t big_endian_64bits)
{
    return big_endian_64bits;
}
#endif

#if !defined(le64toh)
inline uint64_t le64toh(uint64_t little_endian_64bits)
{
    return bswap_64(little_endian_64bits);
}
#endif

#else

#if !defined(htobe16)
inline uint16_t htobe16(uint16_t host_16bits)
{
    return bswap_16(host_16bits);
}
#endif

#if !defined(htole16)
inline uint16_t htole16(uint16_t host_16bits)
{
    return host_16bits;
}
#endif

#if !defined(be16toh)
inline uint16_t be16toh(uint16_t big_endian_16bits)
{
    return bswap_16(big_endian_16bits);
}
#endif

#if !defined(le16toh)
inline uint16_t le16toh(uint16_t little_endian_16bits)
{
    return little_endian_16bits;
}
#endif

#if !defined(htobe32)
inline uint32_t htobe32(uint32_t host_32bits)
{
    return bswap_32(host_32bits);
}
#endif

#if !defined(htole32)
inline uint32_t htole32(uint32_t host_32bits)
{
    return host_32bits;
}
#endif

#if !defined(be32toh)
inline uint32_t be32toh(uint32_t big_endian_32bits)
{
    return bswap_32(big_endian_32bits);
}
#endif

#if !defined(le32toh)
inline uint32_t le32toh(uint32_t little_endian_32bits)
{
    return little_endian_32bits;
}
#endif

#if !defined(htobe64)
inline uint64_t htobe64(uint64_t host_64bits)
{
    return bswap_64(host_64bits);
}
#endif

#if !defined(htole64)
inline uint64_t htole64(uint64_t host_64bits)
{
    return host_64bits;
}
#endif

#if !defined(be64toh)
inline uint64_t be64toh(uint64_t big_endian_64bits)
{
    return bswap_64(big_endian_64bits);
}
#endif

#if !defined(le64toh)
inline uint64_t le64toh(uint64_t little_endian_64bits)
{
    return little_endian_64bits;
}
#endif

#endif

#endif // BITCOIN_COMPAT_ENDIAN_H
