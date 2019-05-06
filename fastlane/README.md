fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios screenshots
```
fastlane ios screenshots
```

### ios version_reset
```
fastlane ios version_reset
```
Resets the build to 1 and version to passed version value and push it to the origin.

params version: the new version of the app
### ios quran_foundation
```
fastlane ios quran_foundation
```

### ios release_quran_foundation
```
fastlane ios release_quran_foundation
```

### ios beta
```
fastlane ios beta
```
Submit a new Beta Build to Apple TestFlight

This will also make sure the profile is up to date

params clean: true|false, default is true

params includeFrameworks: true|false, default is true
### ios build_frameworks
```
fastlane ios build_frameworks
```
This will build frameworks

params archive: true|false

params target: device|simulator|both

params clean: true|false

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
