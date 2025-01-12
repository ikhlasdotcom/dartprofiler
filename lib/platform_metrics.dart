import 'dart:ffi' as ffi;

import 'dart:io' show Platform, Directory;
import 'package:path/path.dart' as path;

typedef RdtscFunc = ffi.Uint64 Function();
typedef Rdtsc = int Function();

final Rdtsc rdtsc = (() {
    // We ignore libraryPath for now. We expect the library user to provide the `libdartprofiler.so` file.
    var libraryPath = path.join(Directory.current.path, 'dartprofiler_library',
      'libdartprofiler.so');
    if (Platform.isMacOS) {
      libraryPath = path.join(Directory.current.path, 'dartprofiler_library',
        'libdartprofiler.dylib');
    } else if (Platform.isWindows) {
      libraryPath = path.join(Directory.current.path, 'dartprofiler_library',
        'Debug', 'libdartprofiler.dll');
    }

    final dylib = ffi.DynamicLibrary.open('libdartprofiler.so');

    Rdtsc rdtsc = dylib
    .lookup<ffi.NativeFunction<RdtscFunc>>('rdtsc')
    .asFunction();

    return rdtsc;
})();


typedef ReadOSPageFaultCountFunc = ffi.Uint64 Function();
typedef ReadOSPageFaultCount = int Function();

final ReadOSPageFaultCount cppReadOSPageFaultCount = (() {
    print("Getting from ReadOSPageFaultCount from cpp...");
    final dylib = ffi.DynamicLibrary.open('libdartprofiler.so');

    ReadOSPageFaultCount cppReadOSPageFaultCount = dylib
    .lookup<ffi.NativeFunction<ReadOSPageFaultCountFunc>>('readOSPageFaultCount')
    .asFunction();

    return cppReadOSPageFaultCount;
})();

void initializePlatformMetrics() {
  readCPUTimer();
}

// Assumes Intel for now.
int readCPUTimer() {
  return rdtsc();
}

int readOSPageFaultCount() {
  return cppReadOSPageFaultCount();
}

double estimateCPUTimerFreq() {
  const int millisecondsToWait = 100;

  final int cpuStart = readCPUTimer();
  
  final Stopwatch stopwatch = Stopwatch();
  stopwatch.reset();
  stopwatch.start();

  int osElapsed = 0;

  // Assume of frequency is this value.
  // We could use stopwatch's frequency though.
  const int osFreq = 1000000;
  const osWaitTime = osFreq * millisecondsToWait / 1000;

  while (osElapsed < osWaitTime) {
    osElapsed = stopwatch.elapsedMicroseconds;
  }

  final int cpuEnd = readCPUTimer();
  final int cpuElapsed = cpuEnd - cpuStart;

  double cpuFreq = 0;
  if (osElapsed != 0) {
    cpuFreq = osFreq * cpuElapsed / osElapsed;
  }
  return cpuFreq;
}


typedef CntfrqFunc = ffi.Uint64 Function();
typedef Cntfrq = int Function();

final Cntfrq cntfrq = (() {
    // We ignore libraryPath for now. We expect the library user to provide the `libdartprofiler.so` file.
    var libraryPath = path.join(Directory.current.path, 'dartprofiler_library',
      'libdartprofiler.so');
    if (Platform.isMacOS) {
      libraryPath = path.join(Directory.current.path, 'dartprofiler_library',
        'libdartprofiler.dylib');
    } else if (Platform.isWindows) {
      libraryPath = path.join(Directory.current.path, 'dartprofiler_library',
        'Debug', 'libdartprofiler.dll');
    }

    final dylib = ffi.DynamicLibrary.open('libdartprofiler.so');

    Cntfrq cntfrq = dylib
    .lookup<ffi.NativeFunction<CntfrqFunc>>('cntfrq')
    .asFunction();

    return cntfrq;
})();

// Only available if on ARM chip.
int getCntFrq() {
  return cntfrq();
}

