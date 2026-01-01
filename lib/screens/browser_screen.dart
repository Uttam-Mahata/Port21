import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ftpconnect/ftpconnect.dart';
import '../providers/ftp_provider.dart';
import 'saved_connections_screen.dart';
import 'login_screen.dart'; // Keep if needed, or remove if not used directly

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final ftp = context.read<FTPProvider>();
        if (ftp.currentPath != '/' && ftp.currentPath.isNotEmpty) {
           ftp.navigateUp();
        } 
        // If at root, we might want to exit app or do nothing (stay in app)
        // Usually Android back button at root should close app? 
        // For now, let's just do nothing if at root or add a confirmation.
      },
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<FTPProvider>(
            builder: (ctx, ftp, _) => Text(
              ftp.currentPath.isEmpty ? '/' : ftp.currentPath,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<FTPProvider>().refresh(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<FTPProvider>().disconnect();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SavedConnectionsScreen()),
                  );
                }
              },
            ),
          ],
        ),
        body: Consumer<FTPProvider>(
          builder: (context, ftp, child) {
            if (ftp.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
             if (ftp.errorMessage != null) {
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(ftp.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: ftp.refresh, child: const Text("Retry"))
                        ],
                      ),
                    )
                );
             }
            
            final files = ftp.files;

            return ListView.separated(
              itemCount: files.length + (ftp.currentPath == '/' ? 0 : 1),
              separatorBuilder: (ctx, idx) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // Add ".." entry if not root
                if (ftp.currentPath != '/' && index == 0) {
                     return ListTile(
                        leading: const Icon(Icons.folder_open, color: Colors.amber),
                        title: const Text('..'),
                        onTap: () => ftp.navigateUp(),
                     );
                }
                
                final realIndex = ftp.currentPath == '/' ? index : index - 1;
                final file = files[realIndex];
                final isDir = file.type == FTPEntryType.DIR;
                
                return ListTile(
                  leading: Icon(
                    isDir ? Icons.folder : Icons.insert_drive_file,
                    color: isDir ? Colors.amber : Colors.blueGrey,
                  ),
                  title: Text(file.name),
                  subtitle: isDir ? null : Text(_formatSize(file.size ?? 0)),
                  trailing: isDir 
                      ? const Icon(Icons.chevron_right) 
                      : IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showFileOptions(context, file),
                        ),
                  onTap: () {
                    if (isDir) {
                      ftp.navigateTo(file.name);
                    } else {
                       _showFileOptions(context, file);
                    }
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _uploadFile(context),
          child: const Icon(Icons.upload_file),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showFileOptions(BuildContext context, FTPEntry file) {
      showModalBottomSheet(context: context, builder: (ctx) {
          return SafeArea(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      ListTile(
                          leading: const Icon(Icons.download),
                          title: const Text('Download'),
                          onTap: () {
                              Navigator.pop(ctx);
                              _downloadFile(context, file);
                          },
                      ),
                       ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onTap: () {
                              Navigator.pop(ctx);
                              _deleteFile(context, file);
                          },
                      ),
                  ],
              ),
          );
      });
  }

  Future<void> _uploadFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      
      if (!context.mounted) return;

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Uploading File"),
          content: Consumer<FTPProvider>(
            builder: (context, ftp, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text("Uploading ${file.path.split(Platform.pathSeparator).last}"),
                   const SizedBox(height: 16),
                   LinearProgressIndicator(value: ftp.uploadProgress),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text("${(ftp.uploadProgress * 100).toStringAsFixed(0)}%"),
                       Text(ftp.uploadSpeed),
                     ],
                   )
                ],
              );
            }
          ),
        ),
      );
      
      // Perform upload
      bool success = await context.read<FTPProvider>().uploadFile(file);
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? "Upload Successful" : "Upload Failed"))
        );
      }
    }
  }

  Future<void> _downloadFile(BuildContext context, FTPEntry file) async {
    // Check permissions
    bool hasPermission = false;
    
    // Try Manage External Storage first (Android 11+)
    if (await Permission.manageExternalStorage.isGranted) {
      hasPermission = true;
    } else if (await Permission.storage.isGranted) {
      hasPermission = true;
    } else {
      // Request permissions
      if (await Permission.manageExternalStorage.request().isGranted) {
        hasPermission = true;
      } else if (await Permission.storage.request().isGranted) {
        hasPermission = true;
      }
    }

    if (hasPermission) {
       Directory? directory;
       if (Platform.isAndroid) {
          // Use /storage/emulated/0/Download for easier access if we have permission
           directory = Directory('/storage/emulated/0/Download');
           if (!await directory.exists()) {
             directory = (await getExternalStorageDirectories(type: StorageDirectory.downloads))?.first;
           }
       } else {
           directory = await getApplicationDocumentsDirectory();
       }
       
       if (directory != null) {
           final success = await context.read<FTPProvider>().downloadFile(file, directory.path);
           if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(success ? 'Downloaded to ${directory.path}/${file.name}' : 'Download Failed')),
               );
           }
       } else {
           if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not determine download path')));
           }
       }
    } else {
        if (context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Permission Denied'),
                content: const Text('Storage permission is required to save files. Please enable "All files access" in settings.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
        }
    }
  }
  
  Future<void> _deleteFile(BuildContext context, FTPEntry file) async {
       final confirm = await showDialog<bool>(
           context: context, 
           builder: (ctx) => AlertDialog(
               title: const Text('Delete File?'),
               content: Text('Are you sure you want to delete ${file.name}?'),
               actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                   TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
               ],
           ),
       );
       
       if (confirm == true) {
           await context.read<FTPProvider>().deleteFile(file);
       }
  }
}
