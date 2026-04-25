// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "cordova-plugin-google-maps-sdk",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "cordova-plugin-google-maps-sdk", targets: ["cordova-plugin-google-maps-sdk"])
    ],
    dependencies: [
        // This must be included as a dependency, with this format for it to work.
        .package(url: "https://github.com/apache/cordova-ios.git", branch: "master"),
        .package(url: "https://github.com/googlemaps/ios-maps-sdk", exact: "10.12.0")
    ],
    targets: [
        .target(
            name: "cordova-plugin-google-maps-sdk",
            dependencies: [
                .product(name: "Cordova", package: "cordova-ios"),
                .product(name: "GoogleMaps", package: "ios-maps-sdk")
            ],
            path: "src/ios",
            resources: [],
            publicHeadersPath: "."
        )
    ]
)
