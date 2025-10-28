import 'package:flutter/material.dart';
import 'features/schedules/presentation/pages/schedules_page.dart';
import 'test_departments_simple.dart';
import 'test_audience_types_simple.dart';
import 'test_lesson_types_simple.dart';
import 'features/equipments/presentation/equipments_screen.dart';
import 'features/buildings/presentation/buildings_screen.dart';
import 'features/time_slots/presentation/time_slots_screen.dart';

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
        '/equipments': (context) => const EquipmentsScreen(),
        '/buildings': (context) => const BuildingsScreen(),
        '/time-slots': (context) => const TimeSlotsScreen(),
      },
    );
  }
}
