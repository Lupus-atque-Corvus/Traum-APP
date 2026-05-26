import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/database/traum_database.dart';
import '../providers/database_provider.dart';

class ImportResult {
  final int total;
  final String? error;
  const ImportResult({this.total = 0, this.error});
}

class DataImportExportService {
  final TraumDatabase _db;
  DataImportExportService(this._db);

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> exportModules(List<String> modules) async {
    final data = await _buildExportMap(modules);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/traum_backup.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'TRAUM Backup',
    );
  }

  Future<Map<String, dynamic>> _buildExportMap(List<String> modules) async {
    final Map<String, dynamic> moduleData = {};
    for (final mod in modules) {
      switch (mod) {
        case 'planning':
          moduleData['planning'] = await _exportPlanning();
        case 'training':
          moduleData['training'] = await _exportTraining();
        case 'health':
          moduleData['health'] = await _exportHealth();
        case 'nutrition':
          moduleData['nutrition'] = await _exportNutrition();
        case 'supplements':
          moduleData['supplements'] = await _exportSupplements();
        case 'medication':
          moduleData['medication'] = await _exportMedication();
        case 'abstinence':
          moduleData['abstinence'] = await _exportAbstinence();
        case 'budget':
          moduleData['budget'] = await _exportBudget();
        case 'period':
          moduleData['period'] = await _exportPeriod();
      }
    }
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'modules': moduleData,
    };
  }

  Future<Map<String, dynamic>> _exportPlanning() async {
    final appointments = await _db.select(_db.appointments).get();
    final todos = await _db.select(_db.todos).get();
    final goals = await _db.select(_db.goals).get();
    final todoSubItems = await _db.select(_db.todoSubItems).get();
    final subTasks = await _db.select(_db.subTasks).get();
    final habits = await _db.select(_db.habits).get();
    final habitLogs = await _db.select(_db.habitLogs).get();
    return {
      'appointments': appointments.map((r) => {
            'id': r.id, 'title': r.title, 'description': r.description,
            'location': r.location,
            'startTime': r.startTime.toIso8601String(),
            'endTime': r.endTime?.toIso8601String(),
            'allDay': r.allDay, 'recurrenceRule': r.recurrenceRule,
            'color': r.color, 'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'todos': todos.map((r) => {
            'id': r.id, 'title': r.title, 'note': r.note,
            'priority': r.priority, 'done': r.done,
            'dueDate': r.dueDate?.toIso8601String(),
            'completedAt': r.completedAt?.toIso8601String(),
            'createdAt': r.createdAt.toIso8601String(),
            'listName': r.listName,
          }).toList(),
      'todoSubItems': todoSubItems.map((r) => {
            'id': r.id, 'todoId': r.todoId, 'title': r.title,
            'done': r.done, 'sortOrder': r.sortOrder,
          }).toList(),
      'goals': goals.map((r) => {
            'id': r.id, 'title': r.title, 'description': r.description,
            'targetValue': r.targetValue, 'currentValue': r.currentValue,
            'unit': r.unit, 'targetDate': r.targetDate?.toIso8601String(),
            'done': r.done, 'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'subTasks': subTasks.map((r) => {
            'id': r.id, 'goalId': r.goalId, 'title': r.title,
            'done': r.done, 'sortOrder': r.sortOrder,
          }).toList(),
      'habits': habits.map((r) => {
            'id': r.id, 'name': r.name, 'emoji': r.emoji,
            'frequency': r.frequency, 'reminderTime': r.reminderTime,
            'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'habitLogs': habitLogs.map((r) => {
            'id': r.id, 'habitId': r.habitId,
            'logDate': r.logDate.toIso8601String(), 'done': r.done,
          }).toList(),
    };
  }

  Future<Map<String, dynamic>> _exportTraining() async {
    final plans = await _db.select(_db.workoutPlans).get();
    final days = await _db.select(_db.workoutDays).get();
    final customEx = await (_db.select(_db.exercises)
          ..where((t) => t.isCustom.equals(true)))
        .get();
    final sessions = await _db.select(_db.workoutSessions).get();
    final sets = await _db.select(_db.workoutSets).get();
    final dayEx = await _db.select(_db.workoutDayExercises).get();
    return {
      'workoutPlans': plans.map((r) => {
            'id': r.id, 'name': r.name, 'description': r.description,
            'isActive': r.isActive, 'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'workoutDays': days.map((r) => {
            'id': r.id, 'planId': r.planId, 'name': r.name,
            'dayOfWeek': r.dayOfWeek, 'sortOrder': r.sortOrder,
          }).toList(),
      'customExercises': customEx.map((r) => {
            'id': r.id, 'name': r.name, 'muscleGroup': r.muscleGroup,
            'primaryMuscles': r.primaryMuscles,
            'secondaryMuscles': r.secondaryMuscles,
            'difficulty': r.difficulty, 'mechanic': r.mechanic,
            'force': r.force, 'equipment': r.equipment,
            'instructions': r.instructions,
            'isBookmarked': r.isBookmarked,
          }).toList(),
      'workoutSessions': sessions.map((r) => {
            'id': r.id, 'planId': r.planId, 'dayId': r.dayId,
            'startedAt': r.startedAt.toIso8601String(),
            'completedAt': r.completedAt?.toIso8601String(),
            'notes': r.notes, 'durationSeconds': r.durationSeconds,
          }).toList(),
      'workoutSets': sets.map((r) => {
            'id': r.id, 'sessionId': r.sessionId, 'exerciseId': r.exerciseId,
            'setNumber': r.setNumber, 'weightKg': r.weightKg, 'reps': r.reps,
            'durationSeconds': r.durationSeconds, 'setType': r.setType,
            'isWarmup': r.isWarmup,
          }).toList(),
      'workoutDayExercises': dayEx.map((r) => {
            'id': r.id, 'dayId': r.dayId, 'exerciseId': r.exerciseId,
            'sortOrder': r.sortOrder, 'defaultSets': r.defaultSets,
            'defaultReps': r.defaultReps, 'notes': r.notes,
            'defaultRestSeconds': r.defaultRestSeconds,
            'progressionType': r.progressionType,
            'supersetGroup': r.supersetGroup,
          }).toList(),
    };
  }

  Future<Map<String, dynamic>> _exportHealth() async {
    final weights = await _db.select(_db.weightLogs).get();
    final measurements = await _db.select(_db.bodyMeasurements).get();
    final sleep = await _db.select(_db.sleepLogs).get();
    final mood = await _db.select(_db.moodLogs).get();
    return {
      'weightLogs': weights.map((r) => {
            'id': r.id, 'weightKg': r.weightKg,
            'logDate': r.logDate.toIso8601String(), 'note': r.note,
          }).toList(),
      'bodyMeasurements': measurements.map((r) => {
            'id': r.id, 'logDate': r.logDate.toIso8601String(),
            'chestCm': r.chestCm, 'waistCm': r.waistCm, 'hipsCm': r.hipsCm,
            'thighCm': r.thighCm, 'bicepCm': r.bicepCm,
            'shoulderCm': r.shoulderCm, 'calfCm': r.calfCm,
            'neckCm': r.neckCm, 'bodyFatPct': r.bodyFatPct,
          }).toList(),
      'sleepLogs': sleep.map((r) => {
            'id': r.id, 'bedtime': r.bedtime.toIso8601String(),
            'wakeTime': r.wakeTime.toIso8601String(),
            'qualityStars': r.qualityStars, 'note': r.note,
          }).toList(),
      'moodLogs': mood.map((r) => {
            'id': r.id, 'logDate': r.logDate.toIso8601String(),
            'moodScore': r.moodScore, 'note': r.note,
          }).toList(),
    };
  }

  Future<Map<String, dynamic>> _exportNutrition() async {
    final logs = await _db.select(_db.nutritionLogs).get();
    final templates = await _db.select(_db.mealTemplates).get();
    final water = await _db.select(_db.waterLogs).get();
    final shopping = await _db.select(_db.shoppingListItems).get();
    return {
      'nutritionLogs': logs.map((r) => {
            'id': r.id, 'logDate': r.logDate.toIso8601String(),
            'mealType': r.mealType, 'foodName': r.foodName,
            'amountGrams': r.amountGrams, 'kcal': r.kcal,
            'proteinG': r.proteinG, 'carbsG': r.carbsG, 'fatG': r.fatG,
            'templateId': r.templateId,
          }).toList(),
      'mealTemplates': templates.map((r) => {
            'id': r.id, 'name': r.name, 'category': r.category,
            'servingSizeG': r.servingSizeG, 'kcalPer100g': r.kcalPer100g,
            'proteinPer100g': r.proteinPer100g,
            'carbsPer100g': r.carbsPer100g, 'fatPer100g': r.fatPer100g,
            'isCustom': r.isCustom, 'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'waterLogs': water.map((r) => {
            'id': r.id, 'logDate': r.logDate.toIso8601String(),
            'amountMl': r.amountMl,
          }).toList(),
      'shoppingListItems': shopping.map((r) => {
            'id': r.id, 'name': r.name, 'category': r.category,
            'quantity': r.quantity, 'unit': r.unit, 'checked': r.checked,
            'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
    };
  }

  Future<Map<String, dynamic>> _exportSupplements() async {
    final supps = await _db.select(_db.supplements).get();
    final logs = await _db.select(_db.supplementLogs).get();
    return {
      'supplements': supps.map((r) => {
            'id': r.id, 'name': r.name, 'category': r.category,
            'dosageAmount': r.dosageAmount, 'dosageUnit': r.dosageUnit,
            'timings': r.timings, 'notes': r.notes, 'isActive': r.isActive,
            'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'supplementLogs': logs.map((r) => {
            'id': r.id, 'supplementId': r.supplementId,
            'takenAt': r.takenAt.toIso8601String(), 'timing': r.timing,
          }).toList(),
    };
  }

  Future<Map<String, dynamic>> _exportMedication() async {
    final meds = await _db.select(_db.medications).get();
    final logs = await _db.select(_db.medicationLogs).get();
    return {
      'medications': meds.map((r) => {
            'id': r.id, 'name': r.name, 'dosage': r.dosage, 'form': r.form,
            'timings': r.timings, 'instructions': r.instructions,
            'isActive': r.isActive, 'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'medicationLogs': logs.map((r) => {
            'id': r.id, 'medicationId': r.medicationId,
            'scheduledAt': r.scheduledAt.toIso8601String(),
            'takenAt': r.takenAt?.toIso8601String(),
            'taken': r.taken, 'skipped': r.skipped,
          }).toList(),
    };
  }

  Future<Map<String, dynamic>> _exportAbstinence() async {
    final trackers = await _db.select(_db.abstinenceTrackers).get();
    final events = await _db.select(_db.abstinenceEvents).get();
    return {
      'abstinenceTrackers': trackers.map((r) => {
            'id': r.id, 'name': r.name, 'emoji': r.emoji,
            'startDate': r.startDate.toIso8601String(), 'note': r.note,
            'isActive': r.isActive, 'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'abstinenceEvents': events.map((r) => {
            'id': r.id, 'trackerId': r.trackerId, 'type': r.type,
            'eventDate': r.eventDate.toIso8601String(), 'note': r.note,
          }).toList(),
    };
  }

  Future<Map<String, dynamic>> _exportBudget() async {
    final cats = await _db.select(_db.budgetCategories).get();
    final txns = await _db.select(_db.transactions).get();
    final savings = await _db.select(_db.savingsGoals).get();
    final debts = await _db.select(_db.debts).get();
    return {
      'budgetCategories': cats.map((r) => {
            'id': r.id, 'name': r.name, 'emoji': r.emoji,
            'monthlyLimit': r.monthlyLimit, 'color': r.color,
            'isExpense': r.isExpense,
          }).toList(),
      'transactions': txns.map((r) => {
            'id': r.id, 'amount': r.amount, 'description': r.description,
            'categoryId': r.categoryId, 'type': r.type,
            'date': r.date.toIso8601String(), 'note': r.note,
            'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'savingsGoals': savings.map((r) => {
            'id': r.id, 'name': r.name, 'targetAmount': r.targetAmount,
            'currentAmount': r.currentAmount,
            'targetDate': r.targetDate?.toIso8601String(), 'note': r.note,
            'isCompleted': r.isCompleted,
            'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
      'debts': debts.map((r) => {
            'id': r.id, 'creditor': r.creditor,
            'originalAmount': r.originalAmount,
            'remainingAmount': r.remainingAmount,
            'interestRate': r.interestRate,
            'dueDate': r.dueDate?.toIso8601String(), 'note': r.note,
            'isPaidOff': r.isPaidOff,
            'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
    };
  }

  Future<Map<String, dynamic>> _exportPeriod() async {
    final entries = await _db.select(_db.periodEntries).get();
    final calcs = await _db.select(_db.cycleCalculations).get();
    final symptoms = await _db.select(_db.periodSymptoms).get();
    return {
      'periodEntries': entries.map((r) => {
            'id': r.id, 'startDate': r.startDate.toIso8601String(),
            'endDate': r.endDate?.toIso8601String(),
            'flowIntensity': r.flowIntensity, 'note': r.note,
          }).toList(),
      'cycleCalculations': calcs.map((r) => {
            'id': r.id, 'periodEntryId': r.periodEntryId,
            'cycleLength': r.cycleLength,
            'ovulationDate': r.ovulationDate?.toIso8601String(),
            'fertileStart': r.fertileStart?.toIso8601String(),
            'fertileEnd': r.fertileEnd?.toIso8601String(),
            'nextPeriodPredicted': r.nextPeriodPredicted?.toIso8601String(),
          }).toList(),
      'periodSymptoms': symptoms.map((r) => {
            'id': r.id, 'logDate': r.logDate.toIso8601String(),
            'symptom': r.symptom, 'intensity': r.intensity, 'note': r.note,
          }).toList(),
    };
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<ImportResult> pickAndImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) {
        return const ImportResult(error: 'no_file');
      }
      final path = result.files.single.path;
      if (path == null) return const ImportResult(error: 'no_file');
      final content = await File(path).readAsString();
      return _importFromJson(content);
    } catch (e) {
      return ImportResult(error: e.toString());
    }
  }

  Future<ImportResult> _importFromJson(String content) async {
    try {
      final data = json.decode(content) as Map<String, dynamic>;
      if ((data['version'] as int?) != 1) {
        return const ImportResult(error: 'unsupported_version');
      }
      final modules = (data['modules'] as Map<String, dynamic>?) ?? {};
      int total = 0;
      for (final entry in modules.entries) {
        final m = entry.value as Map<String, dynamic>;
        switch (entry.key) {
          case 'planning':
            total += await _importPlanning(m);
          case 'training':
            total += await _importTraining(m);
          case 'health':
            total += await _importHealth(m);
          case 'nutrition':
            total += await _importNutrition(m);
          case 'supplements':
            total += await _importSupplements(m);
          case 'medication':
            total += await _importMedication(m);
          case 'abstinence':
            total += await _importAbstinence(m);
          case 'budget':
            total += await _importBudget(m);
          case 'period':
            total += await _importPeriod(m);
        }
      }
      return ImportResult(total: total);
    } catch (e) {
      return ImportResult(error: e.toString());
    }
  }

  Future<int> _importPlanning(Map<String, dynamic> m) async {
    int count = 0;
    for (final r in _rows(m, 'appointments')) {
      await _db.into(_db.appointments).insertOnConflictUpdate(AppointmentsCompanion(
        id: Value(r['id'] as int),
        title: Value(r['title'] as String),
        description: Value(r['description'] as String?),
        location: Value(r['location'] as String?),
        startTime: Value(DateTime.parse(r['startTime'] as String)),
        endTime: Value(r['endTime'] != null ? DateTime.parse(r['endTime'] as String) : null),
        allDay: Value(r['allDay'] as bool? ?? false),
        recurrenceRule: Value(r['recurrenceRule'] as String?),
        color: Value(r['color'] as int?),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'todos')) {
      await _db.into(_db.todos).insertOnConflictUpdate(TodosCompanion(
        id: Value(r['id'] as int),
        title: Value(r['title'] as String),
        note: Value(r['note'] as String?),
        priority: Value(r['priority'] as int? ?? 0),
        done: Value(r['done'] as bool? ?? false),
        dueDate: Value(r['dueDate'] != null ? DateTime.parse(r['dueDate'] as String) : null),
        completedAt: Value(r['completedAt'] != null ? DateTime.parse(r['completedAt'] as String) : null),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
        listName: Value(r['listName'] as String?),
      ));
      count++;
    }
    for (final r in _rows(m, 'todoSubItems')) {
      await _db.into(_db.todoSubItems).insertOnConflictUpdate(TodoSubItemsCompanion(
        id: Value(r['id'] as int),
        todoId: Value(r['todoId'] as int),
        title: Value(r['title'] as String),
        done: Value(r['done'] as bool? ?? false),
        sortOrder: Value(r['sortOrder'] as int? ?? 0),
      ));
      count++;
    }
    for (final r in _rows(m, 'goals')) {
      await _db.into(_db.goals).insertOnConflictUpdate(GoalsCompanion(
        id: Value(r['id'] as int),
        title: Value(r['title'] as String),
        description: Value(r['description'] as String?),
        targetValue: Value(r['targetValue'] as int?),
        currentValue: Value(r['currentValue'] as int? ?? 0),
        unit: Value(r['unit'] as String?),
        targetDate: Value(r['targetDate'] != null ? DateTime.parse(r['targetDate'] as String) : null),
        done: Value(r['done'] as bool? ?? false),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'subTasks')) {
      await _db.into(_db.subTasks).insertOnConflictUpdate(SubTasksCompanion(
        id: Value(r['id'] as int),
        goalId: Value(r['goalId'] as int),
        title: Value(r['title'] as String),
        done: Value(r['done'] as bool? ?? false),
        sortOrder: Value(r['sortOrder'] as int? ?? 0),
      ));
      count++;
    }
    for (final r in _rows(m, 'habits')) {
      await _db.into(_db.habits).insertOnConflictUpdate(HabitsCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        emoji: Value(r['emoji'] as String?),
        frequency: Value(r['frequency'] as String? ?? 'daily'),
        reminderTime: Value(r['reminderTime'] as String?),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'habitLogs')) {
      await _db.into(_db.habitLogs).insertOnConflictUpdate(HabitLogsCompanion(
        id: Value(r['id'] as int),
        habitId: Value(r['habitId'] as int),
        logDate: Value(DateTime.parse(r['logDate'] as String)),
        done: Value(r['done'] as bool? ?? true),
      ));
      count++;
    }
    return count;
  }

  Future<int> _importTraining(Map<String, dynamic> m) async {
    int count = 0;
    for (final r in _rows(m, 'workoutPlans')) {
      await _db.into(_db.workoutPlans).insertOnConflictUpdate(WorkoutPlansCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        description: Value(r['description'] as String?),
        isActive: Value(r['isActive'] as bool? ?? false),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'workoutDays')) {
      await _db.into(_db.workoutDays).insertOnConflictUpdate(WorkoutDaysCompanion(
        id: Value(r['id'] as int),
        planId: Value(r['planId'] as int),
        name: Value(r['name'] as String),
        dayOfWeek: Value(r['dayOfWeek'] as int?),
        sortOrder: Value(r['sortOrder'] as int? ?? 0),
      ));
      count++;
    }
    for (final r in _rows(m, 'customExercises')) {
      await _db.into(_db.exercises).insertOnConflictUpdate(ExercisesCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        muscleGroup: Value(r['muscleGroup'] as String),
        primaryMuscles: Value(r['primaryMuscles'] as String? ?? '[]'),
        secondaryMuscles: Value(r['secondaryMuscles'] as String? ?? '[]'),
        difficulty: Value(r['difficulty'] as String?),
        mechanic: Value(r['mechanic'] as String?),
        force: Value(r['force'] as String?),
        equipment: Value(r['equipment'] as String?),
        instructions: Value(r['instructions'] as String?),
        isCustom: const Value(true),
        isBookmarked: Value(r['isBookmarked'] as bool? ?? false),
      ));
      count++;
    }
    for (final r in _rows(m, 'workoutSessions')) {
      await _db.into(_db.workoutSessions).insertOnConflictUpdate(WorkoutSessionsCompanion(
        id: Value(r['id'] as int),
        planId: Value(r['planId'] as int?),
        dayId: Value(r['dayId'] as int?),
        startedAt: Value(DateTime.parse(r['startedAt'] as String)),
        completedAt: Value(r['completedAt'] != null ? DateTime.parse(r['completedAt'] as String) : null),
        notes: Value(r['notes'] as String?),
        durationSeconds: Value(r['durationSeconds'] as int?),
      ));
      count++;
    }
    for (final r in _rows(m, 'workoutSets')) {
      await _db.into(_db.workoutSets).insertOnConflictUpdate(WorkoutSetsCompanion(
        id: Value(r['id'] as int),
        sessionId: Value(r['sessionId'] as int),
        exerciseId: Value(r['exerciseId'] as int),
        setNumber: Value(r['setNumber'] as int),
        weightKg: Value((r['weightKg'] as num?)?.toDouble()),
        reps: Value(r['reps'] as int?),
        durationSeconds: Value(r['durationSeconds'] as int?),
        setType: Value(r['setType'] as String? ?? 'normal'),
        isWarmup: Value(r['isWarmup'] as bool? ?? false),
      ));
      count++;
    }
    for (final r in _rows(m, 'workoutDayExercises')) {
      await _db.into(_db.workoutDayExercises).insertOnConflictUpdate(WorkoutDayExercisesCompanion(
        id: Value(r['id'] as int),
        dayId: Value(r['dayId'] as int),
        exerciseId: Value(r['exerciseId'] as int),
        sortOrder: Value(r['sortOrder'] as int? ?? 0),
        defaultSets: Value(r['defaultSets'] as int? ?? 3),
        defaultReps: Value(r['defaultReps'] as int? ?? 10),
        notes: Value(r['notes'] as String?),
        defaultRestSeconds: Value(r['defaultRestSeconds'] as int? ?? 90),
        progressionType: Value(r['progressionType'] as String? ?? 'linear'),
        supersetGroup: Value(r['supersetGroup'] as int?),
      ));
      count++;
    }
    return count;
  }

  Future<int> _importHealth(Map<String, dynamic> m) async {
    int count = 0;
    for (final r in _rows(m, 'weightLogs')) {
      await _db.into(_db.weightLogs).insertOnConflictUpdate(WeightLogsCompanion(
        id: Value(r['id'] as int),
        weightKg: Value((r['weightKg'] as num).toDouble()),
        logDate: Value(DateTime.parse(r['logDate'] as String)),
        note: Value(r['note'] as String?),
      ));
      count++;
    }
    for (final r in _rows(m, 'bodyMeasurements')) {
      await _db.into(_db.bodyMeasurements).insertOnConflictUpdate(BodyMeasurementsCompanion(
        id: Value(r['id'] as int),
        logDate: Value(DateTime.parse(r['logDate'] as String)),
        chestCm: Value((r['chestCm'] as num?)?.toDouble()),
        waistCm: Value((r['waistCm'] as num?)?.toDouble()),
        hipsCm: Value((r['hipsCm'] as num?)?.toDouble()),
        thighCm: Value((r['thighCm'] as num?)?.toDouble()),
        bicepCm: Value((r['bicepCm'] as num?)?.toDouble()),
        shoulderCm: Value((r['shoulderCm'] as num?)?.toDouble()),
        calfCm: Value((r['calfCm'] as num?)?.toDouble()),
        neckCm: Value((r['neckCm'] as num?)?.toDouble()),
        bodyFatPct: Value((r['bodyFatPct'] as num?)?.toDouble()),
      ));
      count++;
    }
    for (final r in _rows(m, 'sleepLogs')) {
      await _db.into(_db.sleepLogs).insertOnConflictUpdate(SleepLogsCompanion(
        id: Value(r['id'] as int),
        bedtime: Value(DateTime.parse(r['bedtime'] as String)),
        wakeTime: Value(DateTime.parse(r['wakeTime'] as String)),
        qualityStars: Value(r['qualityStars'] as int?),
        note: Value(r['note'] as String?),
      ));
      count++;
    }
    for (final r in _rows(m, 'moodLogs')) {
      await _db.into(_db.moodLogs).insertOnConflictUpdate(MoodLogsCompanion(
        id: Value(r['id'] as int),
        logDate: Value(DateTime.parse(r['logDate'] as String)),
        moodScore: Value(r['moodScore'] as int),
        note: Value(r['note'] as String?),
      ));
      count++;
    }
    return count;
  }

  Future<int> _importNutrition(Map<String, dynamic> m) async {
    int count = 0;
    for (final r in _rows(m, 'mealTemplates')) {
      await _db.into(_db.mealTemplates).insertOnConflictUpdate(MealTemplatesCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        category: Value(r['category'] as String?),
        servingSizeG: Value((r['servingSizeG'] as num).toDouble()),
        kcalPer100g: Value((r['kcalPer100g'] as num).toDouble()),
        proteinPer100g: Value((r['proteinPer100g'] as num? ?? 0).toDouble()),
        carbsPer100g: Value((r['carbsPer100g'] as num? ?? 0).toDouble()),
        fatPer100g: Value((r['fatPer100g'] as num? ?? 0).toDouble()),
        isCustom: Value(r['isCustom'] as bool? ?? false),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'nutritionLogs')) {
      await _db.into(_db.nutritionLogs).insertOnConflictUpdate(NutritionLogsCompanion(
        id: Value(r['id'] as int),
        logDate: Value(DateTime.parse(r['logDate'] as String)),
        mealType: Value(r['mealType'] as String? ?? 'snack'),
        foodName: Value(r['foodName'] as String),
        amountGrams: Value((r['amountGrams'] as num).toDouble()),
        kcal: Value((r['kcal'] as num).toDouble()),
        proteinG: Value((r['proteinG'] as num? ?? 0).toDouble()),
        carbsG: Value((r['carbsG'] as num? ?? 0).toDouble()),
        fatG: Value((r['fatG'] as num? ?? 0).toDouble()),
        templateId: Value(r['templateId'] as int?),
      ));
      count++;
    }
    for (final r in _rows(m, 'waterLogs')) {
      await _db.into(_db.waterLogs).insertOnConflictUpdate(WaterLogsCompanion(
        id: Value(r['id'] as int),
        logDate: Value(DateTime.parse(r['logDate'] as String)),
        amountMl: Value(r['amountMl'] as int),
      ));
      count++;
    }
    for (final r in _rows(m, 'shoppingListItems')) {
      await _db.into(_db.shoppingListItems).insertOnConflictUpdate(ShoppingListItemsCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        category: Value(r['category'] as String?),
        quantity: Value((r['quantity'] as num?)?.toDouble()),
        unit: Value(r['unit'] as String?),
        checked: Value(r['checked'] as bool? ?? false),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    return count;
  }

  Future<int> _importSupplements(Map<String, dynamic> m) async {
    int count = 0;
    for (final r in _rows(m, 'supplements')) {
      await _db.into(_db.supplements).insertOnConflictUpdate(SupplementsCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        category: Value(r['category'] as String?),
        dosageAmount: Value(r['dosageAmount'] as String?),
        dosageUnit: Value(r['dosageUnit'] as String?),
        timings: Value(r['timings'] as String? ?? '[]'),
        notes: Value(r['notes'] as String?),
        isActive: Value(r['isActive'] as bool? ?? true),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'supplementLogs')) {
      await _db.into(_db.supplementLogs).insertOnConflictUpdate(SupplementLogsCompanion(
        id: Value(r['id'] as int),
        supplementId: Value(r['supplementId'] as int),
        takenAt: Value(DateTime.parse(r['takenAt'] as String)),
        timing: Value(r['timing'] as String?),
      ));
      count++;
    }
    return count;
  }

  Future<int> _importMedication(Map<String, dynamic> m) async {
    int count = 0;
    for (final r in _rows(m, 'medications')) {
      await _db.into(_db.medications).insertOnConflictUpdate(MedicationsCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        dosage: Value(r['dosage'] as String?),
        form: Value(r['form'] as String?),
        timings: Value(r['timings'] as String? ?? '[]'),
        instructions: Value(r['instructions'] as String?),
        isActive: Value(r['isActive'] as bool? ?? true),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'medicationLogs')) {
      await _db.into(_db.medicationLogs).insertOnConflictUpdate(MedicationLogsCompanion(
        id: Value(r['id'] as int),
        medicationId: Value(r['medicationId'] as int),
        scheduledAt: Value(DateTime.parse(r['scheduledAt'] as String)),
        takenAt: Value(r['takenAt'] != null ? DateTime.parse(r['takenAt'] as String) : null),
        taken: Value(r['taken'] as bool? ?? false),
        skipped: Value(r['skipped'] as bool? ?? false),
      ));
      count++;
    }
    return count;
  }

  Future<int> _importAbstinence(Map<String, dynamic> m) async {
    int count = 0;
    for (final r in _rows(m, 'abstinenceTrackers')) {
      await _db.into(_db.abstinenceTrackers).insertOnConflictUpdate(AbstinenceTrackersCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        emoji: Value(r['emoji'] as String?),
        startDate: Value(DateTime.parse(r['startDate'] as String)),
        note: Value(r['note'] as String?),
        isActive: Value(r['isActive'] as bool? ?? true),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'abstinenceEvents')) {
      await _db.into(_db.abstinenceEvents).insertOnConflictUpdate(AbstinenceEventsCompanion(
        id: Value(r['id'] as int),
        trackerId: Value(r['trackerId'] as int),
        type: Value(r['type'] as String),
        eventDate: Value(DateTime.parse(r['eventDate'] as String)),
        note: Value(r['note'] as String?),
      ));
      count++;
    }
    return count;
  }

  Future<int> _importBudget(Map<String, dynamic> m) async {
    int count = 0;
    for (final r in _rows(m, 'budgetCategories')) {
      await _db.into(_db.budgetCategories).insertOnConflictUpdate(BudgetCategoriesCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        emoji: Value(r['emoji'] as String?),
        monthlyLimit: Value((r['monthlyLimit'] as num?)?.toDouble()),
        color: Value(r['color'] as int?),
        isExpense: Value(r['isExpense'] as bool? ?? true),
      ));
      count++;
    }
    for (final r in _rows(m, 'transactions')) {
      await _db.into(_db.transactions).insertOnConflictUpdate(TransactionsCompanion(
        id: Value(r['id'] as int),
        amount: Value((r['amount'] as num).toDouble()),
        description: Value(r['description'] as String),
        categoryId: Value(r['categoryId'] as int?),
        type: Value(r['type'] as String? ?? 'expense'),
        date: Value(DateTime.parse(r['date'] as String)),
        note: Value(r['note'] as String?),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'savingsGoals')) {
      await _db.into(_db.savingsGoals).insertOnConflictUpdate(SavingsGoalsCompanion(
        id: Value(r['id'] as int),
        name: Value(r['name'] as String),
        targetAmount: Value((r['targetAmount'] as num).toDouble()),
        currentAmount: Value((r['currentAmount'] as num? ?? 0).toDouble()),
        targetDate: Value(r['targetDate'] != null ? DateTime.parse(r['targetDate'] as String) : null),
        note: Value(r['note'] as String?),
        isCompleted: Value(r['isCompleted'] as bool? ?? false),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    for (final r in _rows(m, 'debts')) {
      await _db.into(_db.debts).insertOnConflictUpdate(DebtsCompanion(
        id: Value(r['id'] as int),
        creditor: Value(r['creditor'] as String),
        originalAmount: Value((r['originalAmount'] as num).toDouble()),
        remainingAmount: Value((r['remainingAmount'] as num).toDouble()),
        interestRate: Value((r['interestRate'] as num? ?? 0).toDouble()),
        dueDate: Value(r['dueDate'] != null ? DateTime.parse(r['dueDate'] as String) : null),
        note: Value(r['note'] as String?),
        isPaidOff: Value(r['isPaidOff'] as bool? ?? false),
        createdAt: Value(DateTime.parse(r['createdAt'] as String)),
      ));
      count++;
    }
    return count;
  }

  Future<int> _importPeriod(Map<String, dynamic> m) async {
    int count = 0;
    for (final r in _rows(m, 'periodEntries')) {
      await _db.into(_db.periodEntries).insertOnConflictUpdate(PeriodEntriesCompanion(
        id: Value(r['id'] as int),
        startDate: Value(DateTime.parse(r['startDate'] as String)),
        endDate: Value(r['endDate'] != null ? DateTime.parse(r['endDate'] as String) : null),
        flowIntensity: Value(r['flowIntensity'] as int? ?? 2),
        note: Value(r['note'] as String?),
      ));
      count++;
    }
    for (final r in _rows(m, 'cycleCalculations')) {
      await _db.into(_db.cycleCalculations).insertOnConflictUpdate(CycleCalculationsCompanion(
        id: Value(r['id'] as int),
        periodEntryId: Value(r['periodEntryId'] as int),
        cycleLength: Value(r['cycleLength'] as int),
        ovulationDate: Value(r['ovulationDate'] != null ? DateTime.parse(r['ovulationDate'] as String) : null),
        fertileStart: Value(r['fertileStart'] != null ? DateTime.parse(r['fertileStart'] as String) : null),
        fertileEnd: Value(r['fertileEnd'] != null ? DateTime.parse(r['fertileEnd'] as String) : null),
        nextPeriodPredicted: Value(r['nextPeriodPredicted'] != null ? DateTime.parse(r['nextPeriodPredicted'] as String) : null),
      ));
      count++;
    }
    for (final r in _rows(m, 'periodSymptoms')) {
      await _db.into(_db.periodSymptoms).insertOnConflictUpdate(PeriodSymptomsCompanion(
        id: Value(r['id'] as int),
        logDate: Value(DateTime.parse(r['logDate'] as String)),
        symptom: Value(r['symptom'] as String),
        intensity: Value(r['intensity'] as int? ?? 1),
        note: Value(r['note'] as String?),
      ));
      count++;
    }
    return count;
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> m, String key) {
    final raw = m[key];
    if (raw == null) return [];
    return (raw as List).cast<Map<String, dynamic>>();
  }
}

final dataImportExportServiceProvider = Provider<DataImportExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return DataImportExportService(db);
});
