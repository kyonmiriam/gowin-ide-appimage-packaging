#define _GNU_SOURCE

#include <dlfcn.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

typedef bool (*qputenv_fn)(const char *, const void *);
typedef int (*open_fn)(const char *, int, ...);
typedef int (*openat_fn)(int, const char *, int, ...);

static const char *redirect_icudtl(const char *path)
{
    const char *redirect;

    if (!path || strcmp(path, "icudtl.dat") != 0)
        return path;

    redirect = getenv("GOWIN_ICUDTL_PATH");
    return redirect && redirect[0] ? redirect : path;
}

int open(const char *path, int flags, ...)
{
    static open_fn real_open;
    mode_t mode = 0;

    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
    }

    if (!real_open)
        real_open = (open_fn)dlsym(RTLD_NEXT, "open");

    if (flags & O_CREAT)
        return real_open(redirect_icudtl(path), flags, mode);
    return real_open(redirect_icudtl(path), flags);
}

int open64(const char *path, int flags, ...)
{
    static open_fn real_open64;
    mode_t mode = 0;

    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
    }

    if (!real_open64)
        real_open64 = (open_fn)dlsym(RTLD_NEXT, "open64");

    if (flags & O_CREAT)
        return real_open64(redirect_icudtl(path), flags, mode);
    return real_open64(redirect_icudtl(path), flags);
}

int openat(int dirfd, const char *path, int flags, ...)
{
    static openat_fn real_openat;
    mode_t mode = 0;

    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
    }

    if (!real_openat)
        real_openat = (openat_fn)dlsym(RTLD_NEXT, "openat");

    if (flags & O_CREAT)
        return real_openat(dirfd, redirect_icudtl(path), flags, mode);
    return real_openat(dirfd, redirect_icudtl(path), flags);
}

int openat64(int dirfd, const char *path, int flags, ...)
{
    static openat_fn real_openat64;
    mode_t mode = 0;

    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
    }

    if (!real_openat64)
        real_openat64 = (openat_fn)dlsym(RTLD_NEXT, "openat64");

    if (flags & O_CREAT)
        return real_openat64(dirfd, redirect_icudtl(path), flags, mode);
    return real_openat64(dirfd, redirect_icudtl(path), flags);
}

bool qputenv_intercept(const char *name, const void *value) __asm__("_Z7qputenvPKcRK10QByteArray");

bool qputenv_intercept(const char *name, const void *value)
{
    static qputenv_fn real_qputenv;

    if (name && (strcmp(name, "QT_XCB_GL_INTEGRATION") == 0
            || strcmp(name, "QT_OPENGL") == 0
            || strcmp(name, "QTWEBENGINE_CHROMIUM_FLAGS") == 0
            || strcmp(name, "QTWEBENGINEPROCESS_PATH") == 0
            || strcmp(name, "QTWEBENGINE_RESOURCES_PATH") == 0
            || strcmp(name, "QTWEBENGINE_LOCALES_PATH") == 0))
        return true;

    if (!real_qputenv)
        real_qputenv = (qputenv_fn)dlsym(RTLD_NEXT, "_Z7qputenvPKcRK10QByteArray");

    if (!real_qputenv)
        return false;

    return real_qputenv(name, value);
}
