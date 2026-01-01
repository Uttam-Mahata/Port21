import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ftp_provider.dart';
import 'screens/saved_connections_screen.dart';

void main() {
  runApp(const Port21App());
}

class Port21App extends StatelessWidget {
  const Port21App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FTPProvider()),
      ],
      child: MaterialApp(
        title: 'Port21',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        home: const SavedConnectionsScreen(),
      ),
    );
  }
}
