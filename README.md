# XcodeClean Pro

[![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-blue.svg)](https://developer.apple.com/macos/)
[![Language](https://img.shields.io/badge/language-Swift%206.0-orange.svg)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**XcodeClean Pro** is an intelligent, high-performance native macOS utility designed for iOS, iPadOS, and macOS developers. It solves the massive disk space accumulation issue caused by Xcode's cache directories (`DerivedData`, `DeviceSupport`, SPM caches, system archives, and orphaned simulators) which can easily balloon to over 70GB+ of stale files over time.

Built entirely in Swift and SwiftUI, XcodeClean Pro features a premium glassmorphic interface, a dynamic Menu Bar Widget, a floating Desktop HUD, and a customizable background scheduler with native macOS notifications.

---

## Key Features

* **Smart Storage Scanner:** Multi-threaded asynchronous scanner that runs deep file-system checks in background threads, keeping the main interface fully responsive.
* **Granular Deletion Controls:** Drill down into specific categories. Selectively delete individual project folders inside `DerivedData` or target specific iOS version cache files in `DeviceSupport` without purging everything.
* **Status Bar (Menu Bar Extra) Widget:** Monitor recoverable disk space in real-time from the macOS menu bar. Perform quick scans and smart cleanups directly from the status menu.
* **Desktop HUD Widget:** A floating, drag-and-drop glassmorphic widget styled after native macOS desktop widgets that provides quick-clean access.
* **Intelligent Scheduler:** Configure daily, weekly, or monthly scans. Set custom warning thresholds (e.g., alert when Xcode cache exceeds 20GB) to receive local system notifications.
* **Simulator Optimization:** Bridges directly to CoreSimulator CLI to automatically purge orphaned, unavailable, and unsupported simulator runtimes.

---

## Architectural Highlights

### Swift 6 Concurrency & Actor Isolation
To satisfy strict modern safety requirements, the scanning engine (`XcodeScanner`) and cleaning manager (`XcodeCleaner`) isolate disk access operations from the UI thread. File-system sweeps and deletion procedures are run on non-isolated background threads (`Task.detached`), using static value-typed payload exchanges to eliminate data races and actor-isolation conflicts.

```swift
// Swift 6 thread-safe background deletion
let bytesFreed = await Task.detached(priority: .userInitiated) {
    var totalFreed: Int64 = 0
    let fileManager = FileManager.default
    // Perform background deletions using thread-safe path structures...
    return totalFreed
}.value
```

### CoreSimulator Bridge
Instead of blindly removing system files, XcodeClean Pro uses process bridging to execute CLI runtimes like `xcrun simctl delete unavailable`, ensuring that simulator cleanups are handled through Apple's official system tools, avoiding configuration corruption.

---

## Storage Directory Breakdown

XcodeClean Pro scans and cleans the following critical developer folders:

| Category | System Path | Description |
| :--- | :--- | :--- |
| **Derived Data** | `~/Library/Developer/Xcode/DerivedData` | Build artifacts, index logs, and intermediate project files. |
| **Device Support** | `~/Library/Developer/Xcode/*DeviceSupport` | SDK files for debugging physical iOS, watchOS, and tvOS devices. |
| **Caches** | `~/Library/Caches/com.apple.dt.Xcode` | IDE log caches and documentation indexes. |
| **SPM Caches** | `~/Library/Caches/org.swift.swiftpm` | Cached Git clones and downloaded packages. |
| **Archives** | `~/Library/Developer/Xcode/Archives` | Stored App Store / Ad-Hoc builds (`.xcarchive`). |
| **Device Logs** | `~/Library/Developer/Xcode/iOS Device Logs` | Crash reports and system logs collected from debugged devices. |
| **Simulators** | `~/Library/Developer/CoreSimulator/Devices` | Cached simulator application states and system runtimes. |

---

## Getting Started

### Prerequisites
* macOS 14.0 or higher
* Xcode 15.0 or higher
* Swift 6.0 toolchain

### Build and Run
Clone the repository, open the project in Xcode, and build:

1. Open `XcodeClean Pro.xcodeproj` in Xcode.
2. Ensure code signing is set to your active Apple Developer Account or Local Development certificate.
3. Build and run using `Cmd + R` or command line:

```bash
xcodebuild -scheme "XcodeClean Pro" -configuration Release -destination 'platform=macOS' build
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
