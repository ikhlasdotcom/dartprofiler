import 'package:dartprofiler/platform_metrics.dart';

// If you get a list index out of bounds error, increase the list length here.
const anchorsListLength = 16;
class GlobalProfiler {
  static int startTick = 0;
  static int endTick = 0;
  static final List<Anchor> anchors = List<Anchor>.generate(anchorsListLength, (_) => Anchor());
  static int? parentAnchorIndex;
}

class Anchor {
  String label = '';
  int exclusiveElapsedTicks = 0;
  int inclusiveElapsedTicks = 0;
  int hitCount = 0;
}

typedef ProfileBlock = ({
    String label,
    int anchorIndex,
    int? parentAnchorIndex,
    int startTick,
    int oldRootElapsedTicks
});

// Marks the start of the program. Anchors created before a beginProfile() call will have inaccurate numbers.
void beginProfile() {
  initializePlatformMetrics();
  GlobalProfiler.startTick = readCPUTimer();
}

void endAndPrintProfile() {
  void printTimeElapsed(int totalCPUElapsed, Anchor anchor) {
    double percentageExclusive = 100 * (anchor.exclusiveElapsedTicks / totalCPUElapsed);

    if (anchor.exclusiveElapsedTicks != anchor.inclusiveElapsedTicks) {
      double percentageInclusive = 100 * (anchor.inclusiveElapsedTicks / totalCPUElapsed);
      print('  ${anchor.label}[${anchor.hitCount}]: ${anchor.exclusiveElapsedTicks} (${percentageExclusive.toStringAsPrecision(4)}%, ${percentageInclusive.toStringAsPrecision(4)}% w/children)');
    } else {
      print('  ${anchor.label}[${anchor.hitCount}]: ${anchor.exclusiveElapsedTicks} (${percentageExclusive.toStringAsPrecision(4)}%)');
    }
  }
  
  GlobalProfiler.endTick = readCPUTimer();
  double cpuFreq = estimateCPUTimerFreq();

  int totalCPUElapsed = GlobalProfiler.endTick - GlobalProfiler.startTick;

  if (cpuFreq > 0) {
    print('Total time: ${(1000 * totalCPUElapsed / cpuFreq).toStringAsPrecision(4)}ms (CPU freq ${cpuFreq.toStringAsPrecision(2)})');
  }

  for (final anchor in GlobalProfiler.anchors) {
    if (anchor.exclusiveElapsedTicks > 0) {
      printTimeElapsed(totalCPUElapsed, anchor);
    }
  }
}

const s = markStart;
ProfileBlock markStart(String label, int uid) {
  final parentAnchorIndex = GlobalProfiler.parentAnchorIndex;
  GlobalProfiler.parentAnchorIndex = uid;
  return (
    label: label,
    anchorIndex: uid,
    parentAnchorIndex: parentAnchorIndex,
    startTick: readCPUTimer(),
    oldRootElapsedTicks: GlobalProfiler.anchors[uid].inclusiveElapsedTicks
  );
}

const e = markEnd;
void markEnd(ProfileBlock? block) {
  final (:label, :anchorIndex, :parentAnchorIndex, :startTick, :oldRootElapsedTicks) = block!;
  final newElapsedTicks = readCPUTimer() - startTick;

  final Anchor anchor = GlobalProfiler.anchors[anchorIndex];

  GlobalProfiler.parentAnchorIndex = parentAnchorIndex;

  if (parentAnchorIndex != null) {
    final Anchor parentAnchor = GlobalProfiler.anchors[parentAnchorIndex];
    parentAnchor.exclusiveElapsedTicks -= newElapsedTicks;
  }

  anchor.label = label;
  anchor.exclusiveElapsedTicks += newElapsedTicks;
  anchor.inclusiveElapsedTicks += newElapsedTicks;
  anchor.hitCount += 1;
}
/*
IWASHERE.
What is eating time?
- readCPUTimer?
  - Test: readCPUTimer VS stopwatch.
  - Test: readCPUTimer with isb vs without.
*/
