import 'package:flutter/material.dart';
import 'features/schedules/presentation/pages/schedules_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SchedulesPage(),
    );
  }
}
