import os

project_dir = "/Users/Uditya/.gemini/antigravity/scratch/BioSyncWatch"
xcodeproj_dir = os.path.join(project_dir, "BioSync.xcodeproj")
os.makedirs(xcodeproj_dir, exist_ok=True)
schemes_dir = os.path.join(xcodeproj_dir, "xcshareddata", "xcschemes")
os.makedirs(schemes_dir, exist_ok=True)

# Watch Target Stable UUIDs (A1...)
id_watch_app_ref = "A10000000000000000000001"
id_root_group = "A10000000000000000000002"
id_sources_group = "A10000000000000000000003"
id_watch_frameworks_phase = "A10000000000000000000004"
id_main_group = "A10000000000000000000005"
id_products_group = "A10000000000000000000006"
id_watch_target = "A10000000000000000000007"
id_project = "A10000000000000000000008"
id_watch_resources_phase = "A10000000000000000000009"
id_watch_sources_phase = "A1000000000000000000000A"
id_proj_cfg_debug = "A1000000000000000000000B"
id_proj_cfg_release = "A1000000000000000000000C"
id_watch_target_cfg_debug = "A1000000000000000000000D"
id_watch_target_cfg_release = "A1000000000000000000000E"
id_proj_cfg_list = "A1000000000000000000000F"
id_watch_target_cfg_list = "A10000000000000000000010"

# Phone Target Stable UUIDs (B1...)
id_phone_app_ref = "B10000000000000000000001"
id_phone_frameworks_phase = "B10000000000000000000004"
id_phone_target = "B10000000000000000000007"
id_phone_resources_phase = "B10000000000000000000009"
id_phone_sources_phase = "B1000000000000000000000A"
id_phone_target_cfg_debug = "B1000000000000000000000D"
id_phone_target_cfg_release = "B1000000000000000000000E"
id_phone_target_cfg_list = "B10000000000000000000010"

