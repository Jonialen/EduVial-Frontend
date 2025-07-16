import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduvial/views/login.dart';

void main() {
  testWidgets('LoginScreen renderiza correctamente y permite escribir en los campos',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: LoginScreen(),
          ),
        );

        // Verifica que los campos de texto estén
        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.text('Correo electrónico'), findsOneWidget);
        expect(find.text('Contraseña'), findsOneWidget);

        // Verifica que los botones estén
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(find.text('Ingresar como invitado'), findsOneWidget);
        expect(find.text('¿No tienes cuenta? Regístrate'), findsOneWidget);

        // Escribir en los campos de texto
        await tester.enterText(find.byType(TextField).at(0), 'test@email.com');
        await tester.enterText(find.byType(TextField).at(1), '123456');

        // Verifica que se escribió correctamente
        expect(find.text('test@email.com'), findsOneWidget);
        expect(find.text('123456'), findsOneWidget);
      });
}
