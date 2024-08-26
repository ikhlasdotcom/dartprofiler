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

/// Marks the start time of the profiling.
///
/// Call this first before any profiling. Anchors created before this call will
/// have inaccurate numbers.
void beginProfile() {
  initializePlatformMetrics();
  GlobalProfiler.startTick = readCPUTimer();
}

/// Marks the end of the profiling, and prints the results via [print].
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

/// Marks the start time of a profile block with the given [uid] with the given
/// [label], and returns it.
///
/// @param label The human-readable name associated with the anchor when printed.
/// @param uid The unique integer identifier associated with profile block.
/// @returns The profile block associated with the given [uid].
///
/// You have to call `markEnd` on the returned profile block at some point so
/// that the data can be printed at the end. Calling [markStart] with the same
/// [uid] multiple times is undefined behaviour.
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
const s = markStart;

/// Marks the end time of the given profile [block].
///
/// @param block The profile block to mark the end of.
///
/// Only call this once per profile block. Calling it more than once is
/// undefined behaviour.
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
const e = markEnd;
