import 'package:dartprofiler/platform_metrics.dart';

void Test() {
  print("estimateCPUTimerFreq: ${estimateCPUTimerFreq()}");
  final double cpuFreq = estimateCPUTimerFreq();

  const int iterations = 1000000;

  // Test RDTSC speed.

  final int rdtscStart = readCPUTimer();

  final int rdtscActualStart = readCPUTimer();
  for (int i = 0; i < iterations; i++) {
    readCPUTimer();
  }

  final int rdtscEnd = readCPUTimer();


  // Test stopwatch speed.

  final Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  final int stopwatchStart = readCPUTimer();

  final int stopwatchActualStart = stopwatch.elapsedTicks;
  for (int i = 0; i < iterations; i++) {
    stopwatch.elapsedTicks;
  }

  final int stopwatchEnd = readCPUTimer();

  // In summary

  final rdtscDuration = rdtscEnd - rdtscStart;
  final stopwatchDuration = stopwatchEnd - stopwatchStart;

  final rdtscDurationS = rdtscDuration / cpuFreq * 1000;
  final stopwatchDurationS = stopwatchDuration / cpuFreq * 1000;

  print("rdtsc: ${rdtscDuration} (${rdtscDurationS}ms)");
  print("stopwatch: ${stopwatchDuration} (${stopwatchDurationS}ms)");
}
