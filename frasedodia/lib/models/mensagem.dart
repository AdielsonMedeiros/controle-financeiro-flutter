class Mensagem {
  final String id;
  final String texto;
  final String categoria;
  final String? imagemUrl; // URL da imagem gerada pela IA
  final String? promptIA; // Prompt usado para gerar a imagem
  bool favorita;

  Mensagem({
    required this.id,
    required this.texto,
    required this.categoria,
    this.imagemUrl,
    this.promptIA,
    this.favorita = false,
  });

  // Converter para JSON para salvar no SharedPreferences
  Map<String, dynamic> toJson() => {
    'id': id,
    'texto': texto,
    'categoria': categoria,
    'imagemUrl': imagemUrl,
    'promptIA': promptIA,
    'favorita': favorita,
  };

  // Criar objeto a partir de JSON
  factory Mensagem.fromJson(Map<String, dynamic> json) => Mensagem(
    id: json['id'],
    texto: json['texto'],
    categoria: json['categoria'],
    imagemUrl: json['imagemUrl'],
    promptIA: json['promptIA'],
    favorita: json['favorita'] ?? false,
  );

  // Criar cópia com valores alterados
  Mensagem copyWith({
    String? id,
    String? texto,
    String? categoria,
    String? imagemUrl,
    String? promptIA,
    bool? favorita,
  }) {
    return Mensagem(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      categoria: categoria ?? this.categoria,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      promptIA: promptIA ?? this.promptIA,
      favorita: favorita ?? this.favorita,
    );
  }
}