pbxproj_content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 77;
	objects = {{

/* Begin PBXFileReference section */
		{id_watch_app_ref} /* BioSync.app (watchOS) */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BioSync.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{id_phone_app_ref} /* BioSyncPhone.app (iOS) */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BioSyncPhone.app; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
		{id_sources_group} /* Sources */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			path = Sources;
			sourceTree = "<group>";
		}};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
		{id_watch_frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{id_phone_frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{id_main_group} = {{
			isa = PBXGroup;
			children = (
				{id_sources_group} /* Sources */,
				{id_products_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{id_products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{id_watch_app_ref} /* BioSync.app */,
				{id_phone_app_ref} /* BioSyncPhone.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{id_watch_target} /* BioSync (watchOS) */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {id_watch_target_cfg_list} /* Build configuration list for PBXNativeTarget "BioSync" */;
			buildPhases = (
				{id_watch_sources_phase} /* Sources */,
				{id_watch_frameworks_phase} /* Frameworks */,
				{id_watch_resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				{id_sources_group} /* Sources */,
			);
			name = BioSync;
			packageProductDependencies = (
			);
			productName = BioSync;
			productReference = {id_watch_app_ref} /* BioSync.app */;
			productType = "com.apple.product-type.application";
		}};
		{id_phone_target} /* BioSyncPhone (iOS) */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {id_phone_target_cfg_list} /* Build configuration list for PBXNativeTarget "BioSyncPhone" */;
			buildPhases = (
				{id_phone_sources_phase} /* Sources */,
				{id_phone_frameworks_phase} /* Frameworks */,
				{id_phone_resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				{id_sources_group} /* Sources */,
			);
			name = BioSyncPhone;
			packageProductDependencies = (
			);
			productName = BioSyncPhone;
			productReference = {id_phone_app_ref} /* BioSyncPhone.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{id_project} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2660;
				LastUpgradeCheck = 2660;
				TargetAttributes = {{
					{id_watch_target} = {{
						CreatedOnToolsVersion = 26.6;
					}};
					{id_phone_target} = {{
						CreatedOnToolsVersion = 26.6;
					}};
				}};
			}};
			buildConfigurationList = {id_proj_cfg_list} /* Build configuration list for PBXProject "BioSync" */;
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {id_main_group};
			minimizedProjectReferenceProxies = 1;
			preferredProjectObjectVersion = 77;
			productRefGroup = {id_products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{id_watch_target} /* BioSync */,
				{id_phone_target} /* BioSyncPhone */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{id_watch_resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{id_phone_resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{id_watch_sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{id_phone_sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{id_proj_cfg_debug} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				ONLY_ACTIVE_ARCH = YES;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{id_proj_cfg_release} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_OPTIMIZATION_LEVEL = s;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{id_watch_target_cfg_debug} /* Debug (watchOS) */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_ENTITLEMENTS = BioSync.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = P6S2Y272M3;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = BioSync;
				INFOPLIST_KEY_NSHealthShareUsageDescription = "BioSync reads your Heart Rate, HRV, and Sleep to calculate Recovery, Stress, and Sleep scores.";
				INFOPLIST_KEY_NSHealthUpdateUsageDescription = "BioSync records recovery data.";
				INFOPLIST_KEY_WKBackgroundModes = "app-refresh";
				INFOPLIST_KEY_WKWatchOnly = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.uditya.BioSync;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "4";
				WATCHOS_DEPLOYMENT_TARGET = 10.0;
			}};
			name = Debug;
		}};
		{id_watch_target_cfg_release} /* Release (watchOS) */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_ENTITLEMENTS = BioSync.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = P6S2Y272M3;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = BioSync;
				INFOPLIST_KEY_NSHealthShareUsageDescription = "BioSync reads your Heart Rate, HRV, and Sleep to calculate Recovery, Stress, and Sleep scores.";
				INFOPLIST_KEY_NSHealthUpdateUsageDescription = "BioSync records recovery data.";
				INFOPLIST_KEY_WKBackgroundModes = "app-refresh";
				INFOPLIST_KEY_WKWatchOnly = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.uditya.BioSync;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "4";
				WATCHOS_DEPLOYMENT_TARGET = 10.0;
			}};
			name = Release;
		}};
		{id_phone_target_cfg_debug} /* Debug (iOS) */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = BioSync.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = P6S2Y272M3;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = BioSync;
				INFOPLIST_KEY_NSHealthShareUsageDescription = "BioSync reads your Heart Rate, HRV, Sleep, Steps, and Activity to calculate Recovery, Stress, and Biological Age.";
				INFOPLIST_KEY_NSHealthUpdateUsageDescription = "BioSync records recovery data.";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait";
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.uditya.BioSync;
				PRODUCT_NAME = BioSyncPhone;
				SDKROOT = iphoneos;
				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{id_phone_target_cfg_release} /* Release (iOS) */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = BioSync.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = P6S2Y272M3;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = BioSync;
				INFOPLIST_KEY_NSHealthShareUsageDescription = "BioSync reads your Heart Rate, HRV, Sleep, Steps, and Activity to calculate Recovery, Stress, and Biological Age.";
				INFOPLIST_KEY_NSHealthUpdateUsageDescription = "BioSync records recovery data.";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait";
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.uditya.BioSync;
				PRODUCT_NAME = BioSyncPhone;
				SDKROOT = iphoneos;
				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{id_proj_cfg_list} /* Build configuration list for PBXProject "BioSync" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{id_proj_cfg_debug} /* Debug */,
				{id_proj_cfg_release} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{id_watch_target_cfg_list} /* Build configuration list for PBXNativeTarget "BioSync" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{id_watch_target_cfg_debug} /* Debug */,
				{id_watch_target_cfg_release} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{id_phone_target_cfg_list} /* Build configuration list for PBXNativeTarget "BioSyncPhone" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{id_phone_target_cfg_debug} /* Debug */,
				{id_phone_target_cfg_release} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {id_project} /* Project object */;
}}
"""

pbxproj_path = os.path.join(xcodeproj_dir, "project.pbxproj")
with open(pbxproj_path, "w") as f:
    f.write(pbxproj_content)

print("Generated multiplatform BioSync.xcodeproj at:", pbxproj_path)

# Generate BioSync (watchOS) Scheme
watch_scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{id_watch_target}"
               BuildableName = "BioSync.app"
               BlueprintName = "BioSync"
               ReferencedContainer = "container:BioSync.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{id_watch_target}"
            BuildableName = "BioSync.app"
            ReferencedContainer = "container:BioSync.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{id_watch_target}"
            BuildableName = "BioSync.app"
            ReferencedContainer = "container:BioSync.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

watch_scheme_path = os.path.join(schemes_dir, "BioSync.xcscheme")
with open(watch_scheme_path, "w") as f:
    f.write(watch_scheme_content)
print("Wrote watchOS scheme:", watch_scheme_path)

# Generate BioSyncPhone (iOS) Scheme
phone_scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{id_phone_target}"
               BuildableName = "BioSyncPhone.app"
               BlueprintName = "BioSyncPhone"
               ReferencedContainer = "container:BioSync.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{id_phone_target}"
            BuildableName = "BioSyncPhone.app"
            ReferencedContainer = "container:BioSync.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{id_phone_target}"
            BuildableName = "BioSyncPhone.app"
            ReferencedContainer = "container:BioSync.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

phone_scheme_path = os.path.join(schemes_dir, "BioSyncPhone.xcscheme")
with open(phone_scheme_path, "w") as f:
    f.write(phone_scheme_content)
print("Wrote iOS scheme:", phone_scheme_path)
