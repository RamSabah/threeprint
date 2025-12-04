import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.search, size: 100),
          SizedBox(height: 20),
          Text(
            'Search Prints',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Find your 3D models and prints',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}