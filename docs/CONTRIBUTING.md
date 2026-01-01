# Contributing to Port21

We welcome contributions! Please follow these steps to get started.

## Development Setup

1. **Fork and Clone**: Fork the repo and clone it locally.
2. **Prerequisites**:
    - Flutter SDK (latest stable).
    - Java 21 JDK (important due to Gradle/Java compatibility issues).
    - Android SDK with NDK installed.
3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

## Running the App

```bash
flutter run
```
Ensure you have an emulator running or a physical device connected.

## Testing

Run unit and widget tests before submitting changes:

```bash
flutter test
```

## Java/Gradle Issues
If you see "What went wrong: 25", ensure your `android/gradle.properties` points to Java 21:
```properties
org.gradle.java.home=/path/to/java-21
```

## Submission
1. Create a branch for your feature/fix.
2. Commit with clear messages.
3. Open a Pull Request.
