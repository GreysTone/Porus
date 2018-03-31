# Porus - An iOS App For Road Type Recognition

## Introduction

**Porus** is an client-server for detecting the type of roads. The prediction is based on deep learning and it runs on the server. The client application captures the images and requests prediction service from the server. This idea may be applied to driving assistance system in the future.

This project is the client side application of Porus. It runs on iOS platform. The user interface of Porus is designed to fit 4.7-inch iPhones, so it may look different on other devices.

## System Requirements
### Computer
To build and deploy Porus on your iPhone, you need to have a Mac. It should meet the following requirements:
1. `macOS`, version `>= 10.11.5`.
2. `Xcode`, version `>= 8.2.1`.
3. `Internet` capability. You need Internet to run the server and sign in Apple ID.
4. Valid `Apple ID`. You need to sign in your Apple ID to deploy this App on your iPhone. 

### Phone
Your iPhone should meet the following requirements:
1. `iOS`, version `>= 10.1`.
2. A `Lightning cable`. Your phone must connected to your Mac to deploy the App.

## Deployment
1. Clone this repository. You may use the following command.
~~~~
git clone https://github.com/GreysTone/Porus.git
~~~~
2. Install the required components with the following command. The required packages are included in `Podfile`, so you need `CocoaPods` to install them. If you don't have one, please refer to [CocoaPods' homepage](https://cocoapods.org).
~~~~
pod install
~~~~
3. Launch the project in Xcode. To ensure all third-party components are configured correctly, go to the project directory in a command window and run the following command.
~~~~
open Porus.xcworkspace
~~~~
4. Open the project homepage in Xcode. In `Signing` section, please select your team. If you don't have one, you need to select `Add an Account` to create one.
5. If you have your iPhone connected, select your iPhone in `Build Target` and build (⌘ + B) the project. Please `unlock` your iPhone and choose `Allow` if you see any warnings.

## Layout
There are four views on the main screen of Porus. This section introduces the layout and functions of the views. The following image is a screenshot of the homepage of Porus.

![image](https://github.com/jerryljq/Porus/blob/master/homepage.PNG)

1. `V1`

`V1` shows what you can see through the camera. There is also a label showing your IP address and  port number of the server. You can tap it to edit.

2. `V2`

`V2` shows the most recently captured image from the camera. You can tap the `Capture` button to capture a image.

3. `P1`

`P1` shows some actions you can do. `Predict` button starts automatic prediction while `Pause` button stops it temporarily. `Connection` button can help you test the connection to the server.

4. `P2`

`P2` shows the messages from the server. It also displays the errors and other types of logs.

## Features
**1. Static Prediction**

After the server is correctly configured, you may tap `Capture` button and Porus will capture an image and predict the type of road in this single image.

**2. Realtime Prediction**

After the server is correctly configured, you may tap `Predict` button and Porus will capture an image every two seconds. The captured images will be sent to the server in the sequence they are captured and the server will reply the prediction results in the same order.


## Warning
The prediction accuracy of Porus is not high enough to assist drivers. Please `DO NOT` rely on Porus when you are driving. 

