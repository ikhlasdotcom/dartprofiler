// A replica of stubdartprofiler.dart that only measures total run time and nothing else.

import 'package:dartprofiler/platform_metrics.dart';

class GlobalProfiler {
  static int startTick = 0;
  static int endTick = 0;
}

typedef ProfileBlock = ();

// Marks the start of the program. Anchors created before a beginProfile() call will have inaccurate numbers.
void beginProfile() {
  GlobalProfiler.startTick = readCPUTimer();
}

void endAndPrintProfile() {
  GlobalProfiler.endTick = readCPUTimer();
  double cpuFreq = estimateCPUTimerFreq();

  int totalCPUElapsed = GlobalProfiler.endTick - GlobalProfiler.startTick;

  if (cpuFreq > 0) {
    print('Total time: ${(1000 * totalCPUElapsed / cpuFreq).toStringAsPrecision(4)}ms (CPU freq ${cpuFreq.toStringAsPrecision(2)})');
  }
}

ProfileBlock? markStart(String label, int uid) {
  return null;
}

void markEnd(ProfileBlock? block) {
}
