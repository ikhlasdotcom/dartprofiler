# dartprofiler

Based on Casey Muratori's C++ profiler and repetition tester in his Computer
Enhance course, this tool lets you profile and time specific segments of your
Dart code with minimal overhead.

- Uses Dart FFI so that you can speak with CPU directly (overhead is less than
  Stopwatch, but can't be inlined on an assembly level, analysis done below)
- Independent from Dart's and Flutters profiling tools, which allows you to run
  it even in flutter's `release` mode.

This tool is by no means perfect. I pulled it together really quickly to get
some performance data for a project I was on short-term which I found the Dart
DevTools to be unsatisfactory. I apologise in advance to anyone finds the setup
process a pain. It has been open-sourced to give you an example as to how you
can approach your own profiler, or hopefully, this profiler is improved upon by
community-driven effort.

## Philosophy

- The lightweightness gives you a picture of your how performant the segment of your
  code is, with minimal distortions.
- You ought to be able to talk to the CPU directly. All the drudge work of
  setting up the FFI into C++ has been done.
- The repetition tester allows you to time how long your code will take in the
  best case scenario, on top of counting page faults. What it does is that it
  runs a chunk of code repeatedly until it has hit a minimum that cannot be
  beaten for 10 seconds.

## Setup 

A lot of work is needed on the part of the developer to actually get all this
working. If all this work doesn't seem worth it, you can replace the ticks in
`dartprofiler.dart` with stopwatch ticks. It's a little less efficient, but it
gets the job done.

Unfortunately, I have only tried this with an Android device for a Flutter
app. The setup provides a lot of instructions for that particular context. At
the very least, I have linked some resources to make your life a little
easier. Everyone has to go through step 1 and 2. Steps 3 and 4 will differ
depending on how you are building the c++ code, whether you are using Flutter,
and which platform you are on.

[This](https://dart.dev/interop/c-interop) is the official documentation for c
interop in Dart. [The Bundle and load C
libraries](https://dart.dev/interop/c-interop#bundle-and-load-c-libraries)
section should be extra important to you if you are on a platform that differs
from the steps below.

1. Clone/download the repository, and import dartprofiler as dependency in your
   flutter app. For more information about `path:`, read [the official documentation](https://docs.flutter.dev/packages-and-plugins/using-packages#dependencies-on-unpublished-packages).

```yaml
# In pubspec.yaml

# ...

dev_dependencies:
  # ...
  dartprofiler:
    path: "../path/to/dartprofiler"
  # ...

# ...

```

2. Copy the `dartprofiler_lib` into the root of your app, you can rename it if
   you would like. If you are using flutter, you can ignore `build.sh` and rely
   solely on CMakeLists.txt. `build.sh` gives you an example of how you can compile
   the `cpp` code. If you would like to modify `cpp` side of things, you would
   have to look at `libdartprofiler.cpp`. I have provided examples for `rdtsc`
   and `cntvct_el0`. 
3. If you're relying on the `CMakeLists.txt` to build your c++ library (like for
   Flutter developers), make sure your build knows about the c++ library. For Android, add
   [`externalNativeBuild`](https://developer.android.com/reference/tools/gradle-api/8.0/com/android/build/api/dsl/ExternalNativeBuild) in `android/app/build.gradle`, as below. Make sure that
   it's pointing to the aforementioned `CMakeLists.txt`. I haven't tried
   it with any other platform. If you figure it out, feel free to make a PR to
   add to this `README`.
   
```
externalNativeBuild {
    // ...
    cmake {
        path "../../dartprofiler_library/CMakeLists.txt"
    }
    // ...
}

```

4. If you are talking to the CPU, make sure your build knows about it. For
   Flutter development on Android, add the following to
   `android/app/build.gradle`. If you are running in a mode other than release,
   replace `release` with that mode, like `debug`. Replace `"arm64-v8a"` with
   your particular ABI.

```
// ...
buildTypes {
    release {
        signingConfig = signingConfigs.debug

        ndk {
            abiFilters "arm64-v8a"
        }
    }
}
// ...
```

## Guide

### `dartprofiler`

The following is a gist of how one would use this library to profile a segment
of their code.

```dart
// Tip: Import as a unique name, like `dp`, so you can just for `dp` to find
// where you are using the profiler.

import 'package:dartprofiler/dartprofiler.dart' as dp;

void main() {
    doSomeStuff1();
    
    // Suppose we are interested in `doSomeStuff2` and `doSomeStuff3` only, we can surround it with
    `beginProfile` and `endAndPrintProfile` so that the profiler ignores
    `doSomeStuff1`. 
    
    
    dp.beginProfile();
    
    // Suppose we want to know the individual time spent by doSomeStuff2 and
    doSomeStuff3. We can use `markStart` and `markEnd`, or their alias, `s` and
    `e` respectively.
    
    final b0 = dp.s("doSomeStuff2", 0);
    doSomeStuff2(5);
    dp.e(b0);
    
    final b1 = dp.s("doSomeStuff3", 1);
    doSomeStuff3();
    dp.e(b1);
    
    dp.endAndPrintProfile();
}
```

For a reference to the API, see the
[documentation](/doc/api/dartprofiler/dartprofiler-library.html). You only need
to care about everything in `Functions`, and `e` and `s`. Note that `e` and `s`
are aliases for `markStart` and `markEnd` respectively.

### `stubdartprofiler`
Exactly the same API as `dartprofiler`, but all the procedures, except
`beginProfile` and `endAndPrintProfile`, do nothing. The two procedures that do
something calculate the total time spent in the profiled code segment. The
purpose of this is to allow you to get a baseline on how long your code is
taking with basically no intrusion from the profiler. You can then compare this
number with how long your profiled code segment takes with `dartprofiler`. The
difference indicates how intrusive your profiling is.

### `repetition_tester`

Here is an example of how one might use the repetition tester. This example
explores the performance difference between `readCPUTimer` and using
`stopwatch.elapsedTicks`. If you were to run this test yourself, `readCPUTimer`
should be significantly better. If it for some reason isn't, then you should
modify the dart profiler to use `stopwatch.elapsedTicks` under the hood.

In general, the only procedure you need from `repetition_tester.dart` are
`newTestWave`, `isTesting`, `beginTime` and `endTime`.

```dart
import 'package:dartprofiler/repetition_tester.dart';
import 'package:dartprofiler/platform_metrics.dart';

typedef void ReadCPUTimerTestFunc(RepetitionTester tester);

void regularRead(RepetitionTester tester) {
  while (isTesting(tester)) {
    beginTime(tester);
    final initialTime = readCPUTimer();
    int elapsedTime;

    for (var i = 0; i < 100000; i++) {
      elapsedTime = readCPUTimer() - initialTime;
    }
    endTime(tester);
  }
}

void stopwatchRead(RepetitionTester tester) {
  while (isTesting(tester)) {
    final Stopwatch stopwatch = Stopwatch();
    stopwatch.start();
    
    beginTime(tester);
    final initialTime = stopwatch.elapsedTicks;
    var elapsedTime;
    
    for (var i = 0; i < 100000; i++) {
      elapsedTime = stopwatch.elapsedTicks - initialTime;
    }
    endTime(tester);
  }
}

class TestFunction {
  String name;
  ReadCPUTimerTestFunc func;

  TestFunction(this.name, this.func);
}

List<TestFunction> testFunctions = [
  TestFunction("Stopwatch", stopwatchRead),
  TestFunction("ReadCPUTime", regularRead),
];

void main() {
  double CPUTimerFreq = estimateCPUTimerFreq();
  
  List<RepetitionTester> testers = List<RepetitionTester>.generate(testFunctions.length, (_) => RepetitionTester());

  while (true) {
    for (var i = 0; i < testFunctions.length; i++) {
      RepetitionTester tester = testers[i];
      TestFunction testFunc = testFunctions[i];

      print("\n--- ${testFunc.name} ---\n");
      newTestWave(tester, CPUTimerFreq);
      testFunc.func(tester);
    }
  }
}
```

For a reference to the API, see the [documentation](/doc/api/repetition_tester/repetition_tester-library.html).

## Output Explanation
Here is an example output.

Each label and its profiling data is printed in the ascending order of their
`uid`. The number in the square brackets (e.g `[2]`) represents the number of
times that block has been profiled. So `LabelB1` was profiled twice. The
percentage in the parentheses (e.g `(1.23%)`) is the percentage of the total
time in that particular block. So for `1.23%` of `76.20ms`, the block with label
`LabelA` was being executed. If the block has children, like if `LabelB` has a
child `LabelB1`, then there are two percentages. One of the percentage is the
percentage in that block without the children (`15%`), and the other percentage
is with the children (`92.51%`). The number before the parentheses (e.g `16408`
for `LabelA`) is the number of elapsed ticks in that block.

```sh
I/flutter (20848): Total time: 76.20ms (CPU freq 2.6e+7)
I/flutter (20848):   LabelA[1]: 16408 (1.23%)
I/flutter (20848):   LabelB[1]: 1234123 (15%, 92.51% w/children)
I/flutter (20848):   LabelB1[2]: 956568 (77.51%)
I/flutter (20848):   LabelC: 83511 (6.26%)
```

## Contributing
   I am not actively improving the library as I am no longer using Dart, but I
   will keep my eyes open for pull requests.
   
### Project Structure
    This profiler is not a command-line application, and hence, there is no
    `bin/`. I was lazy, so the `test/` is empty.
    
    `doc/` holds the documentation, generated by `dart doc .`.
    
    `lib/` has:
    - `dartprofiler.dart`
    - `stubdartprofiler.dart`: A copy of `dartprofiler.dart` but with the bulk
    of implementation removed.
    - `platform_metrics.dart`: Internal, a thin layer of abstraction for the
    profiler to talk to the underlying platform.
    - `repetition_tester.dart`
    
    `dartprofiler_library/` holds the c++ code for Dart FFI. It's for library
    users to copy into the root directory of their app. 
    

### Using Classes as Structs
    Methods aren't used even though the data definitions are defined with
    classes. This isn't a political statement against object-oriented
    programming. I happen to find it easier to reason about the program when
    there is a clear separation between data and code that acts on them. Perhaps
    there is a way to blur that line in a productive way while maintaining the
    minimal overhead, but I haven't bothered with it.

### Disadvantages & Room for Improvements

    - You need manually track the `uid`. The printing at the the results
    associated with `uid` in ascending order.
    - As of now, there can only be 16 uids (0 - 15). You can have more by
    changing the constant in `lib/dartprofiler.dart`. The idea is that all the
    memory is allocated before the profiling begins. 
    - Calling into C++ is not as cheap and uninstrusive as calling
      inlined-assembly in C++. As far as I am aware, currently, there is no way of getting
      around this.
    - You need to specify both the start and end, it would be nice to just say
      that you would like to treat an entire block as a zone. Dart has recently
      introduced [macros](https://dart.dev/language/macros), perhaps it's
      possible to do that now?
    - Every variant of dartprofiler requires you to copy from `dartprofiler`,
      creating multiple sources of truth. For example, `stubdartprofiler`
      clearly has a lot of overlap with `dartprofiler`. It would be nice if
      there was a way to add compiler flags to add/remove certain parts of the
      profiler, or a way to parameterize over with 0 runtime costs.
    - Getting the baseline performance with `stubdartprofiler` requires you to
      actually modify the code, which is tedious and error-prone. Moreover,
      requiring to maintain `stubdartprofiler` which is just a copy of
      `dartprofiler` with many things removed is tedious. Furthermore,
      some of the lines of code for the dart profiler are actually still
      executed. Ideally, there should be a way to use a macro compile a version
      of the code without the implementation, instead of having to resort to an
      alternate library with empty implementations.
    - The documentation is automatically generated by `dart doc .`, and it may
      include documentation on things that the library user don't need to know
      about. For instance, it exposes the fields of `ProfileBlock` when the
      library user does not, and should not, know about them.
