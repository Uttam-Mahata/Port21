import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/connection_profile.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _keyProfiles = 'connection_profiles';

  Future<void> saveProfile(ConnectionProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    List<ConnectionProfile> profiles = await getProfiles();
    
    // Check if profile with same host exists, update it
    final index = profiles.indexWhere((p) => p.host == profile.host);
    if (index != -1) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }

    final String encodedData = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_keyProfiles, encodedData);
  }

  Future<void> deleteProfile(ConnectionProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    List<ConnectionProfile> profiles = await getProfiles();
    
    profiles.removeWhere((p) => p == profile);

    final String encodedData = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_keyProfiles, encodedData);
  }

  Future<List<ConnectionProfile>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_keyProfiles);
    
    if (encodedData == null) return [];

    try {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      return decodedData.map((json) => ConnectionProfile.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
