cmake_minimum_required(VERSION 3.14)
project(stargazer LANGUAGES CXX)

set(BINARY_NAME "stargazer")

cmake_policy(VERSION 3.14...3.25)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(flutter/ephemeral/.cmake/flutter_windows.cmake OPTIONAL)

if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
endif()

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release")
endif()

add_executable(${BINARY_NAME} WIN32
  "flutter/ephemeral/.plugin_symlinks/path_provider_windows/windows/path_provider_windows_plugin.cpp"
  runner/main.cpp
  runner/flutter_window.cpp
  runner/utils.cpp
  runner/win32_window.cpp
  runner/window_configuration.cpp
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "${FLUTTER_LIBRARY}")

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/flutter/ephemeral/.plugin_symlinks/path_provider_windows/windows" "${CMAKE_CURRENT_BINARY_DIR}/path_provider_windows")

set_target_properties(${BINARY_NAME} PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/runner"
)
