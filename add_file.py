import sys
from pbxproj import XcodeProject

project = XcodeProject.load("LongScreenShot.xcodeproj/project.pbxproj")
# Adjust path as necessary, perhaps "LongScreenShot" group
project.add_file("LongScreenShot/EditViewController.swift", force=False)
project.save()
print("Added EditViewController.swift")
