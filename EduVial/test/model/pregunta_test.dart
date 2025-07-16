import 'package:flutter_test/flutter_test.dart';
import 'package:eduvial/models/pregunta.dart';

void main() {
  group('Modelo Pregunta', () {
    test('fromJson crea un objeto Pregunta correctamente', () {
      final json = {
        'id': 1,
        'txt': '¿Cuál es la velocidad máxima?',
        'cat': 'Velocidad',
        'lvl': 'Facil',
        'lawid': 123,
      };

      final pregunta = Pregunta.fromJson(json);

      expect(pregunta.id, 1);
      expect(pregunta.txt, '¿Cuál es la velocidad máxima?');
      expect(pregunta.cat, 'Velocidad');
      expect(pregunta.lvl, 'Facil');
      expect(pregunta.lawid, 123);
    });
  });

  group('Modelo OpcionRespuesta', () {
    test('fromJson crea un objeto OpcionRespuesta correctamente con correct true', () {
      final json = {
        'id': 10,
        'qid': 1,
        'txt': '50 km/h',
        'correct': true,
      };

      final opcion = OpcionRespuesta.fromJson(json);

      expect(opcion.id, 10);
      expect(opcion.qid, 1);
      expect(opcion.txt, '50 km/h');
      expect(opcion.correct, true);
    });

    test('fromJson crea un objeto OpcionRespuesta correctamente con correct null', () {
      final json = {
        'id': 11,
        'qid': 1,
        'txt': '60 km/h',
        'correct': null,
      };

      final opcion = OpcionRespuesta.fromJson(json);

      expect(opcion.id, 11);
      expect(opcion.qid, 1);
      expect(opcion.txt, '60 km/h');
      expect(opcion.correct, null);
    });
  });
}
