# Qt XCB GL Integration Plugins

This directory contains two third-party Qt binary plugins:

```text
libqxcb-egl-integration.so
libqxcb-glx-integration.so
```

They are not Gowin files. They are Qt 5.15.14-compatible
`xcbglintegrations` plugins used to make the vendor-provided Gowin IDE runtime
work on desktop systems where the host Qt private ABI does not match Gowin's
bundled Qt 5.15.14 libraries.

## Source

The plugins were extracted from the Arch Linux Archive package:

```text
qt5-base-5.15.14+kde+r143-1-x86_64.pkg.tar.zst
```

They are redistributed here only to provide the Qt runtime component missing
from the user-provided Gowin Linux archive.

## License

Qt is available under LGPL/GPL/commercial licensing terms depending on the
component and distribution. These plugins should be treated as Qt runtime
components subject to Qt's open-source license terms and any terms from the
distribution package they were extracted from.

If you redistribute this repository or generated AppImages, review the Qt
license obligations for binary redistribution, including providing the
corresponding Qt source or an offer as required by the applicable license.

## Why They Are Tracked

The Gowin archive bundles Qt 5.15.14 but does not include the matching XCB GL
integration plugins. Host plugins from other Qt patch/private-ABI versions fail
to load. Keeping these two small plugins in the repository makes the build
reproducible without downloading third-party packages during every build.
