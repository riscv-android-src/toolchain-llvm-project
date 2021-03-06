#
# Copyright (C) 2016 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH := $(call my-dir)

libunwind_src_files := \
    src/libunwind.cpp \
    src/Unwind-EHABI.cpp \
    src/Unwind-sjlj.c \
    src/UnwindLevel1.c \
    src/UnwindLevel1-gcc-ext.c \
    src/UnwindRegistersRestore.S \
    src/UnwindRegistersSave.S \

ifneq (,$(filter armeabi%,$(TARGET_ARCH_ABI)))
    use_llvm_unwinder := true
else
    use_llvm_unwinder := false
endif

ifneq ($(LIBCXX_FORCE_REBUILD),true) # Using prebuilt

ifeq ($(use_llvm_unwinder),true)
include $(CLEAR_VARS)
LOCAL_MODULE := libunwind
LOCAL_SRC_FILES := ../llvm-libc++/libs/$(TARGET_ARCH_ABI)/$(LOCAL_MODULE)$(TARGET_LIB_EXTENSION)
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include

ifeq ($(NDK_PLATFORM_NEEDS_ANDROID_SUPPORT),true)
    LOCAL_STATIC_LIBRARIES := android_support
endif
include $(PREBUILT_STATIC_LIBRARY)
endif

else # Building

include $(CLEAR_VARS)
LOCAL_MODULE := libunwind
LOCAL_SRC_FILES := $(libunwind_src_files)
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include
LOCAL_CFLAGS := \
    -D__STDC_FORMAT_MACROS \
    -D_LIBUNWIND_USE_DLADDR=0 \
    -D_LIBUNWIND_IS_NATIVE_ONLY \

LOCAL_CPPFLAGS := -std=c++11
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include
LOCAL_ARM_NEON := false

ifeq ($(NDK_PLATFORM_NEEDS_ANDROID_SUPPORT),true)
    LOCAL_STATIC_LIBRARIES := android_support
endif
include $(BUILD_STATIC_LIBRARY)

endif # Prebuilt/building

$(call import-module, android/support)
