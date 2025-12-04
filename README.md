#  Neocord: A Swift-based Discord Client for iOS 6-26

Currently in the works, but supports a lot of features. VCs are planned but for the future.

## Features
- DMs and Group DMs
- Servers
- Channels
- Forums
- Threads
- Sending and recieving text with full markdown support
- Recieving custom emoji (iOS 7+)
- Recieving, sending and saving images (limit of 1 image per message on iOS 6 only)
- Presence indicators (online, offline, etc)
- Guild folders with proper order and memory
- Friends list
- Guild nicknames
- Guild roles
- Guild colors
- Profile view including roles, colors, nicknames (both guild and personal) and profile themes
- Replying inline
- Editing inline


## Compatibility

### Level 1 Compatibility (No Glass, No Animations, No Blur)
- A4 chipset, 256MB of RAM
- iOS 6-7

### Level 2 Compatibility (Glass, No Animations, No Blur)
- A5+ chipset, 512MB+ of RAM
- iOS 6-8

### Level 3 Compatibility (Glass, No Animations, Blur)
- A5+ chipset, 512MB+ of RAM
- iOS 9+

### Level 4 Compatibility (All Effects)
- A7+ chipset, 1GB+ of RAM
- iOS 9+

## Build
### Option 1 - iOS 6+ armv7/arm64 build
You must use Xcode 13.4, macOS 12, and my custom Swift 5.1.5 and Swift 5.10.1 toolchains which are provided on my website, https://www.j-w-i.org . After following the instructions there, download the SwiftcordLegacy package from my repo and place both this project and that project in your "Desktop" folder. Then, inside the folder for this project, run "./build". The output will be two IPAs that are named accordingly as to what their usage should be.

### Option 2 - iOS 12.0+ arm64 build
Use any version of Xcode that is 14+, on any macOS that will run it. I highly recommend using Swift 5.10 to build, but you shouldn't have to. 
