
<p align="center">
    <img src="https://github.com/quran/quran-ios/assets/5665498/636ff859-78e9-40aa-96ea-db013197b6fc" width="350pt">
</p>

QuranEngine
===============
[![CI](https://github.com/quran/quran-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/quran/quran-ios/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/quran/quran-ios/branch/main/graph/badge.svg)](https://codecov.io/gh/quran/quran-ios)

QuranEngine is the open-source iOS library that powers the [Quran.com iOS App](https://apps.apple.com/app/id1118663303). This repository contains approximately 99% of the Quran.com iOS App code, providing you with a robust foundation to build Quran-related applications.

In this repository, we also provide an example application called QuranEngineApp that mimics the Quran.com iOS App, available under the [Example](/Example) folder.

## Installation

The repository can be installed via Swift Package Manager:

```swift
.package(url: "https://github.com/quran/quran-ios", branch: "main")
```
Then use one or more of the available targets as dependency. All targets are available for consumers, for example:
```swift
.product(name: "AppStructureFeature", package: "quran-ios"),
```

> :warning: Please note that we do not support CocoaPods or Carthage, and we do not plan to support these in the future.

## Building and Testing

Use the Makefile targets so `QURAN_SYNC` is always set explicitly:

```sh
# Build the package, or one scheme
make build-no-sync
make build-sync TARGET=NoorUI

# Run the complete package test plan
make test-no-sync
make test-sync

# Run one test target through the package test scheme
make test-no-sync TARGET=AyahMenuFeature
make test-sync TARGET=AyahMenuFeatureTests
```

For test commands, `TARGET` accepts either the production target or its `Tests` target. Both focused examples above select `AyahMenuFeatureTests`. New test targets must also be added to `QuranEngine-Package.xctestplan`.

### Local MobileSync Development

For local sync development, keep the three repositories under the same workspace:

```text
Quran/
├── mobile-sync/
├── mobile-sync-spm/
└── quran-ios/
```

The Makefile derives the workspace from Git's common directory. This works from both the primary `quran-ios` checkout and Git worktrees, whose immediate parent does not contain the sibling repositories.

```sh
# Build the KMP debug XCFramework, then build mobile-sync-spm against it
make build-mobile-sync-spm

# Build or test QuranEngine against both local dependencies
make build-sync-local-debug
make test-sync-local-debug

# Build or launch the example app against both local dependencies
make build-example-sync-local-debug
make run-example-sync-local-debug QURAN_OAUTH_CLIENT_ID=<client-id>
```

`MOBILE_SYNC_SPM_PATH` selects the local `mobile-sync-spm` package, while `MOBILE_SYNC_XCFRAMEWORK_PATH` selects the local KMP binary. The Makefile provides and validates defaults for the sibling-repository layout. Override the paths when using another layout:

```sh
make build-sync-local-debug \
  MOBILE_SYNC_DIR=/path/to/mobile-sync \
  MOBILE_SYNC_SPM_PATH=/path/to/mobile-sync-spm \
  MOBILE_SYNC_XCFRAMEWORK_PATH=../relative/path/to/Shared.xcframework
```

`MOBILE_SYNC_XCFRAMEWORK_PATH` is relative to the `mobile-sync-spm` package root, as required by Swift Package Manager binary targets. Local example launches default to full HTTP request and response logging; set `MOBILE_SYNC_HTTP_LOG_LEVEL=INFO` or `NONE` to reduce it. Authentication and cookie headers are redacted.

## Repository Structure and Architecture

The library consists of 6 top-level directories:

* **Core**: General purpose libraries that work with any app. The only exception is the Localization library, which we aim to make more universal.

* **Model**: Contains simple entities that facilitate building a Quran App. These entities mostly work together without including extensive logic.

* **Data**: This directory includes SQLite, CoreData, and Networking libraries that abstract away the underlying technologies used.

* **Domain**: This is where the business logic of the app resides. It depends on Model and Data to serve such business logic.

* **UI**: Houses the design system used by the App (we call it NoorUI). We are gradually shifting towards using SwiftUI in all our components, except for the navigation aspect - we will continue using UIKit for that. UI does not depend on Domain nor Data, but can depend on Core and Model.

* **Features**: Comprises the screens making up the app. They rely on all other components to create our Quran apps. Features can encompass other features to create higher-level features. For example, `AppStructureFeature` hosts all other features to create the app.

> :warning: UI and Features still have less test coverage than the foundational layers. New behavior should include focused tests where practical.

Here is a visual representation of the architecture:

<img width="438" alt="architecture" src="https://github.com/quran/quran-ios/assets/5665498/1135c102-c20b-456f-9f96-3c5b4faee0dc">

This dependency order is enforced in [Package.swift](https://github.com/quran/quran-ios/blob/c1598f6f582198035b0b3df6b09051cf2391e6c1/Package.swift#L751).


# Contributions

We warmly welcome contributions to the QuranEngine project. We encourage potential contributors to tackle any of the open issues. Please start a conversation with us in the Discussions section of the repo and we will do our best to assist you inshaa'Allah.

If your contribution is small enough, feel free to create a Pull Request directly. For larger contributions, we ask that you first create a post in the discussions section. This allows us to ensure that nobody else is working on the same feature, and also allows us to plan for upcoming features in case your contribution is dependent on another feature.

## Intended Use

We are re-open sourcing the app because we see a lot of benefits in allowing developers to build on top of what we have already built. This way, developers don't have to re-implement the foundation and can innovate more on the idea itself. The malicious behavior we've seen previously, including but not limited to selling this free code to people who are not aware of this repo's existence, is negligible compared to the overall benefit of giving what we have implemented to others. We look forward to seeing great Islamic innovation that helps Muslims everywhere inshaa'Allah.

We welcome all types of use. However, we kindly ask that you don't use the QuranEngineApp example and republish it without making any modifications. You may also need to bring your own data.

## License

* QuranEngine is available under Apache-2.0 license. See the LICENSE file for more info.
* Madani images from [quran images project](https://github.com/quran/quran.com-images) on github.
* Translation, tafsir and Arabic data come from [tanzil](http://tanzil.net) and [King Saud University](https://quran.ksu.edu.sa).
