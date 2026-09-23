// Prueba extremo a extremo de la capa de servicios del cliente contra el
// backend Flask real. Requiere el servidor corriendo (python backend/run.py).
//
//   flutter test test/api_e2e_test.dart
//
// Se omite automáticamente si /api/health no responde.
import 'dart:io';

import 'package:diapce_aplicationn/core/api_client.dart';
import 'package:diapce_aplicationn/models/project_data.dart';
import 'package:diapce_aplicationn/services/auth_service.dart';
import 'package:diapce_aplicationn/services/experiment_service.dart';
import 'package:diapce_aplicationn/services/mixture_service.dart';
import 'package:diapce_aplicationn/services/project_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test bloquea HTTP real por defecto; aquí se necesita el backend.
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});

  final api = ApiClient();
  late bool backendUp;

  setUpAll(() async {
    try {
      await api.get('/api/health');
      backendUp = true;
    } on ApiException {
      backendUp = false;
    }
  });

  test('flujo completo: registro → opciones → predicción → proyecto → borrado', () async {
    if (!backendUp) {
      markTestSkipped('Backend no disponible en ${api.baseUrl}');
      return;
    }

    final email = 'e2e_${DateTime.now().millisecondsSinceEpoch}@diapce.test';
    final auth = AuthService();
    final user = await auth.register(email, 'secret123');
    expect(user.email, email);
    expect(api.hasToken, isTrue);

    // Correo duplicado → 409 con mensaje de la API.
    await expectLater(
      auth.register(email, 'secret123'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );

    // Selección en cascada desde el servidor.
    final experiments = ExperimentService();
    final temps = await experiments.getTemperatures();
    expect(temps, containsAll([10, 25, 32]));
    final hums = await experiments.getHumidityOptions(25);
    expect(hums, isNotEmpty);
    final acs = await experiments.getRelacionAcOptions(25, hums.first);
    expect(acs, isNotEmpty);
    final aditivos = await experiments.getAditivoOptions(25, hums.first, acs.first);
    expect(aditivos, isNotEmpty);

    // Modelo matemático en el servidor.
    final pred = await experiments.predict(
      temperatura: 25,
      humedad: hums.first,
      relacionAc: acs.first,
      aditivoId: aditivos.first.id,
    );
    expect(pred.dias28, isNotNull);
    expect(pred.numMuestras, greaterThan(0));
    expect(pred.formula, startsWith('f(t) ='));

    final ranges = await experiments.optimalRanges(35);
    expect(ranges.combinacionesQueCumplen, greaterThan(0));

    // Dosificación ACI 211.1 propuesta sin persistir.
    final preview = await MixtureService().previewMixture('Tuneles', 0.45, 6);
    expect(preview.id, isNull);
    expect((preview.materials ?? []).map((m) => m.materialName), contains('Aditivo Plastificante'));

    // Crear proyecto: el servidor completa predicciones y crea la mezcla.
    final projects = ProjectService();
    final created = await projects.createProject(ProjectData(
      projectName: 'E2E Túnel',
      workType: 'Tuneles',
      resistanceTarget: 45,
      temperature: 25,
      humidity: hums.first,
      relacionAc: acs.first,
      aditivoId: aditivos.first.id,
    ));
    expect(created.id, isNotNull);
    expect(created.mixtureId, isNotNull);
    expect(created.resistenciaPredicha28d, pred.dias28);

    final mixture = await MixtureService().getMixtureWithMaterials(created.mixtureId!);
    expect(mixture!.name, startsWith('Dosificación ACI 211.1'));

    // Reporte PDF del proyecto (botón «Descargar»).
    final pdf = await projects.downloadReport(created.id!);
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');

    final list = await projects.getAllProjects();
    expect(list.map((p) => p.id), contains(created.id));

    expect(await projects.deleteProject(created.id!), isTrue);
    expect(await projects.getProjectById(created.id!), isNull);

    await auth.logout();
    expect(api.hasToken, isFalse);
    await expectLater(
      projects.getAllProjects(),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
  });
}
