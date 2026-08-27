import 'package:flutter/material.dart';

void main() {
  runApp(const PaceUpApp());
}

class PaceUpApp extends StatelessWidget {
  const PaceUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaceUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const Scaffold(body: Center(child: Text('PaceUp'))),
    );
  }
}
