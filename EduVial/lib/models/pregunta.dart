class Pregunta {
  final int id;
  final String txt;
  final String cat;
  final String lvl;
  final int lawid;

  Pregunta({
    required this.id,
    required this.txt,
    required this.cat,
    required this.lvl,
    required this.lawid,
  });

  factory Pregunta.fromJson(Map<String, dynamic> json) {
    return Pregunta(
      id: json['id'],
      txt: json['txt'],
      cat: json['cat'],
      lvl: json['lvl'],
      lawid: json['lawid'],
    );
  }
}

class OpcionRespuesta {
  final int id;
  final int qid;
  final String txt;
  final bool? correct; // Puede ser null si no viene en la respuesta

  OpcionRespuesta({
    required this.id,
    required this.qid,
    required this.txt,
    this.correct,
  });

  factory OpcionRespuesta.fromJson(Map<String, dynamic> json) {
    return OpcionRespuesta(
      id: json['id'],
      qid:json['qid'],
      txt: json['txt'],
      correct: json['correct'],
    );
  }
}