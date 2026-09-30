import 'package:flutter/material.dart';

import 'ui/terrarium_screen.dart';

class HissingoApp extends StatelessWidget {
  const HissingoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hissingo',
      theme: ThemeData.dark(),
      home: const TerrariumScreen(),
    );
  }
}
