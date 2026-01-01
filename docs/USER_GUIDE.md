# Port21 User Guide

## Connecting to a Server

1. Open the Port21 app.
2. Fill in your server details:
   - **Host Address**: The IP address or domain name (e.g., `ftp.example.com`).
   - **Port**: Default is `21`. Change it if your server uses a non-standard port.
   - **Username**: FTP user (use `anonymous` for public servers).
   - **Password**: Your FTP password (leave empty for anonymous if applicable).
3. **FTPS (Secure)**:
   - Toggle the **Use FTPS** switch ON if your server requires FTP over TLS (Encrypted).
   - Leave it OFF for standard unencrypted FTP.
### Saved Connections
- When you connect successfully and choose to "Save Connection Details", the profile is saved.
- **Direct Connect**: Tap a saved profile to connect immediately.
- **Edit**: Tap the **Pencil Icon** to modify connection details before connecting.
- **Delete**: Long-press a profile to remove it.

## File Browsing

- **Directories**: Folders are shown with a yellow folder icon. Tap them to enter.
- **Go Back**: Tap the `..` folder at the top of the list to go up one level.
- **Refresh**: Tap the refresh icon in the top-right corner to reload the file list.

## Managing Files

### Download
1. Locate the file you want to download.
2. Tap the **More Options** (three vertical dots) icon on the right.
3. Select **Download**.
4. The file will be saved to your device's **Downloads** folder.
5. **Permissions**: The app will request storage permission only the first time you try to download. Please grant it to proceed.

### Upload
1. Tap the **+ (Plus)** button in the bottom right corner.
2. Select one or **multiple files** from your device's file picker (long-press to select multiple).
3. A **Progress Dialog** will appear showing:
   - "Uploading 1/X" counter.
   - Current file name and progress.
   - Upload speed.
4. Do not close the app while uploading. The dialog will close automatically when **all files** are uploaded.

### Create Folder
1. Tap the **Create Folder** icon (folder with a plus sign) in the top menu bar.
2. Enter a name for the new folder in the dialog box.
3. Tap **Create**.
4. The new folder will appear in the list immediately.

### Delete
1. Tap the **More Options** icon on the file.
2. Select **Delete**.
3. Confirm the deletion in the popup dialog. **Warning: This cannot be undone.**
