#define _GNU_SOURCE

#include <dlfcn.h>
#include <stdbool.h>
#include <string.h>

typedef bool (*qputenv_fn)(const char *, const void *);

bool qputenv_intercept(const char *name, const void *value) __asm__("_Z7qputenvPKcRK10QByteArray");

bool qputenv_intercept(const char *name, const void *value)
{
    static qputenv_fn real_qputenv;

    if (name && (strcmp(name, "QT_XCB_GL_INTEGRATION") == 0
            || strcmp(name, "QT_OPENGL") == 0
            || strcmp(name, "QTWEBENGINE_CHROMIUM_FLAGS") == 0))
        return true;

    if (!real_qputenv)
        real_qputenv = (qputenv_fn)dlsym(RTLD_NEXT, "_Z7qputenvPKcRK10QByteArray");

    if (!real_qputenv)
        return false;

    return real_qputenv(name, value);
}
