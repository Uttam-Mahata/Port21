# Port21 Architecture

## Overview
Port21 is a Flutter application designed with a clean separation of concerns using the **Provider** pattern for state management. It bridges the UI layer with the underlying FTP networking logic.

## Layered Design

### 1. UI Layer (`lib/screens`)
- **LoginScreen**: Handles user input for connection credentials. It delegates authentication to the `FTPProvider`.
- **BrowserScreen**: Displays the file system of the remote server. It observes `FTPProvider` for changes in the file list or current path.
- **Widgets**: Uses Material 3 components. Responsive design is achieved via `ConstrainedBox` and flexible layouts.

### 2. State Management Layer (`lib/providers`)
- **FTPProvider**: The central store for the application state.
    - Manages `_currentPath`, `_files` list, `_isLoading`, and `_errorMessage`.
    - Exposes methods like `connect`, `disconnect`, `navigateTo`, `uploadFile`, etc.
    - Notifies listeners (UI) whenever state changes (e.g., download starts/finishes).

### 3. Service Layer (`lib/services`)
- **FTPService**: A dedicated class wrapping the `ftpconnect` package.
    - Encapsulates low-level FTP commands.
    - Handles exceptions and logging.
    - Returns raw data (e.g., `List<FTPEntry>`) or success booleans to the Provider.

## Data Flow
1. **User Action**: User clicks "Connect".
2. **UI -> Provider**: `LoginScreen` calls `provider.connect()`.
3. **Provider -> Service**: `FTPProvider` calls `service.connect()`.
4. **Service -> Network**: `FTPService` establishes the TCP/TLS connection.
5. **State Update**: Provider updates `_isConnected` and `_files`.
6. **UI Rebuild**: `Consumer<FTPProvider>` detects the change and navigates the user to `BrowserScreen`.

## dependencies
- `ftpconnect`: Core FTP logic.
- `provider`: State injection.
- `path_provider`: Accessing local storage paths.
- `permission_handler`: Managing Android runtime permissions.
