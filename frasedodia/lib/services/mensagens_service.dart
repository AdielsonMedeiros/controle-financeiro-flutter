import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mensagem.dart';
import 'ai_image_service.dart';

class MensagensService {
  final AIImageService _aiService = AIImageService();
  
  // Prompts pré-definidos para cada categoria
  final Map<String, List<String>> _promptsPorCategoria = {
    'Bom Dia': [
      'beautiful sunrise over mountains, birds flying, warm orange and pink sky, peaceful morning, digital art',
      'coffee cup on window sill, morning sunlight, flowers in vase, cozy atmosphere, warm colors',
      'sunflowers field at dawn, golden light, clear blue sky, peaceful landscape, nature photography',
      'beach sunrise, waves, seagulls, orange sky reflecting on water, peaceful scene',
    ],
    'Boa Noite': [
      'starry night sky, full moon, silhouette of trees, peaceful atmosphere, deep blue colors',
      'city lights at night, stars above, calm peaceful scene, purple and blue tones',
      'cozy bedroom window view, night sky, stars, candles, warm peaceful ambiance',
      'northern lights, aurora borealis, night sky, mountains silhouette, magical atmosphere',
    ],
    'Natal': [
      'christmas tree with colorful lights, presents underneath, snow falling, warm cozy room',
      'santa claus sleigh flying over snowy village, full moon, magical christmas night',
      'christmas wreath on door, snow, warm lights, festive decorations, cozy atmosphere',
      'fireplace with christmas stockings, decorated tree, gifts, warm family scene',
    ],
    'Ano Novo': [
      'colorful fireworks exploding in night sky, city skyline, celebration atmosphere',
      'champagne glasses toasting, golden confetti, bokeh lights, festive celebration',
      'clock showing midnight, fireworks, new year celebration, sparkles and lights',
      'party celebration, gold and silver decorations, balloons, confetti, festive lights',
    ],
  };
  
  // Gerar imagem para uma mensagem específica
  Future<String?> gerarImagemParaMensagem(String categoria, int index) async {
    final prompts = _promptsPorCategoria[categoria] ?? [];
    if (prompts.isEmpty) return null;
    
    // Usar um prompt diferente baseado no índice
    final prompt = prompts[index % prompts.length];
    
    // Usar seed único para cada mensagem
    final seed = '${categoria}_$index';
    
    return await _aiService.gerarImagemPollinations(prompt, seed: seed);
  }
  
  // Carregar mensagens com imagens
  Future<List<Mensagem>> carregarMensagens(String categoria) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mensagens_$categoria';
    final mensagensJson = prefs.getString(key);
    
    if (mensagensJson != null) {
      final List<dynamic> lista = jsonDecode(mensagensJson);
      return lista.map((json) => Mensagem.fromJson(json)).toList();
    }
    
    // Se não houver mensagens salvas, criar mensagens padrão
    return await _criarMensagensPadrao(categoria);
  }
  
  // Criar mensagens padrão com imagens geradas
  Future<List<Mensagem>> _criarMensagensPadrao(String categoria) async {
    List<Mensagem> mensagens = [];
    
    switch (categoria) {
      case 'Bom Dia':
        final textos = [
          'Bom dia! Que seu dia seja cheio de alegrias!',
          'Acorde com gratidão e energia positiva!',
          'Que Deus abençoe seu dia!',
          'Um novo dia, novas oportunidades!',
        ];
        
        for (int i = 0; i < textos.length; i++) {
          final imagemUrl = await gerarImagemParaMensagem('Bom Dia', i);
          mensagens.add(Mensagem(
            id: '${i + 1}',
            texto: textos[i],
            categoria: categoria,
            imagemUrl: imagemUrl,
            promptIA: _promptsPorCategoria['Bom Dia']![i],
          ));
        }
        break;
      
      case 'Boa Noite':
        final textos = [
          'Boa noite! Que seus sonhos sejam doces!',
          'Durma bem e recarregue suas energias!',
          'Que a paz te acompanhe nesta noite!',
          'Descanse e tenha uma noite abençoada!',
        ];
        
        for (int i = 0; i < textos.length; i++) {
          final imagemUrl = await gerarImagemParaMensagem('Boa Noite', i);
          mensagens.add(Mensagem(
            id: '${i + 4}',
            texto: textos[i],
            categoria: categoria,
            imagemUrl: imagemUrl,
            promptIA: _promptsPorCategoria['Boa Noite']![i],
          ));
        }
        break;
      
      case 'Natal':
        final textos = [
          'Feliz Natal! Que esta data traga amor e paz!',
          'Que o espírito natalino ilumine seu lar!',
          'Feliz Natal! Muita alegria e união!',
          'Que o Natal renove sua fé e esperança!',
        ];
        
        for (int i = 0; i < textos.length; i++) {
          final imagemUrl = await gerarImagemParaMensagem('Natal', i);
          mensagens.add(Mensagem(
            id: '${i + 8}',
            texto: textos[i],
            categoria: categoria,
            imagemUrl: imagemUrl,
            promptIA: _promptsPorCategoria['Natal']![i],
          ));
        }
        break;
      
      case 'Ano Novo':
        final textos = [
          'Feliz Ano Novo! Que 2026 seja incrível!',
          'Novos começos, novas conquistas!',
          'Que o ano novo traga realizações!',
          'Feliz 2026! Muita saúde e prosperidade!',
        ];
        
        for (int i = 0; i < textos.length; i++) {
          final imagemUrl = await gerarImagemParaMensagem('Ano Novo', i);
          mensagens.add(Mensagem(
            id: '${i + 12}',
            texto: textos[i],
            categoria: categoria,
            imagemUrl: imagemUrl,
            promptIA: _promptsPorCategoria['Ano Novo']![i],
          ));
        }
        break;
    }
    
    // Salvar mensagens
    await salvarMensagens(categoria, mensagens);
    return mensagens;
  }
  
  // Salvar mensagens
  Future<void> salvarMensagens(String categoria, List<Mensagem> mensagens) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mensagens_$categoria';
    final mensagensJson = jsonEncode(mensagens.map((m) => m.toJson()).toList());
    await prefs.setString(key, mensagensJson);
  }
  
  // Regenerar imagem para uma mensagem
  Future<Mensagem> regenerarImagem(Mensagem mensagem, int index) async {
    // Usar seed diferente a cada regeneração
    final newSeed = '${mensagem.categoria}_${index}_${DateTime.now().millisecondsSinceEpoch}';
    final prompts = _promptsPorCategoria[mensagem.categoria];
    final prompt = prompts != null && prompts.isNotEmpty 
        ? prompts[index % prompts.length] 
        : mensagem.categoria;
    
    final novaImagemUrl = await _aiService.gerarImagemPollinations(prompt, seed: newSeed);
    
    return mensagem.copyWith(imagemUrl: novaImagemUrl);
  }
}
