import 'package:flutter/material.dart';

class DiaryEntryScreen extends StatelessWidget {
  final String date;
  const DiaryEntryScreen({super.key, required this.date});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Entry')));
}
