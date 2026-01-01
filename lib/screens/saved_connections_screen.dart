import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ftp_provider.dart';
import '../models/connection_profile.dart';
import 'login_screen.dart';
import 'browser_screen.dart';

class SavedConnectionsScreen extends StatelessWidget {
  const SavedConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Connections')),
      body: Consumer<FTPProvider>(
        builder: (context, provider, child) {
          if (provider.savedProfiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No saved connections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add a new server'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.savedProfiles.length,
            itemBuilder: (context, index) {
              final profile = provider.savedProfiles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.dns)),
                  title: Text(profile.host),
                  subtitle: Text('${profile.username} • Port: ${profile.port}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(profile: profile),
                        ),
                      );
                    },
                  ),
                  onTap: () async {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(child: CircularProgressIndicator()),
                    );

                    final success = await provider.connect(
                      profile.host,
                      profile.port,
                      profile.username,
                      profile.password,
                      isSecure: profile.isSecure,
                    );

                    if (context.mounted) {
                      Navigator.pop(context); // Close loading dialog
                      
                      if (success) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BrowserScreen(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text(provider.errorMessage ?? 'Connection failed'),
                             backgroundColor: Colors.red,
                           ),
                        );
                      }
                    }
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Connection?'),
                        content: Text('Remove ${profile.host} from saved connections?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.deleteProfile(profile);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
