// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "WLUnitField",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "WLUnitField",
            targets: ["WLUnitField"]
        )
    ],
    targets: [
        .target(
            name: "WLUnitField",
            path: "WLUnitField/Classes",
            publicHeadersPath: "."
        )
    ]
)
