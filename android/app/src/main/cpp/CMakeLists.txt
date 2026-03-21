cmake_minimum_required(VERSION 3.10)
project(docsmind_native)

# This SHARED library forces the Android Gradle Plugin to package
# libc++_shared.so into the APK, which is required by libopencv_java4.so
add_library(docsmind_native SHARED dummy.cpp)
