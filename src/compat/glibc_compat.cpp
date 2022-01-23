// Copyright (c) 2009-2014 The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <cstddef>

#include "compat.h"

#if defined(_AIX) || defined(__NOVELL_LIBC__) || \
    defined(__NetBSD__) || defined(__minix) || \
    defined(__SYMBIAN32__) || defined(__INTEGRITY) || \
    defined(ANDROID) || defined(__ANDROID__) || \
    defined(__OpenBSD__) || \
   (defined(__FreeBSD_version) && (__FreeBSD_version < 800000))
#include <sys/select.h>
#endif

// Prior to GLIBC_2.14, memcpy was aliased to memmove.
extern "C" void* memmove(void* a, const void* b, size_t c);
extern "C" void* memcpy(void* a, const void* b, size_t c)
{
    return memmove(a, b, c);
}

extern "C" void __chk_fail(void) __attribute__((__noreturn__));
extern "C" long int __fdelt_warn(long int a)
{
    if (a >= FD_SETSIZE)
        __chk_fail();
    return a / __NFDBITS;
}
extern "C" long int __fdelt_chk(long int) __attribute__((weak, alias("__fdelt_warn")));
