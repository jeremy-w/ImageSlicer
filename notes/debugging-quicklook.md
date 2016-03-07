## Debugging QuickLook
qlmanage is failing to load QuickLookSlicedImage.qlgenerator with the same
"damaged or missing stuff" error GateKeeper gives me whenever I try to run an
unsigned app bundle.

Rigged up a test harness by following the instructions in the
*Quick Look Programming Guide,*
["Debugging and Testing a Generator"](https://developer.apple.com/library/prerelease/mac/documentation/UserExperience/Conceptual/Quicklook_Programming_Guide/Articles/QLDebugTest.html#//apple_ref/doc/uid/TP40005020-CH14-SW4),
with the appropriate changes for Xcode 4+.

Promising breakpoints:

- `__QLLoadPluginAtURL` - $arg4 is relative URL so use `(BOOL)[[$arg4 lastPathComponent] hasPrefix: @"QuickLookSlicedImage"]` as condition
- arg1, 2, 3 are dictionaries mapping:
  1. UTI to QLGenerator
  2. string path of .qlgenerator bundle to QLGenerator
  3. generator bundle ID to QLGenerator
- `_QLError` (never hits)
- `_CFPlugInCreate`

`qlmanage` goes through and loads a bunch of plugins. After it loads mine, it
ends up in CFPlugInCreate.
That successfully loads the bundle:

```
CFBundle/CFPlugIn 0x10028a3f0 </Users/jeremy/Library/Developer/Xcode/DerivedData/ImageSlicer-haytfaakgngbkjczhchrnadasxhk/Build/Products/Debug/Image Slicer.app/Contents/Library/QuickLook/QuickLookSlicedImage.qlgenerator> (not loaded)
```

`___QLGeneratorWakeUp_block_invoke` then grabs the bundle from the plug-in and
tries to load the executable with `CFBundleLoadExecutableAndReturnError`.
And that's where the "we can't load this thing" error comes from!

Actually, that just calls straight to an underscore-prefixed version. Huh.

Dirty work must happen in `_CFBundleDlfcnLoadBundle`.
It does `dlopen(path, RTLD_FIRST | RTLD_NOW | RTLD_LOCAL)` (aka 0x106).
Returns nil.

And, bingo! The call to `dlerror` gives us a real error message:

```
(lldb) x/s $rax
0x100576819: "dlopen(/Users/jeremy/Library/Developer/Xcode/DerivedData/ImageSlicer-haytfaakgngbkjczhchrnadasxhk/Build/Products/Debug/Image Slicer.app/Contents/Library/QuickLook/QuickLookSlicedImage.qlgenerator/Contents/MacOS/QuickLookSlicedImage, 262): Library not loaded: @rpath/libswiftAppKit.dylib\n  Referenced from: /Users/jeremy/Library/Developer/Xcode/DerivedData/ImageSlicer-haytfaakgngbkjczhchrnadasxhk/Build/Products/Debug/Image Slicer.app/Contents/Library/QuickLook/QuickLookSlicedImage.qlgenerator/Contents/MacOS/QuickLookSlicedImage\n  Reason: image not found"
```

Setting `EMBEDDED_CONTENT_CONTAINS_SWIFT=YES` for the QuickLook bundle did NOT
seem to fix this, even though I can see that libswiftAppKit.dylib is in the
qlgenerator bundle's embedded Frameworks directory.

man dyld helps:

- rpath can be logged by setting env var `DYLD_PRINT_RPATHS`.
- rpath is built of `LC_RPATH` load commands in the dependency chain that led to the library load
- what we probably actually want is `@loader_path`-relative references to the
  `libswift*.dylibs`, because these don't rely on the rpath being what we
  expect. But we should check the rpath in qlmanage first I guess.

Printing rpaths gives:

```
RPATH failed to expanding     @rpath/libswiftAppKit.dylib to: /System/Library/Frameworks/QuickLook.framework/Versions/A/Resources/quicklookd.app/Contents/MacOS/../Frameworks/libswiftAppKit.dylib
RPATH failed to expanding     @rpath/libswiftAppKit.dylib to: /Users/jeremy/Library/Developer/Xcode/DerivedData/ImageSlicer-haytfaakgngbkjczhchrnadasxhk/Build/Products/Debug/Image Slicer.app/Contents/Library/QuickLook/QuickLookSlicedImage.qlgenerator/Contents/MacOS/../Frameworks/libswiftAppKit.dylib
RPATH failed to expanding     @rpath/libswiftAppKit.dylib to: /System/Library/Frameworks/QuickLook.framework/Versions/A/Resources/quicklookd.app/Contents/MacOS/../Frameworks/libswiftAppKit.dylib
RPATH failed to expanding     @rpath/libswiftAppKit.dylib to: /Users/jeremy/Library/Developer/Xcode/DerivedData/ImageSlicer-haytfaakgngbkjczhchrnadasxhk/Build/Products/Debug/Image Slicer.app/Contents/Library/QuickLook/QuickLookSlicedImage.qlgenerator/Contents/MacOS/../Frameworks/libswiftAppKit.dylib
[ERROR] Can't load plug-in at file:///Users/jeremy/Library/Developer/Xcode/DerivedData/ImageSlicer-haytfaakgngbkjczhchrnadasxhk/Build/Products/Debug/Image%20Slicer.app/Contents/Library/QuickLook/QuickLookSlicedImage.qlgenerator/: El paquete “QuickLookSlicedImage” no se ha podido cargar porque está dañado o le faltan recursos necesarios.
```

A-hah, that one doesn't have that in there.
Because it's running the one in my main app (which I haven't rebuilt yet).
Should have been explicit about the generator in my qlmanage invocation!

And now that I've added the appropriate -g flag to run the just-built generator
rather than the old one in the app bundle, it runs! And fails. But now I can
tone down the qlmanage logging and focus on debugging my plugin.
