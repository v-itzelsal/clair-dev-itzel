# Clair Dev
This sample app loads a model exported from Teachable Machine. 
It loads a simple screen to test the model using images from the phone's album.

Steps I followed...

- pubspec.yaml
	1. Dependencies
		- tflite: any
 		- image_picker: ^0.6.7+2. (Look for latest version on flutter’s doc)

	2. Assets
		- Uncomment assets under flutter:
		- Add - assets/

- iOS Deployment

	1. Install pods 
		- sudo gem install cocoapods
		- pod setup

	2. Modify podfile
		- Uncomment second line
		- platform :ios, '9.0'

	3. Tflite
		- Runner -> workspace file -> targets -> build settings -> compile source as: Objective-C++

	4. Permissions for image picker/microphone/camera
		- iOS -> Runner folder -> info.plist
		```
		<key>NSPhotoLibraryUsageDescription</key>
		<string>This app requires permission to access photo library</string>
		<key>NSCameraUsageDescription</key>
		<string>This app requires permission to access camera</string>
		<key>NSMicrophoneUsageDescription</key>
		<string>This app requires permission to access microphone</string>
		```
		

- Android
	1. app -> build grade
		```
		android {
			…
			aaptOptions {
        			noCompress "tflite"
        			noCompress "lite"
    			}
		}
		```
	
