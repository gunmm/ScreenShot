import sys
import re

project_path = "LongScreenShot.xcodeproj/project.pbxproj"

try:
    with open(project_path, 'r') as f:
        content = f.read()
except FileNotFoundError:
    print(f"Error: {project_path} not found")
    sys.exit(1)

# 1. Find the target "LongScreenShot"
target_match = re.search(r'([0-9A-F]+) /\* LongScreenShot \*/ = \{.*?isa = PBXNativeTarget.*?\};', content, re.DOTALL)
if not target_match:
    print("Target 'LongScreenShot' not found")
    sys.exit(1)

target_id = target_match.group(1)
print(f"Found Target ID: {target_id}")

# 2. Find the build phases for this target
target_block_match = re.search(re.escape(target_id) + r' /\* LongScreenShot \*/ = \{(.*?)\};', content, re.DOTALL)
target_block = target_block_match.group(1)

build_phases_match = re.search(r'buildPhases = \((.*?)\);', target_block, re.DOTALL)
build_phases_ids = [x.strip().split()[0] for x in build_phases_match.group(1).split(',')] if build_phases_match else []

# 3. Find the Sources Build Phase
sources_phase_id = None
for pid in build_phases_ids:
    # Check if this phase is a PBXSourcesBuildPhase
    phase_match = re.search(re.escape(pid) + r' /\* Sources \*/ = \{.*?isa = PBXSourcesBuildPhase.*?\};', content, re.DOTALL)
    if phase_match:
        sources_phase_id = pid
        break

if not sources_phase_id:
    print("Sources Build Phase not found")
    sys.exit(1)

print(f"Found Sources Build Phase ID: {sources_phase_id}")

# 4. Get files in Sources Build Phase
phase_block_match = re.search(re.escape(sources_phase_id) + r' /\* Sources \*/ = \{(.*?)\};', content, re.DOTALL)
phase_block = phase_block_match.group(1)
files_match = re.search(r'files = \((.*?)\);', phase_block, re.DOTALL)
file_ids = [x.strip().split()[0] for x in files_match.group(1).split(',')] if files_match else []

# 5. Check if Test.m is in the file list
# We need to find the PBXBuildFile entry for Test.m
# First find file ref for Test.m
test_m_ref_match = re.search(r'([0-9A-F]+) /\* Test.m \*/ = \{isa = PBXFileReference', content)
if not test_m_ref_match:
    print("Test.m file reference not found in project")
    sys.exit(1)

test_m_ref_id = test_m_ref_match.group(1)
print(f"Found Test.m File Ref ID: {test_m_ref_id}")

# Now check if any build file points to this file ref
found = False
for fid in file_ids:
    # Find PBXBuildFile definition
    # 9A... /* Test.m in Sources */ = {isa = PBXBuildFile; fileRef = 9A... /* Test.m */; };
    build_file_match = re.search(re.escape(fid) + r'.*?isa = PBXBuildFile; fileRef = ' + re.escape(test_m_ref_id), content, re.DOTALL)
    if build_file_match:
        found = True
        break

if found:
    print("SUCCESS: Test.m is in the Sources Build Phase of LongScreenShot")
else:
    print("FAILURE: Test.m is NOT in the Sources Build Phase of LongScreenShot")

