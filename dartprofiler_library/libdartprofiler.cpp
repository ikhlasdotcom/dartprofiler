#if __ANDROID__
#elif _WIN32
#include <intrin.h>
#else
#include <x86intrin.h>
#endif

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

#include <stdint.h>
#include <sys/resource.h>

extern "C"
{
  EXPORT uint64_t rdtsc()
  {
    #if __ANDROID__
    uint64_t result;
    asm volatile (
        "isb\n\t"                           // Instruction Synchronization Barrier
        "mrs %0, cntvct_el0\n\t"            // Read counter-timer virtual count
        : "=r" (result)                     // Output operand
        :                                   // No input operands
        : "memory"                          // Clobbered registers
    );
    return result;
    #else
    // If on ARM, need to replace __rdtsc with one of their performance
    // counter instructions.
    return __rdtsc();
    #endif
  }

  EXPORT uint64_t cntfrq()
  {
    uint64_t result;
    asm volatile (
      "mrs %0, cntfrq_el0"
      : "=r" (result)
      :
      : "memory"
    );
    return result;
  }
  
  EXPORT uint64_t readOSPageFaultCount()
  {
    // Implementation from Computer Enhance.
    struct rusage usage = {};
    getrusage(RUSAGE_SELF, &usage);
    
    // ru_minflt  the number of page faults serviced without any I/O activity.
    // ru_majflt  the number of page faults serviced that required I/O activity.
    uint64_t result = usage.ru_minflt + usage.ru_majflt;
    
    return result;
  }
}

