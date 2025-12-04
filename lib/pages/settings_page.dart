import 'package:flutter/material.dart';
import '../widgets/bambu_lab_integration_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Center(
            child: Column(
              children: [
                Icon(Icons.settings, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'App Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Customize your 3D printing experience',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Printer Integration Section
          const Text(
            'Printer Integration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Bambu Lab Integration Widget
          const BambuLabIntegrationWidget(),
          
          const SizedBox(height: 32),
          
          // Other Settings Section (placeholder)
          const Text(
            'App Preferences',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle dark/light theme'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // TODO: Implement theme switching
                },
              ),
            ),
          ),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: const Text('Print completion alerts'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implement notification settings
                },
              ),
            ),
          ),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('App version and information'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Show about dialog
                showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text('ThreePrint'),
                    content: Text('Version 1.0.0\nA 3D printing management app'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}