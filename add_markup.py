import sys
from pbxproj import XcodeProject

project = XcodeProject.load("LongScreenShot.xcodeproj/project.pbxproj")
project.add_file("LongScreenShot/MarkupViewController.swift", force=False)
project.save()
print("Added MarkupViewController.swift")
