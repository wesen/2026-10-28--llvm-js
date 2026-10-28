# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

add_hermes_library(hermesSHBackend
  LoweringPasses.h
  LowerCalls.cpp
  LoadConstants.cpp
  RecreateCheapValues.cpp
  LowerNanBoxedUnionNarrowT.cpp
  PeepholeLowering.cpp
  SH.cpp
  LLVMNative/LLVMBackend.cpp
  SHRegAlloc.cpp SHRegAlloc.h
  LineDirectiveEmitter.cpp LineDirectiveEmitter.h
  LINK_OBJLIBS
  hermesBackend
  hermesInst
  hermesSourceMap
  hermesAST
)

# The bridge is compiled once for a runtime configuration. JavaScript modules
# emitted by the LLVM backend link against it without generating or parsing C.
add_library(shllvm_runtime_obj OBJECT
  LLVMNative/runtime.c
  LLVMNative/value_extensions.c)
set_target_properties(shllvm_runtime_obj PROPERTIES
  POSITION_INDEPENDENT_CODE ON)
if(NOT MSVC)
  # Hermes hides implementation symbols globally, but these functions form the
  # public ABI resolved by separately compiled LLVM modules and lli.
  target_compile_options(shllvm_runtime_obj PRIVATE -fvisibility=default)
endif()

add_library(shllvm_runtime STATIC $<TARGET_OBJECTS:shllvm_runtime_obj>)
set_target_properties(shllvm_runtime PROPERTIES
  ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib")

add_library(shllvm_runtime_shared SHARED
  $<TARGET_OBJECTS:shllvm_runtime_obj>)
set_target_properties(shllvm_runtime_shared PROPERTIES
  OUTPUT_NAME shllvm_runtime
  WINDOWS_EXPORT_ALL_SYMBOLS ON
  LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/lib")
target_link_libraries(shllvm_runtime_shared PRIVATE
  hermesvm shermes_console)
