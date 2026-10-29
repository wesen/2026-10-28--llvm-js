# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# Define targets for the C++ console bindings. We define both a static and a
# dynamic library, so they can be linked the same way as hermesvm.
set(HERMES_ENABLE_EH ON)
add_library(shermes_console SHARED ConsoleBindings.cpp)
target_link_libraries(shermes_console PRIVATE hermesvm jsi)

add_library(shermes_console_a STATIC ConsoleBindings.cpp)
# Add hermesvm as a dependency so headers are available, even though we aren't
# actually linking anything here.
target_link_libraries(shermes_console_a PRIVATE hermesvm_a)
set(HERMES_ENABLE_EH OFF)

set(SHERMES_CC "${CMAKE_C_COMPILER}" CACHE STRING "C compiler to invoke")
set(SHERMES_CC_SYSCFLAGS "" CACHE STRING "C compiler system flags")
set(SHERMES_CC_SYSLDFLAGS "" CACHE STRING "C compiler system linker flags")
if(CMAKE_HOST_WIN32)
  set(SHERMES_CC_PATH_SEPARATOR ";")
else()
  set(SHERMES_CC_PATH_SEPARATOR ":")
endif()

set(SHERMES_CC_INCLUDE_PATH_DEFAULT_ENTRIES
  "${PROJECT_BINARY_DIR}/lib/config"
  "${PROJECT_SOURCE_DIR}/include")
list(JOIN SHERMES_CC_INCLUDE_PATH_DEFAULT_ENTRIES
  "${SHERMES_CC_PATH_SEPARATOR}"
  SHERMES_CC_INCLUDE_PATH_DEFAULT)

set(SHERMES_CC_LIB_PATH_DEFAULT_ENTRIES
  "$<TARGET_FILE_DIR:hermesvm>"
  "$<TARGET_FILE_DIR:jsi>"
  "$<TARGET_FILE_DIR:shermes_console>")
list(JOIN SHERMES_CC_LIB_PATH_DEFAULT_ENTRIES
  "${SHERMES_CC_PATH_SEPARATOR}"
  SHERMES_CC_LIB_PATH_DEFAULT)
set(SHERMES_CC_INCLUDE_PATH "${SHERMES_CC_INCLUDE_PATH_DEFAULT}" CACHE STRING
  "Include path when invoking CC")
set(SHERMES_CC_LIB_PATH "${SHERMES_CC_LIB_PATH_DEFAULT}" CACHE STRING
  "Library path when invoking CC")

if (HERMES_ENABLE_ADDRESS_SANITIZER)
  # Leave frame pointers. Allows the fast unwinder to function properly.
  append("-fsanitize=address -fno-omit-frame-pointer" SHERMES_CC_SYSCFLAGS SHERMES_CC_SYSLDFLAGS)
endif()

if (HERMES_ENABLE_UNDEFINED_BEHAVIOR_SANITIZER)
  append("-fsanitize=undefined" SHERMES_CC_SYSCFLAGS SHERMES_CC_SYSLDFLAGS)
endif()

file(GENERATE
        OUTPUT $<CONFIG>/config.h
        CONTENT "\
#define SHERMES_CC                    R\"(${SHERMES_CC})\"
#define SHERMES_CC_SYSCFLAGS          R\"(${SHERMES_CC_SYSCFLAGS})\"
#define SHERMES_CC_SYSLDFLAGS         R\"(${SHERMES_CC_SYSLDFLAGS})\"
#define SHERMES_CC_INCLUDE_PATH       R\"(${SHERMES_CC_INCLUDE_PATH})\"
#define SHERMES_CC_LIB_PATH           R\"(${SHERMES_CC_LIB_PATH})\""
        )

include_directories(${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>)

set(SHERMES_LINK_LIBS hermescompiler)
if(NOT WIN32)
  list(APPEND SHERMES_LINK_LIBS dl)
endif()

add_hermes_tool(shermes
  shermes.cpp
  ParseJSFile.cpp ParseJSFile.h
  compile.cpp compile.h
  LINK_LIBS ${SHERMES_LINK_LIBS})

# The compiler is used as part of the build of the VM.
# During cross-compilation, the compiler needs to be built for the host system,
# then used to build the VM for the target system.
# Namespace added to avoid clashing the imported binary with the target binary.
export(TARGETS shermes APPEND FILE ${CMAKE_BINARY_DIR}/ImportHostCompilers.cmake NAMESPACE imported-)

# A target building both the shermes compiler and the libraries potentially
# needed for linking of a compiled binary.
# Note that it is not a given that we always want to link against these
# libraries, we might want to link against release libraries from a debug
# compiler, so this is not the default for shermes.
add_custom_target(shermes-dep)
add_dependencies(shermes-dep shermes hermesvm_a hermesvmlean_a hermesvm hermesvmlean shermes_console shermes_console_a)

# AOT emission stays independent of installed LLVM development libraries.
option(HERMES_BUILD_LLVM_JIT "Build the in-process baseline LLVM JIT" OFF)
if(HERMES_BUILD_LLVM_JIT)
  # LLVMConfig imports tools named FileCheck/count/not, colliding with llvh.
  # Discover only the installed shared library and headers through llvm-config.
  find_program(SHLLVM_CONFIG NAMES llvm-config-18 REQUIRED)
  execute_process(COMMAND ${SHLLVM_CONFIG} --version OUTPUT_VARIABLE SHLLVM_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL ANY)
  if(NOT SHLLVM_VERSION MATCHES "^18\\.")
    message(FATAL_ERROR "The baseline JIT requires LLVM 18")
  endif()
  execute_process(COMMAND ${SHLLVM_CONFIG} --includedir OUTPUT_VARIABLE SHLLVM_INCLUDE OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL ANY)
  execute_process(COMMAND ${SHLLVM_CONFIG} --libdir OUTPUT_VARIABLE SHLLVM_LIBDIR OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL ANY)
  find_library(SHLLVM_LIBRARY NAMES LLVM-18 HINTS ${SHLLVM_LIBDIR} REQUIRED NO_DEFAULT_PATH)
  target_sources(shermes_console PRIVATE JITHost.cpp)
  add_library(shllvm_engine STATIC
    ../../lib/LLVMJIT/Engine.cpp
    ../../lib/LLVMJIT/Frontend.cpp
    ParseJSFile.cpp)
  hermes_update_cxx_flags(shllvm_engine)
  target_include_directories(shllvm_engine PRIVATE ${SHLLVM_INCLUDE} ${CMAKE_CURRENT_SOURCE_DIR})
  target_link_libraries(shllvm_engine PUBLIC hermescompiler shllvm_runtime_shared shermes_console ${SHLLVM_LIBRARY} dl)
  add_executable(shllvm-jit ../shllvm-jit/main.cpp)
  target_link_libraries(shllvm-jit PRIVATE shllvm_engine)
  set_target_properties(shllvm-jit PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")
endif()
if(HERMES_BUILD_LLVM_JIT)
  add_executable(shllvm-jit-test ../../test/LLVMJIT/engine.cpp)
  target_link_libraries(shllvm-jit-test PRIVATE shllvm_engine)
  set_target_properties(shllvm-jit-test PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")
endif()

if(HERMES_BUILD_LLVM_JIT)
  add_executable(shllvm-app-host ../../examples/llvm-apps/persistent-host/main.cpp)
  target_link_libraries(shllvm-app-host PRIVATE shllvm_engine)
  set_target_properties(shllvm-app-host PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/bin")
endif()
