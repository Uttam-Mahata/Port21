import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ftpconnect/ftpconnect.dart';
import '../services/ftp_service.dart';
import 'package:port21/services/storage_service.dart';
import 'package:port21/models/connection_profile.dart';

class FTPProvider with ChangeNotifier {
  final FTPService _ftpService = FTPService();
  
  List<FTPEntry> _files = [];
  String _currentPath = '/';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isConnected = false;
  List<ConnectionProfile> _savedProfiles = [];

  // Upload Progress State
  double _uploadProgress = 0.0;
  String _uploadSpeed = "";
  bool _isUploading = false;

  List<FTPEntry> get files => _files;
  String get currentPath => _currentPath;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;
  FTPService get service => _ftpService;
  List<ConnectionProfile> get savedProfiles => _savedProfiles;
  
  // Multi-file upload state
  int _totalUploadFiles = 0;
  int _currentUploadIndex = 0;
  String _currentUploadFileName = "";

  double get uploadProgress => _uploadProgress;
  String get uploadSpeed => _uploadSpeed;
  bool get isUploading => _isUploading;
  int get totalUploadFiles => _totalUploadFiles;
  int get currentUploadIndex => _currentUploadIndex;
  String get currentUploadFileName => _currentUploadFileName;

  Timer? _keepAliveTimer;

  FTPProvider() {
    _loadSavedProfiles();
  }

  @override
  void dispose() {
    _keepAliveTimer?.cancel();
    super.dispose();
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (_isConnected) {
        _ftpService.sendNoOp();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadSavedProfiles() async {
    _savedProfiles = await StorageService().getProfiles();
    notifyListeners();
  }

  Future<void> saveProfile(String host, int port, String user, String pass, bool isSecure) async {
    final profile = ConnectionProfile(
      host: host,
      port: port,
      username: user,
      password: pass,
      isSecure: isSecure,
    );
    await StorageService().saveProfile(profile);
    await _loadSavedProfiles();
  }

  Future<void> deleteProfile(ConnectionProfile profile) async {
    await StorageService().deleteProfile(profile);
    await _loadSavedProfiles();
  }

  Future<bool> connect(String host, int port, String user, String pass, {bool isSecure = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    // Reset path on new connection
    _currentPath = '/';

    bool success = await _ftpService.connect(host, port, user, pass, isSecure: isSecure);
    
    _isLoading = false;
    if (success) {
      _isConnected = true;
      _startKeepAlive();
      await _fetchFiles();
    } else {
      _errorMessage = "Failed to connect to server. Check credentials and network.";
    }
    notifyListeners();
    return success;
  }

  Future<void> disconnect() async {
    await _ftpService.disconnect();
    _isConnected = false;
    _files = [];
    _currentPath = '/';
    notifyListeners();
  }

  Future<void> navigateTo(String folderName) async {
      String newPath;
      if (_currentPath.endsWith('/')) {
        newPath = '$_currentPath$folderName';
      } else {
        newPath = '$_currentPath/$folderName';
      }
      _currentPath = newPath;
      await _fetchFiles();
  }
  
  Future<void> navigateUp() async {
      if (_currentPath == '/' || _currentPath.isEmpty) return;
      
      // Handle Windows/Unix path separators if needed, but FTP usually uses /
      List<String> parts = _currentPath.split('/');
      // If path ends with /, remove the last empty element first
      if (parts.isNotEmpty && parts.last.isEmpty) {
        parts.removeLast();
      }
      
      if (parts.isNotEmpty) {
        parts.removeLast();
      }
      
      if (parts.isEmpty || (parts.length == 1 && parts[0].isEmpty)) {
          _currentPath = '/';
      } else {
          _currentPath = parts.join('/');
          if (_currentPath.isEmpty) _currentPath = '/';
      }
      await _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    _setLoading(true);
    _errorMessage = null;
    _files = await _ftpService.listDirectory(_currentPath);
    
    // Sort directories first, then files
    _files.sort((a, b) {
        if (a.type == FTPEntryType.DIR && b.type != FTPEntryType.DIR) return -1;
        if (a.type != FTPEntryType.DIR && b.type == FTPEntryType.DIR) return 1;
        return a.name.compareTo(b.name);
    });
    _setLoading(false);
  }

  Future<void> refresh() async {
      await _fetchFiles();
  }
  
  Future<bool> uploadMultipleFiles(List<File> files) async {
    if (files.isEmpty) return false;

    _setLoading(true);
    _isUploading = true;
    _totalUploadFiles = files.length;
    _currentUploadIndex = 0;
    _uploadProgress = 0.0;
    _uploadSpeed = "0 B/s";
    notifyListeners();

    bool allSuccess = true;

    for (int i = 0; i < files.length; i++) {
      _currentUploadIndex = i + 1;
      _currentUploadFileName = files[i].path.split(Platform.pathSeparator).last;
      notifyListeners(); // Update UI for new file

      bool success = await _uploadSingleFileInternal(files[i]);
      if (!success) allSuccess = false;
      
      // key: Add a small delay between uploads to prevent server rate-limiting/timeouts
      if (i < files.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _isUploading = false;
    if (allSuccess) {
      await _fetchFiles();
    } else {
      _errorMessage = "Some files failed to upload.";
    }
    _setLoading(false);
    return allSuccess;
  }

  Future<bool> _uploadSingleFileInternal(File file) async {
      String fileName = file.path.split(Platform.pathSeparator).last;
      DateTime startTime = DateTime.now();
      
      // Reset progress for new file
      _uploadProgress = 0.0;
      // Do NOT notifyListeners here, or it might flash 0%. 
      // The onProgress will call it soon enough.

      bool success = await _ftpService.uploadFile(file, fileName, onProgress: (progress, sent, total) {
          _uploadProgress = progress / 100.0; 
          
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          if (elapsed > 0) {
             double speedBytesPerSec = (sent / elapsed) * 1000;
             _uploadSpeed = _formatSpeed(speedBytesPerSec);
          }
          notifyListeners();
      });
      return success;
  }
  
  Future<bool> uploadFile(File file) async {
      return uploadMultipleFiles([file]);
  }
  
  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
  
  Future<bool> downloadFile(FTPEntry entry, String localDirectory) async {
       _setLoading(true);
       File localFile = File('$localDirectory/${entry.name}');
       bool success = await _ftpService.downloadFile(entry.name, localFile);
       if (!success) {
         _errorMessage = "Failed to download file.";
       }
       _setLoading(false);
       return success;
  }
  
  Future<bool> deleteFile(FTPEntry entry) async {
      _setLoading(true);
      bool success = await _ftpService.deleteFile(entry.name);
      if (success) {
          await _fetchFiles();
      } else {
          _errorMessage = "Failed to delete file.";
      }
      _setLoading(false);
      return success;
  }

  Future<bool> createDirectory(String directoryName) async {
       _setLoading(true);
       bool success = await _ftpService.createDirectory(directoryName);
       if (success) {
           await _fetchFiles();
       } else {
           _errorMessage = "Failed to create directory.";
       }
       _setLoading(false);
       return success;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
