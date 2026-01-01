# Port21

Port21 is a modern FTP client application built with Flutter for Android. It supports standard FTP as well as secure FTPS connections.

## Features

- **Protocol Support**:
    - **FTP**: Standard File Transfer Protocol.
    - **FTPS**: FTP over TLS (Implicit/Explicit) for secure transfers.
- **File Management**:
    - Browse files and directories.
    - Upload files from local storage.
    - Download files to the device (Downloads folder).
    - Delete files remotely.
- **Responsive UI**: Designed to work on phones and tablets.

## Getting Started

### Prerequisites

- Flutter SDK
- Android SDK
- Java 21 (JDK 21) or compatible LTS version.

### Installation

1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Troubleshooting: "What went wrong: 25"

If you encounter a build error stating `What went wrong: 25` or `java.lang.System::load` restrictions, it is likely due to an incompatibility with Java 25.

**Fix**:
Ensure you are using Java 21. You may need to explicitely tell Gradle to use it by adding the following line to `android/gradle.properties`:

```properties
org.gradle.java.home=/usr/lib/jvm/java-21-openjdk-amd64
```
(Adjust the path to match your Java 21 installation).

## Usage

1. **Connect**: Launch the app and enter your FTP server details (Host, Port, Username, Password).
2. **Secure Mode**: Toggle "Use FTPS (Secure)" for TLS connections.
3. **Browse**: Tap folders to navigate. Use the `..` item to go up a directory.
4. **Actions**:
    - **Upload**: Tap the floating action button (+).
    - **Context Menu**: Tap the "more" (three dots) icon on a file to Download or Delete it.
