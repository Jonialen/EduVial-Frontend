import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eduvial/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login exitoso muestra SnackBar y navega a Menu', (WidgetTester tester) async {
    // Inicia la app
    app.main();
    await tester.pumpAndSettle();

    // Encuentra campos por etiqueta
    final emailField = find.widgetWithText(TextField, 'Correo electrónico');
    final passwordField = find.widgetWithText(TextField, 'Contraseña');

    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);

    // Introduce credenciales de prueba
    await tester.enterText(emailField, 'usuario@test.com');
    await tester.enterText(passwordField, '123456');
    await tester.pumpAndSettle();

    // Toca el botón Iniciar sesión
    final loginButton = find.widgetWithText(ElevatedButton, 'Iniciar sesión');
    expect(loginButton, findsOneWidget);

    await tester.tap(loginButton);

    // Espera que se procese la acción y muestre SnackBar
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Da tiempo a mostrar SnackBar y navegar

    await tester.pump(const Duration(seconds: 1)); // Espera a que aparezca SnackBar

    expect(find.text('¡Inicio de sesión exitoso!'), findsOneWidget);


    //
  });
}
