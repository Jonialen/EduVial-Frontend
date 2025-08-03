import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eduvial/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login sin credenciales muestra mensaje de validación',
          (WidgetTester tester) async {
        // Arranca la app y espera a que cargue
        app.main();
        await tester.pumpAndSettle();

        // Pulsa "Iniciar sesión" sin introducir email ni contraseña
        await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));

        // Espera la animación del SnackBar
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Comprueba que muestra el mensaje de validación
        expect(find.text('Por favor completa todos los campos'), findsOneWidget);
      });
}