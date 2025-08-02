import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eduvial/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Registro exitoso desde LoginScreen sin usar keys', (WidgetTester tester) async {
    // Inicia la app
    app.main();
    await tester.pumpAndSettle();

    // Navega a RegisterScreen tocando el texto del botón
    final goToRegister = find.text('¿No tienes cuenta? Regístrate');
    expect(goToRegister, findsOneWidget);
    await tester.tap(goToRegister);
    await tester.pumpAndSettle();

    // Encuentra los TextFields (nombre, correo, contraseña)
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(3));

    // Ingresa texto en cada TextField
    await tester.enterText(textFields.at(0), 'Juan Pérez');         // Nombre
    await tester.enterText(textFields.at(1), 'juan@test.com');      // Correo
    await tester.enterText(textFields.at(2), '123456');             // Contraseña
    await tester.pumpAndSettle();

    // Abre menú desplegable para seleccionar nivel
    final popupMenu = find.byType(PopupMenuButton<String>);
    expect(popupMenu, findsOneWidget);
    await tester.tap(popupMenu);
    await tester.pumpAndSettle();

    // Selecciona "Principiante"
    final opcionPrincipiante = find.text('Principiante').last;
    expect(opcionPrincipiante, findsOneWidget);
    await tester.tap(opcionPrincipiante);
    await tester.pumpAndSettle();

    // Toca botón "Registrarme"
    final registerButton = find.widgetWithText(ElevatedButton, 'Registrarme');
    expect(registerButton, findsOneWidget);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    // Busca el SnackBar y su texto
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.descendant(of: find.byType(SnackBar), matching: find.text('Registro exitoso')), findsOneWidget);
  });
}
