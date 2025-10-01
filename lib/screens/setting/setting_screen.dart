import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pregnancy Tracker')),
      body: Center(child: Text('Week-by-week pregnancy updates')),
    );
  }
}