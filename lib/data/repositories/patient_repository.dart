import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/database/local_database.dart';
import '../models/patient_model.dart';
import 'history_repository.dart';

class PatientRepository {
  final _historyRepository = HistoryRepository();

  Future<List<PatientModel>> findAll() async {
    final db = await LocalDatabase.database;
    final rows = await db.query('patients', orderBy: 'created_at DESC');
    return rows.map(PatientModel.fromDatabase).toList();
  }

  Stream<List<PatientModel>> watchAll() async* {
    yield await findAll();
    yield* LocalDatabase.patientsChanged.asyncMap((_) => findAll());
  }

  Future<PatientModel> save(PatientModel patient) async {
    final db = await LocalDatabase.database;
    final isNew = patient.id.isEmpty;
    final id = isNew ? LocalDatabase.newId() : patient.id;
    final savedPatient = patient.copyWith(id: id);

    await db.insert(
      'patients',
      savedPatient.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _historyRepository.add(
      patientId: savedPatient.id,
      type: isNew ? 'patient_created' : 'patient_updated',
      description: isNew
          ? 'Paciente ${savedPatient.name} cadastrado.'
          : 'Paciente ${savedPatient.name} atualizado.',
    );
    LocalDatabase.notifyPatientsChanged();
    return savedPatient;
  }

  Future<void> delete(String id) async {
    final db = await LocalDatabase.database;
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
    await _historyRepository.add(
      patientId: null,
      type: 'patient_deleted',
      description: 'Paciente removido.',
    );
    LocalDatabase.notifyPatientsChanged();
  }
}
