A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.


1. Import dartprofiler as dependency in your flutter app.
2. Copy cpp lib folder.
3. Add externalNativeBuild in `android/app/build.gradle`.
4. In the same file, add `buildTypes`, `ndk`, `abiFilters`.
