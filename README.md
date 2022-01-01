
<p align="center">
    <img src="https://user-images.githubusercontent.com/5665498/147855777-fc7d645c-6522-4bb3-8886-32c9f90b20df.png" width="350pt">
</p>

QuranEngine is the engine powering the [Quran.com iOS app](https://itunes.apple.com/app/id1118663303). It's a collection of libraries that can be used to create a Quran app or a quran reading/listening experience within an Islamic app.

- [Libraries](#libraries)
  - [QuranKit](#qurankit)
  - [QuranTextKit](#qurantextkit)
- [Libraries to Open Source Soon](#libraries-to-open-source-soon)
  - [QuranMadaniData](#quranmadanidata)
  - [QuranAudioKit](#quranaudiokit)
  - [QuranBookmarkingKit](#quranbookmarkingkit)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
- [Contributions](#contributions)
- [License](#license)

## Libraries

We have currently open sourced the following libraries:

### QuranKit
A quranic numbering library. It can be used to locate the page of a verse or juz' of a page, etc.

### QuranTextKit
A quranic text kit to search and retrieve quran, translations and tafseers text.


## Libraries to Open Source Soon

The following are libraries we are going to open source soon.

### QuranMadaniData

The data for the madani Quran.

### QuranAudioKit

A library for downloading and playing quran recitations.

### QuranBookmarkingKit

A library for taking bookmarks and notes.


## Installation

### Swift Package Manager

```swift
let package = Package(
    name: "<YOUR PACKAGE>",
    products: [
        .library(name: "<YOUR PACKAGE>", targets: ["Caching"]),
    ],
    dependencies: [
        .package(url: "https://github.com/quran/quran-ios", .from("2.0.0")),
    ],
    targets: [
        .target(
            name: "<YOUR PACKAGE>",
            dependencies: [
                .product(name: "QuranTextKit", package: "quran-ios"),
            ]
        ),
    ]
)
```

It would be great if you could send an e-mail to ios@quran.com then we will notify you for beta builds and you can then help us find bugs before going live.

## Contributions
Please read [Contributions page](https://github.com/quran/quran-ios/wiki/Contributions).

## License

* QuranEngine is available under Apache-2.0 license. See the LICENSE file for more info.
* Madani images from [quran images project](https://github.com/quran/quran.com-images) on github.
* Translation, tafsir and Arabic data come from [tanzil](http://tanzil.net) and [King Saud University](https://quran.ksu.edu.sa).
