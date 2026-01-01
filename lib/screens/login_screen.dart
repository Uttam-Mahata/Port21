import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ftp_provider.dart';
import 'browser_screen.dart';
import '../models/connection_profile.dart';

import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  final ConnectionProfile? profile;
  const LoginScreen({super.key, this.profile});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _userController;
  late final TextEditingController _passController;
  bool _isSecure = false;
  bool _saveConnection = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    
    // Initialize with profile data or defaults
    _hostController = TextEditingController(text: widget.profile?.host ?? '');
    _portController = TextEditingController(text: widget.profile?.port.toString() ?? '21');
    _userController = TextEditingController(text: widget.profile?.username ?? 'anonymous');
    _passController = TextEditingController(text: widget.profile?.password ?? '');
    _isSecure = widget.profile?.isSecure ?? false;
    // If opening an existing profile, default to saving updates? Or just keep it separate.
    // Let's default to false to be explicit, or true if it's a saved profile we are "editing" (conceptually).
    // For simplicity, let user decide.
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
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
