# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

require "json"

package = JSON.parse(File.read(File.join(__dir__, "..", "..", "package.json")))
version = package['version']

source = { :git => 'https://github.com/facebook/react-native.git' }
if version == '1000.0.0'
  # This is an unpublished version, use the latest commit hash of the react-native repo, which we’re presumably in.
  source[:commit] = `git rev-parse HEAD`.strip if system("git rev-parse --git-dir > /dev/null 2>&1")
else
  source[:tag] = "v#{version}"
end

folly_flags = ' -DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -DFOLLY_CFG_NO_COROUTINES=1 -DFOLLY_HAVE_CLOCK_GETTIME=1'
folly_compiler_flags = folly_flags + ' ' + '-Wno-comma -Wno-shorten-64-to-32'

is_new_arch_enabled = ENV["RCT_NEW_ARCH_ENABLED"] == "1"
use_hermes =  ENV['USE_HERMES'] == nil || ENV['USE_HERMES'] == '1'
use_frameworks = ENV['USE_FRAMEWORKS'] != nil

new_arch_enabled_flag = (is_new_arch_enabled ? " -DRCT_NEW_ARCH_ENABLED" : "")
is_fabric_enabled = is_new_arch_enabled || ENV["RCT_FABRIC_ENABLED"]
fabric_flag = (is_fabric_enabled ? " -DRN_FABRIC_ENABLED" : "")
hermes_flag = (use_hermes ? " -DUSE_HERMES" : "")
other_cflags = "$(inherited)" + folly_flags + new_arch_enabled_flag + fabric_flag + hermes_flag

header_search_paths = [
  "$(PODS_TARGET_SRCROOT)/../../ReactCommon",
  "$(PODS_ROOT)/Headers/Private/React-Core",
  "$(PODS_ROOT)/boost",
  "$(PODS_ROOT)/DoubleConversion",
  "$(PODS_ROOT)/fmt/include",
  "$(PODS_ROOT)/RCT-Folly",
  "${PODS_ROOT}/Headers/Public/FlipperKit",
  "$(PODS_ROOT)/Headers/Public/ReactCommon",
  "$(PODS_ROOT)/Headers/Public/React-RCTFabric",
  "$(PODS_ROOT)/Headers/Private/Yoga",
].concat(use_hermes ? [
  "$(PODS_ROOT)/Headers/Public/React-hermes",
  "$(PODS_ROOT)/Headers/Public/hermes-engine"
] : []).concat(use_frameworks ? [
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-Fabric/React_Fabric.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-Fabric/React_Fabric.framework/Headers/react/renderer/components/view/platform/cxx/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-graphics/React_graphics.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-graphics/React_graphics.framework/Headers/react/renderer/graphics/platform/ios",
  "$(PODS_CONFIGURATION_BUILD_DIR)/ReactCommon/ReactCommon.framework/Headers/react/nativemodule/core",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-NativeModulesApple/React_NativeModulesApple.framework/Headers",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-RuntimeApple/React_RuntimeApple.framework/Headers",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-RuntimeCore/React_RuntimeCore.framework/Headers",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-RCTFabric/RCTFabric.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-utils/React_utils.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-debug/React_debug.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-runtimescheduler/React_runtimescheduler.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-rendererdebug/React_rendererdebug.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-Fabric-macOS/React_Fabric.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-Fabric-macOS/React_Fabric.framework/Headers/react/renderer/components/view/platform/cxx/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-graphics-macOS/React_graphics.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-graphics-macOS/React_graphics.framework/Headers/react/renderer/graphics/platform/ios",
  "$(PODS_CONFIGURATION_BUILD_DIR)/ReactCommon-macOS/ReactCommon.framework/Headers/react/nativemodule/core",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-NativeModulesApple-macOS/React_NativeModulesApple.framework/Headers",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-RuntimeApple-macOS/React_RuntimeApple.framework/Headers",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-RuntimeCore-macOS/React_RuntimeCore.framework/Headers",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-RCTFabric-macOS/RCTFabric.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-utils-macOS/React_utils.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-debug-macOS/React_debug.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-runtimescheduler-macOS/React_runtimescheduler.framework/Headers/",
  "$(PODS_CONFIGURATION_BUILD_DIR)/React-rendererdebug-macOS/React_rendererdebug.framework/Headers/",
] : []).map{|p| "\"#{p}\""}.join(" ")

Pod::Spec.new do |s|
  s.name            = "React-RCTAppDelegate"
  s.version                = version
  s.summary                = "An utility library to simplify common operations for the New Architecture"
  s.homepage               = "https://reactnative.dev/"
  s.documentation_url      = "https://reactnative.dev/"
  s.license                = package["license"]
  s.author                 = "Meta Platforms, Inc. and its affiliates"
  s.platforms              = min_supported_versions
  s.source                 = source
  s.source_files            = "**/*.{c,h,m,mm,S,cpp}"

  # This guard prevent to install the dependencies when we run `pod install` in the old architecture.
  s.compiler_flags = other_cflags
  s.pod_target_xcconfig    = {
    "HEADER_SEARCH_PATHS" => header_search_paths,
    "OTHER_CPLUSPLUSFLAGS" => other_cflags,
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++20",
    "DEFINES_MODULE" => "YES"
  }
  s.user_target_xcconfig   = { "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/Headers/Private/React-Core\""}

  use_hermes = ENV['USE_HERMES'] == nil || ENV['USE_HERMES'] == "1"

  s.dependency "React-Core"
  s.dependency "RCT-Folly"
  s.dependency "RCTRequired"
  s.dependency "RCTTypeSafety"
  s.dependency "ReactCommon/turbomodule/core"
  s.dependency "React-RCTNetwork"
  s.dependency "React-RCTImage"
  s.dependency "React-NativeModulesApple"
  s.dependency "React-CoreModules"
  s.dependency "React-nativeconfig"
  s.dependency "React-runtimescheduler"
  s.dependency "React-RCTFabric"

  if is_new_arch_enabled
    s.dependency "React-RuntimeCore"
    s.dependency "React-RuntimeApple"
    if use_hermes
      s.dependency "React-RuntimeHermes"
    end
  end

  if use_hermes
    s.dependency "React-hermes"
  else
    s.dependency "React-jsc"
  end

  if is_new_arch_enabled
    s.dependency "React-Fabric"
    s.dependency "React-graphics"
    s.dependency "React-utils"
    s.dependency "React-debug"
    s.dependency "React-rendererdebug"

    s.script_phases = {
      :name => "Generate Legacy Components Interop",
      :script => "
WITH_ENVIRONMENT=\"$REACT_NATIVE_PATH/scripts/xcode/with-environment.sh\"
source $WITH_ENVIRONMENT
${NODE_BINARY} ${REACT_NATIVE_PATH}/scripts/codegen/generate-legacy-interop-components.js -p #{ENV['APP_PATH']} -o ${REACT_NATIVE_PATH}/Libraries/AppDelegate
      ",
      :execution_position => :before_compile,
      :input_files => ["#{ENV['APP_PATH']}/react-native.config.js"],
      :output_files => ["${REACT_NATIVE_PATH}/Libraries/AppDelegate/RCTLegacyInteropComponents.mm"],
    }
  end
end
