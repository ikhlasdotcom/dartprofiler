cmake_minimum_required(VERSION 3.10)
project(ffi_dart VERSION 1.0)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")

# Add your source file
set(SOURCES
    ./libdartprofiler.cpp
)

# Add your library
add_library(dartprofiler SHARED ${SOURCES})
