class Pregunta {
  final int id;
  final String txt;
  final String cat;   // <- viene como "category" del API
  final String lvl;   // <- local, lo respetamos
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
      id: json['id'] ?? json['question_id'],
      txt: json['txt'] ?? json['question_text'],
      cat: json['cat'] ?? json['category'] ?? '',
      lvl: json['lvl'] ?? '',          // 👈 no lo calculamos aquí, lo dejas como usas hoy
      lawid: json['lawid'] ?? json['law_id'] ?? 0,
    );
  }
}

class OpcionRespuesta {
  final int id;
  final int qid;
  final String txt;
  final bool? correct;

  OpcionRespuesta({
    required this.id,
    required this.qid,
    required this.txt,
    this.correct,
  });

  factory OpcionRespuesta.fromJson(Map<String, dynamic> json) {
    return OpcionRespuesta(
      id: json['id'] ?? json['option_id'],
      qid: json['qid'] ?? json['question_id'],
      txt: json['txt'] ?? json['option_text'],
      correct: json['correct'] ?? json['is_correct'],
    );
  }
}
