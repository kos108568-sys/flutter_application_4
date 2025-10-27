import 'package:flutter/material.dart';
import 'features/schedules/presentation/pages/schedules_page.dart';
import 'test_departments_simple.dart';
import 'test_audience_types_simple.dart';
import 'test_lesson_types_simple.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SchedulesPage(),
      routes: {
        '/test-departments': (context) => const DepartmentsTestScreen(),
        '/test-audience-types': (context) => const AudienceTypesTestScreen(),
        '/test-lesson-types': (context) => const LessonTypesTestScreen(),
      },
    );
  }
}
