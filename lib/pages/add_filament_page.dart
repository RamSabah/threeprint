import 'package:flutter/material.dart';

class AddFilamentPage extends StatelessWidget {
  const AddFilamentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.add_circle_outline, size: 100),
          SizedBox(height: 20),
          Text(
            'Add New Filament',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Track your filament inventory',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}