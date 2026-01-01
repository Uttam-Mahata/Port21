# Port21

![Port21 Logo](port21.png)

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

### Troubleshooting: Java Warnings or Build Errors

If you encounter warnings like `WARNING: A restricted method in java.lang.System has been called` or build errors related to Java version:

1.  **Java Version**: Ensure you are using Java 21 (JDK 21). Java 25 is currently too new for some Gradle components.
2.  **Fix**: Set `JAVA_HOME` to your Java 21 installation before running Gradle:
    ```bash
    export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
    ./gradlew run
    ```

## Features added in v1.1

- **Upload Progress**: Real-time progress bar and percentage during file uploads.
- **Speed Indicator**: Shows current upload speed (e.g., MB/s).
- **Smart Permissions**: Storage permissions are requested only when needed (on download), not at startup.
- **Quick Connect**: Saved profiles connect directly with one tap. Use the Edit icon to modify details.

## Usage

1. **Connect**: Launch the app and enter your FTP server details (Host, Port, Username, Password).
2. **Secure Mode**: Toggle "Use FTPS (Secure)" for TLS connections.
3. **Browse**: Tap folders to navigate. Use the `..` item to go up a directory.
4. **Actions**:
    - **Upload**: Tap the floating action button (+).
    - **Context Menu**: Tap the "more" (three dots) icon on a file to Download or Delete it.
