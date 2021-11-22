#ifndef INCLUDE_features_h__
#define INCLUDE_features_h__

/* #undef GIT_DEBUG_POOL */
#define GIT_TRACE 1
#define GIT_THREADS 1
/* #undef GIT_MSVC_CRTDBG */

/* #undef GIT_ARCH_64 */
#define GIT_ARCH_32 1

/* #undef GIT_USE_ICONV */
#define GIT_USE_NSEC 1
#define GIT_USE_STAT_MTIM 1
/* #undef GIT_USE_STAT_MTIMESPEC */
/* #undef GIT_USE_STAT_MTIME_NSEC */
/* #undef GIT_USE_FUTIMENS */

/* #undef GIT_REGEX_REGCOMP_L */
/* #undef GIT_REGEX_REGCOMP */
/* #undef GIT_REGEX_PCRE */
/* #undef GIT_REGEX_PCRE2 */
#define GIT_REGEX_BUILTIN 1

/* #undef GIT_SSH */
/* #undef GIT_SSH_MEMORY_CREDENTIALS */

#define GIT_NTLM 1
/* #undef GIT_GSSAPI */
/* #undef GIT_GSSFRAMEWORK */

/* #undef GIT_WINHTTP */
#define GIT_HTTPS 1
#define GIT_OPENSSL 1
/* #undef GIT_SECURE_TRANSPORT */
/* #undef GIT_MBEDTLS */

#define GIT_SHA1_COLLISIONDETECT 1
/* #undef GIT_SHA1_WIN32 */
/* #undef GIT_SHA1_COMMON_CRYPTO */
/* #undef GIT_SHA1_OPENSSL */
/* #undef GIT_SHA1_MBEDTLS */

#endif
