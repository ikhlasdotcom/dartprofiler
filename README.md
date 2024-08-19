A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.


1. Import dartprofiler as dependency in your flutter app.
2. Copy cpp lib folder.
3. Add externalNativeBuild in `android/app/build.gradle`.
4. In the same file, add `buildTypes`, `ndk`, `abiFilters`.

Example
```
externalNativeBuild {
        cmake {
            path "../../dartprofiler_library/CMakeLists.txt"
        }
    }

buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.debug

            ndk {
                abiFilters "arm64-v8a"
            }
        }
    }
