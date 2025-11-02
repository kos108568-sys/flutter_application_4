import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/audiences/data/audiences_repository.dart';
import '../../features/audiences/data/audience_lesson_types_repository.dart';
import '../../features/departments/data/department_repository.dart';
import '../../features/audience_types/data/audience_type_repository.dart';
import '../../features/lesson_types/data/lesson_type_repository.dart';
import '../../features/lesson_rules/data/lesson_rules_repository.dart';
import '../../features/equipments/data/equipment_repository.dart';
import '../../features/buildings/data/building_repository.dart';
import '../../features/time_slots/data/time_slot_repository.dart';
import '../../features/teachers/data/teachers_repository.dart';
import '../../features/disciplines/data/disciplines_repository.dart';
import '../../features/groups/data/groups_repository.dart';
import '../../features/audiences/data/audience_equipments_repository.dart';
import '../../features/gst/data/group_subject_teachers_repository.dart';
import '../../features/schedules/data/lessons_repository.dart';
// import 'sync_logger.dart';

class SyncService {
  final _localAudRepo = AudiencesRepository();
  final _departmentRepo = DepartmentRepository();
  final _audienceTypeRepo = AudienceTypeRepository();
  final _lessonTypeRepo = LessonTypeRepository();
  final _lessonRulesRepo = LessonRulesRepository();
  final _equipmentRepo = EquipmentRepository();
  final _buildingRepo = BuildingRepository();
  final _timeSlotRepo = TimeSlotRepository();
  final _teachersRepo = TeachersRepository();
  final _disciplinesRepo = DisciplinesRepository();
  final _groupsRepo = GroupsRepository();
  final _audEquipRepo = AudienceEquipmentsRepository();
  final _audLessonTypesRepo = AudienceLessonTypesRepository();
  final _gstRepo = GroupSubjectTeachersRepository();
  final _lessonsRepo = LessonsRepository();
  final supabase = Supabase.instance.client;

  // last pull tracking currently unused
  // ignore: unused_field
  DateTime _lastPulled = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final since = prefs.getInt('lastPulledAt') ?? 0;
    _lastPulled = DateTime.fromMillisecondsSinceEpoch(since);
  }

  // ignore: unused_element
  Future<void> _saveLastPulled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPulledAt', DateTime.now().millisecondsSinceEpoch);
    _lastPulled = DateTime.now();
  }

  

  Future<void> fullSync() async {
    try {
      // синхронизация аудиторий
      await _localAudRepo.syncAudiences();
      
      // Синхронизация отделов (асинхронно, чтобы не блокировать)
      Future.microtask(() async {
        try {
          await _departmentRepo.syncDepartments();
        } catch (e) {
          print('Ошибка при синхронизации отделов: $e');
        }
      });
      
      // Синхронизация типов аудиторий (асинхронно, чтобы не блокировать)
      Future.microtask(() async {
        try {
          await _audienceTypeRepo.syncAudienceTypes();
        } catch (e) {
          print('Ошибка при синхронизации типов аудиторий: $e');
        }
      });
      
      // Синхронизация типов занятий (асинхронно, чтобы не блокировать)
      Future.microtask(() async {
        try {
          await _lessonTypeRepo.syncLessonTypes();
        } catch (e) {
          print('Ошибка при синхронизации типов занятий: $e');
        }
      });

      // Синхронизация правил занятий и аудиторий (асинхронно, чтобы не блокировать)
      Future.microtask(() async {
        try {
          await _lessonRulesRepo.syncRules();
        } catch (e) {
          print('Ошибка при синхронизации правил занятий: $e');
        }
      });

      // Синхронизация справочника оборудования (асинхронно)
      Future.microtask(() async {
        try {
          await _equipmentRepo.syncEquipments();
        } catch (e) {
          print('Ошибка при синхронизации оборудования: $e');
        }
      });

      // Синхронизация справочника корпусов (асинхронно)
      Future.microtask(() async {
        try {
          await _buildingRepo.syncBuildings();
        } catch (e) {
          print('Ошибка при синхронизации корпусов: $e');
        }
      });

      // Синхронизация временных интервалов (асинхронно)
      Future.microtask(() async {
        try {
          await _timeSlotRepo.syncTimeSlots();
        } catch (e) {
          print('Ошибка при синхронизации временных интервалов: $e');
        }
      });

      // Синхронизация преподавателей (асинхронно)
      Future.microtask(() async {
        try {
          await _teachersRepo.syncTeachers();
        } catch (e) {
          print('Ошибка при синхронизации преподавателей: $e');
        }
      });

      // Синхронизация дисциплин (асинхронно)
      Future.microtask(() async {
        try {
          await _disciplinesRepo.syncDisciplines();
        } catch (e) {
          print('Ошибка при синхронизации дисциплин: $e');
        }
      });

      // Синхронизация групп (асинхронно)
      Future.microtask(() async {
        try {
          await _groupsRepo.syncGroups();
        } catch (e) {
          print('Ошибка при синхронизации групп: $e');
        }
      });

      // Синхронизация связей аудитория-оборудование (асинхронно)
      Future.microtask(() async {
        try {
          await _audEquipRepo.syncAudienceEquipments();
        } catch (e) {
          print('Ошибка при синхронизации audience_equipments: $e');
        }
      });

      // Синхронизация связей аудитория-тип занятия (асинхронно)
      Future.microtask(() async {
        try {
          await _audLessonTypesRepo.syncAudienceLessonTypes();
        } catch (e) {
          print('Ошибка при синхронизации audience_lesson_types: $e');
        }
      });

      // Синхронизация GST (асинхронно)
      Future.microtask(() async {
        try {
          await _gstRepo.syncGST();
        } catch (e) {
          print('GST sync error: ' + e.toString());
        }
      });
      Future.microtask(() async {
        try {
          await _lessonsRepo.syncLessons();
        } catch (e) {
          print('Lessons sync error: ' + e.toString());
        }
      });
    } catch (e) {
      print('Ошибка при полной синхронизации: $e');
    }
  }
}

