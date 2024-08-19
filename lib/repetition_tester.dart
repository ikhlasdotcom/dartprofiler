import 'dart:io';
import 'package:dartprofiler/platform_metrics.dart';

enum TestMode {
  Uninitialized,
  Testing,
  Completed,
  Error
}

enum RepetitionValueType {
  TestCount,
  CPUTimer,
  MemPageFaults,

  Count
}

class RepetitionValue {
  List<int> e = List<int>.filled(RepetitionValueType.Count.index, 0);
}

class RepetitionTestResults {
  RepetitionValue total = RepetitionValue();
  RepetitionValue max = RepetitionValue();
  RepetitionValue min = RepetitionValue();
}

class RepetitionTester {
  double CPUTimerFreq = 0;
  int tryForTime = 0;
  int testsStartedAt = 0;

  TestMode mode = TestMode.Uninitialized;
  bool printNewMinimums = false;
  int openBlockCount = 0;
  int closeBlockCount = 0;
  
  RepetitionValue accumulatedOnThisTest = RepetitionValue();
  RepetitionTestResults results = RepetitionTestResults();
}

void newTestWave(RepetitionTester tester, double CPUTimerFreq, [int secondsToTry = 10]) {
  switch (tester.mode) {
    case TestMode.Uninitialized:
    tester.mode = TestMode.Testing;
    tester.CPUTimerFreq = CPUTimerFreq;
    tester.printNewMinimums = true;
    tester.results.min.e[RepetitionValueType.CPUTimer.index] = double.maxFinite.toInt();
    break;
    case TestMode.Completed:
    tester.mode = TestMode.Testing;

    if (tester.CPUTimerFreq != CPUTimerFreq) {
      error(tester, "CPU frequency changed, tester ${tester.CPUTimerFreq}, argument ${CPUTimerFreq}.");
    }
    break;
    default:
    // Do nothing.
  }

  tester.tryForTime = (secondsToTry * CPUTimerFreq).round();
  tester.testsStartedAt = readCPUTimer();
}

void beginTime(RepetitionTester tester) {
  tester.openBlockCount++;

  RepetitionValue accumulated = tester.accumulatedOnThisTest;
  accumulated.e[RepetitionValueType.MemPageFaults.index] -= readOSPageFaultCount();
  accumulated.e[RepetitionValueType.CPUTimer.index] -= readCPUTimer().round();
}

void endTime(RepetitionTester tester) {
  RepetitionValue accumulated = tester.accumulatedOnThisTest;
  accumulated.e[RepetitionValueType.CPUTimer.index] += readCPUTimer().round();
  accumulated.e[RepetitionValueType.MemPageFaults.index] += readOSPageFaultCount();

  tester.closeBlockCount++;
}

bool isTesting(RepetitionTester tester) {
  if (tester.mode == TestMode.Testing) {
    RepetitionValue accumulated = tester.accumulatedOnThisTest;
    int currentTime = readCPUTimer();

    if (tester.openBlockCount > 0) {
      if (tester.openBlockCount != tester.closeBlockCount) {
        error(tester, "Unbalanced beginTime/endTime. (${tester.openBlockCount}/${tester.closeBlockCount})");
      }

      if (tester.mode == TestMode.Testing) {
        RepetitionTestResults results = tester.results;

        accumulated.e[RepetitionValueType.TestCount.index] = 1;
        for (var i = 0; i < accumulated.e.length; i++) {
          results.total.e[i] += accumulated.e[i];
        }
        
        if (results.max.e[RepetitionValueType.CPUTimer.index] < accumulated.e[RepetitionValueType.CPUTimer.index]) {
          results.max = accumulated;
        }

        if (results.min.e[RepetitionValueType.CPUTimer.index] > accumulated.e[RepetitionValueType.CPUTimer.index]) {
          results.min = accumulated;

          tester.testsStartedAt = currentTime;

          if (tester.printNewMinimums) {
            printValue("Min", results.min, tester.CPUTimerFreq);
          }
        }

        tester.openBlockCount = 0;
        tester.closeBlockCount = 0;
        tester.accumulatedOnThisTest = RepetitionValue();
      }
    }

    if ((currentTime - tester.testsStartedAt) > tester.tryForTime) {
      tester.mode = TestMode.Completed;

      print("");
      printResults(tester.results, tester.CPUTimerFreq);
    }
  }

  bool result = (tester.mode == TestMode.Testing);
  return result;
}

void error(RepetitionTester tester, String message) {
  tester.mode = TestMode.Error;
  print("ERROR: ${message}");
}

void printValue(String label, RepetitionValue value, double CPUTimerFreq) {
  int testCount = value.e[RepetitionValueType.TestCount.index];
  int divisor = testCount > 0 ? testCount : 1;

  // For the average.
  List<double> e = List<double>.filled(RepetitionValueType.Count.index, 0);
  for (int i = 0; i < RepetitionValueType.Count.index; i++) {
    e[i] = value.e[i] / divisor;
  }

  final StringBuffer toPrint = StringBuffer();

  toPrint.write("${label}: ${e[RepetitionValueType.CPUTimer.index].round()}");

  if (CPUTimerFreq > 0) {
    double seconds = secondsFromCPUTime(e[RepetitionValueType.CPUTimer.index], CPUTimerFreq);
    toPrint.write(" (${seconds.toStringAsFixed(2)}ms)");
  }

  if (e[RepetitionValueType.MemPageFaults.index] > 0) {
    toPrint.write(" PF: ${e[RepetitionValueType.MemPageFaults.index]}");
  }

  print(toPrint);
}

double secondsFromCPUTime(double CPUTime, double CPUTimerFreq) {
  double result = 0;
  if (CPUTimerFreq > 0) {
    result = (CPUTime / CPUTimerFreq);
  }
  return result;
}

void printResults(RepetitionTestResults results, double CPUTimerFreq) {
  printValue("Min", results.min, CPUTimerFreq);
  printValue("Max", results.max, CPUTimerFreq);
  printValue("Avg", results.total, CPUTimerFreq);
}
