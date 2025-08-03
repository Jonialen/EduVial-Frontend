import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eduvial/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Registro sin nivel muestra mensaje de validación',
          (WidgetTester tester) async {
        // Arranca la app y espera a que cargue
        app.main();
        await tester.pumpAndSettle();

        // Navega a la pantalla de registro
        await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
        await tester.pumpAndSettle();

        // Rellena nombre, correo y contraseña
        await tester.enterText(find.byType(TextField).at(0), 'Juan Pérez');
        await tester.enterText(find.byType(TextField).at(1), 'juan@test.com');
        await tester.enterText(find.byType(TextField).at(2), '123456');
        await tester.pumpAndSettle();

        // Pulsa "Registrarme" sin seleccionar nivel
        await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarme'));

        // Espera la animación del SnackBar
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Comprueba que muestra el mensaje de validación
        expect(find.text('Por favor selecciona un nivel'), findsOneWidget);
      });
}
