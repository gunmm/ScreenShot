import re
import sys

project_path = "LongScreenShot.xcodeproj/project.pbxproj"
bridging_header_path = "LongScreenShot/Shared/LongScreenShot-Bridging-Header.h"

with open(project_path, 'r') as f:
    content = f.read()

# 1. Find ScreenCapture Target Key
# Search for the target definition by name
# Use [^}] to ensure we find 'isa = PBXNativeTarget' inside the SAME block
target_pattern = r'([0-9A-F]{24}) /\* ScreenCapture \*/ = \{[^}]*isa = PBXNativeTarget'
target_match = re.search(target_pattern, content, re.DOTALL)
if not target_match:
    print("Error: Could not find ScreenCapture target")
    sys.exit(1)

target_id = target_match.group(1)
print(f"Target ID: {target_id}")

# 2. Find Build Configuration List ID in the target definition
# Need to search within the target block
target_block_pattern = re.escape(target_id) + r' /\* ScreenCapture \*/ = \{(.*?)\};'
target_block_match = re.search(target_block_pattern, content, re.DOTALL)
if not target_block_match:
    print("Error: Could not parse ScreenCapture target block")
    sys.exit(1)

target_block = target_block_match.group(1)
# print(f"DEBUG: Target Block: {target_block[:200]}...") 

config_list_match = re.search(r'buildConfigurationList\s*=\s*([0-9A-F]{24})', target_block)
if not config_list_match:
    print(f"Error: Could not find buildConfigurationList in block:\n{target_block}")
    sys.exit(1)

config_list_id = config_list_match.group(1)
print(f"Config List ID: {config_list_id}")

# 3. Find Build Configurations in the list
# Anchor to start of line to avoid matching the usage of the ID
config_list_block_pattern = r'^\s*' + re.escape(config_list_id) + r'.*?=\s*\{(.*?)\};'
config_list_block_match = re.search(config_list_block_pattern, content, re.DOTALL | re.MULTILINE)
if not config_list_block_match:
    print("Error: Could not find configuration list block")
    sys.exit(1)

config_list_block = config_list_block_match.group(1)
build_configs_match = re.search(r'buildConfigurations = \((.*?)\);', config_list_block, re.DOTALL)
if not build_configs_match:
    print("Error: Could not find buildConfigurations")
    sys.exit(1)

build_config_ids = [x.strip().split()[0] for x in build_configs_match.group(1).split(',') if x.strip()]
print(f"Build Config IDs: {build_config_ids}")

# 4. Update each Build Configuration
new_content = content
changes_made = 0

for config_id in build_config_ids:
    print(f"Processing Config ID: {config_id}")
    # Find the configuration block
    # It looks like: ID /* Debug */ = { ... buildSettings = { ... }; ... };
    
    # We construct a regex to capture the buildSettings block content specifically
    # Be careful not to match too greedily. 
    # Structure: ID ... = { ... buildSettings = { CONTENT }; ... };
    
    config_pattern = re.escape(config_id) + r'.*? = \{.*?buildSettings = \{(.*?)\};'
    config_match = re.search(config_pattern, new_content, re.DOTALL)
    
    if config_match:
        settings_content = config_match.group(1)
        
        # Check if SWIFT_OBJC_BRIDGING_HEADER exists
        if "SWIFT_OBJC_BRIDGING_HEADER" in settings_content:
             # It likely exists but is empty or wrong? Regex replace it.
             # If it is empty string "", replace it.
             print("  Header setting exists, updating...")
             updated_settings = re.sub(
                 r'SWIFT_OBJC_BRIDGING_HEADER = ".*?";', 
                 f'SWIFT_OBJC_BRIDGING_HEADER = "{bridging_header_path}";', 
                 settings_content
             )
             if updated_settings == settings_content:
                 # Try matching without quotes if it was somehow different
                 updated_settings = re.sub(
                     r'SWIFT_OBJC_BRIDGING_HEADER = .*?;', 
                     f'SWIFT_OBJC_BRIDGING_HEADER = "{bridging_header_path}";', 
                     settings_content
                 )
        else:
            print("  Header setting missing, adding...")
            # Add it to the end of settings
            updated_settings = settings_content + f'\n\t\t\t\tSWIFT_OBJC_BRIDGING_HEADER = "{bridging_header_path}";'

        # Now replace the settings block in the file content
        # We need to be careful to replace only this occurrence.
        # Construct the full string to replace
        
        # Actually, using string replacement on the whole file with a unique match is safer.
        full_match_string = config_match.group(0)
        new_full_match_string = full_match_string.replace(settings_content, updated_settings)
        
        new_content = new_content.replace(full_match_string, new_full_match_string)
        changes_made += 1

if changes_made > 0:
    with open(project_path, 'w') as f:
        f.write(new_content)
    print("Successfully updated project file.")
else:
    print("No changes made.")
