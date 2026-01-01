import 'dart:io';
import 'package:ftpconnect/ftpconnect.dart' hide Logger;
import 'package:logger/logger.dart';

class FTPService {
  FTPConnect? _ftpConnect;
  final Logger _logger = Logger();

  bool get isConnected => _ftpConnect != null;

  Future<bool> connect(String host, int port, String user, String pass, {bool isSecure = false}) async {
    try {
      // Create FTPConnect instance
      // Note: isSecured enables FTPS (FTP over TLS). 
      // If implicit FTPS is needed, additional config might be required depending on the library version,
      // but usually this handles explicit FTPS.
      _ftpConnect = FTPConnect(
        host, 
        port: port, 
        user: user, 
        pass: pass, 
        securityType: isSecure ? SecurityType.FTPS : SecurityType.FTP,
        timeout: 60, // Increase timeout to 60 seconds
      );
      
      await _ftpConnect!.connect();
      return true;
    } catch (e) {
      _logger.e("Connection Error: $e");
      await disconnect(); // Ensure cleanup
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _ftpConnect?.disconnect();
    } catch (e) {
      _logger.e("Disconnection Error: $e");
    } finally {
      _ftpConnect = null;
    }
  }

  Future<List<FTPEntry>> listDirectory(String path) async {
    if (_ftpConnect == null) return [];
    try {
      bool changed = await _ftpConnect!.changeDirectory(path);
      if (!changed) {
         _logger.w("Could not change directory to $path");
         return [];
      }
      return await _ftpConnect!.listDirectoryContent();
    } catch (e) {
      _logger.e("List Directory Error: $e");
      return [];
    }
  }

  Future<bool> uploadFile(File file, String remoteFileName, {Function(double, int, int)? onProgress}) async {
    if (_ftpConnect == null) return false;
    try {
      return await _ftpConnect!.uploadFile(file, sRemoteName: remoteFileName, onProgress: onProgress);
    } catch (e, stackTrace) {
      _logger.e("Upload Error: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> downloadFile(String remoteFileName, File localFile) async {
    if (_ftpConnect == null) return false;
    try {
      return await _ftpConnect!.downloadFile(remoteFileName, localFile);
    } catch (e, stackTrace) {
      _logger.e("Download Error: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> createDirectory(String directoryName) async {
     if (_ftpConnect == null) return false;
     try {
       return await _ftpConnect!.makeDirectory(directoryName);
     } catch (e, stackTrace) {
       _logger.e("Create Directory Error: $e", error: e, stackTrace: stackTrace);
       return false;
     }
  }
  
  Future<bool> deleteFile(String fileName) async {
    if (_ftpConnect == null) return false;
    try {
      return await _ftpConnect!.deleteFile(fileName);
    } catch (e, stackTrace) {
      _logger.e("Delete File Error: $e", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> sendNoOp() async {
    if (_ftpConnect == null) return;
    try {
      await _ftpConnect!.sendCustomCommand('NOOP');
    } catch (_) {
      // Ignore errors on NOOP, connection might be dead already
    }
  }
}
