import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ftp_provider.dart';
import 'browser_screen.dart';
import '../models/connection_profile.dart';

import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '21');
  final _userController = TextEditingController(text: 'anonymous');
  final _passController = TextEditingController();
  bool _isSecure = false;
  bool _saveConnection = false;
  ConnectionProfile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Request storage permissions on app start
    // For Android 11+ (API 30+), use Manage External Storage for full access
    if (await Permission.manageExternalStorage.request().isGranted) {
      return; 
    }
    
    // Fallback for older Android or if Manage External Storage is not applicable/denied
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    if (statuses[Permission.storage]!.isDenied || statuses[Permission.manageExternalStorage]!.isDenied) {
       // Optionally show a dialog explaining why
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Storage permissions are required to download/upload files.')),
         );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      appBar: AppBar(title: const Text('Port21 - FTP Client')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/logo.png',
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Text(
                        'Connect to Server',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Saved Connections Dropdown
                      Consumer<FTPProvider>(
                        builder: (context, provider, child) {
                          if (provider.savedProfiles.isEmpty) return const SizedBox.shrink();
                          
                          // Ensure selected profile is still valid
                          ConnectionProfile? selectedValue;
                           if (_selectedProfile != null) {
                             if (provider.savedProfiles.contains(_selectedProfile)) {
                               selectedValue = _selectedProfile;
                             }
                           }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: DropdownButtonFormField<ConnectionProfile>(
                              isExpanded: true, // Fix broken RenderFlex
                              decoration: const InputDecoration(
                                labelText: 'Saved Connections',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.bookmark),
                              ),
                              value: selectedValue,
                              items: provider.savedProfiles.map((profile) {
                                return DropdownMenuItem(
                                  value: profile,
                                  child: Text(
                                    '${profile.username}@${profile.host}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (profile) {
                                if (profile != null) {
                                  _hostController.text = profile.host;
                                  _portController.text = profile.port.toString();
                                  _userController.text = profile.username;
                                  _passController.text = profile.password;
                                  setState(() {
                                    _selectedProfile = profile;
                                    _isSecure = profile.isSecure;
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                      TextFormField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Host Address',
                          hintText: 'ftp.example.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.dns),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter host address' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '21',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter port' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _userController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter username' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Use FTPS (Secure)'),
                        value: _isSecure,
                        onChanged: (value) => setState(() => _isSecure = value),
                      ),
                      CheckboxListTile(
                        title: const Text('Save Connection Details'),
                        value: _saveConnection,
                        onChanged: (value) => setState(() => _saveConnection = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: Consumer<FTPProvider>(
                          builder: (context, provider, child) {
                            return ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState?.validate() ?? false) {
                                        final host = _hostController.text;
                                        final port = int.parse(_portController.text);
                                        final user = _userController.text;
                                        final pass = _passController.text;

                                        if (_saveConnection) {
                                          await provider.saveProfile(host, port, user, pass, _isSecure);
                                        }

                                        final success = await provider.connect(
                                          host,
                                          port,
                                          user,
                                          pass,
                                          isSecure: _isSecure,
                                        );

                                        if (success && context.mounted) {
                                            Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const BrowserScreen(),
                                            ),
                                          );
                                        } else if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(provider.errorMessage ?? 'Connection failed'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: provider.isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Connect'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
