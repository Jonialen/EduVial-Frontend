import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eduvial/main.dart' as app;
import 'package:eduvial/views/menu.dart';
import 'package:eduvial/views/simulation_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testEmail = 'Dann@';
  const testPassword = '123';

  Future<void> waitUntil(
      WidgetTester tester,
      Finder finder, {
        Duration step = const Duration(milliseconds: 300),
        int maxSteps = 60, // ~18s
        String? debugLabel,
      }) async {
    for (var i = 0; i < maxSteps; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(step);
    }
    expect(finder, findsOneWidget, reason: 'Timeout esperando $debugLabel');
  }

  testWidgets('Login → Menu → Principiantes → Simulaciones → 3 preguntas',
          (WidgetTester tester) async {
        // 1) Arranca y login
        app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Correo electrónico'),
          testEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Contraseña'),
          testPassword,
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));

        // Evita pumpAndSettle por animaciones periódicas (mascota)
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        // 2) Confirma llegada al Menú
        await waitUntil(tester, find.byType(Menu), debugLabel: 'Menu');
        await tester.pump(const Duration(seconds: 1)); // pausa visual

        // 3) Abrir PRINCIPIANTES
        final principiantesLabel = find.text('PRINCIPIANTES');
        await waitUntil(tester, principiantesLabel, debugLabel: 'label "PRINCIPIANTES"');

        final principiantesSection = find.ancestor(
          of: principiantesLabel,
          matching: find.byType(Column),
        ).first;

        final principiantesInkWell = find.descendant(
          of: principiantesSection,
          matching: find.byType(InkWell),
        ).first;

        await tester.ensureVisible(principiantesInkWell);
        await tester.tap(principiantesInkWell);
        await tester.pump(const Duration(milliseconds: 600)); // anim 300ms + colchón
        await tester.pump(const Duration(milliseconds: 400));

        // 4) Entrar a "Simulaciones"
        final simulacionesLabel = find.text('Simulaciones');
        await waitUntil(tester, simulacionesLabel, debugLabel: 'label "Simulaciones"');

        final simulacionesColumn = find.ancestor(
          of: simulacionesLabel,
          matching: find.byType(Column),
        ).first;

        final simulacionesInkWell = find.descendant(
          of: simulacionesColumn,
          matching: find.byType(InkWell),
        ).first;

        await tester.ensureVisible(simulacionesInkWell);
        await tester.tap(simulacionesInkWell);

        // 5) Esperar navegación a SimulationScreen
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await waitUntil(tester, find.byType(SimulationScreen), debugLabel: 'SimulationScreen');

        // 6) Esperar carga de preguntas (puede mostrar CircularProgressIndicator primero)
        // Espera a ver "Opciones:" o una ListTile
        final opcionesTitulo = find.text('Opciones:');
        final algunaOpcion = find.byType(ListTile);
        if (opcionesTitulo.evaluate().isEmpty && algunaOpcion.evaluate().isEmpty) {
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 1));
        }
        await waitUntil(tester, find.byType(Scaffold), debugLabel: 'Scaffold de SimulationScreen');

        // Si hay error de backend, permite reintentar
        if (find.textContaining('Error').evaluate().isNotEmpty) {
          final reintentarBtn = find.widgetWithText(ElevatedButton, 'Reintentar');
          if (reintentarBtn.evaluate().isNotEmpty) {
            await tester.tap(reintentarBtn);
            await tester.pump(const Duration(seconds: 1));
            await tester.pump(const Duration(seconds: 1));
          }
        }

        // 7) Responder 3 preguntas (elige la primera opción, verifica y siguiente)
        for (int i = 0; i < 3; i++) {
          // Espera que haya al menos una opción
          await waitUntil(tester, find.byType(ListTile), debugLabel: 'ListTile opción');

          // Toca la primera opción
          final firstOption = find.byType(ListTile).first;
          await tester.ensureVisible(firstOption);
          await tester.tap(firstOption);
          await tester.pump(const Duration(milliseconds: 400));

          // Toca "Verificar respuesta"
          final verificarBtn = find.widgetWithText(ElevatedButton, 'Verificar respuesta');
          await waitUntil(tester, verificarBtn, debugLabel: 'Botón "Verificar respuesta"');
          await tester.tap(verificarBtn);
          await tester.pump(const Duration(milliseconds: 700)); // muestra colores

          // Toca "Siguiente Pregunta"
          final siguienteBtn = find.widgetWithText(ElevatedButton, 'Siguiente Pregunta');
          await waitUntil(tester, siguienteBtn, debugLabel: 'Botón "Siguiente Pregunta"');
          await tester.tap(siguienteBtn);

          // Pausa visual y permite que cargue la siguiente
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(milliseconds: 800));
        }

        // 8) Llegado aquí, completó 3 iteraciones sin fallar
        //
        expect(find.byType(SimulationScreen), findsOneWidget);
      });
}

