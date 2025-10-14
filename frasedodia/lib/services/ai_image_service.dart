import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class AIImageService {
  static const String _pollinationsBaseUrl = 'https://image.pollinations.ai/prompt';
  static const String _openAIBaseUrl = 'https://api.openai.com/v1/images/generations';
  static const String _openAIKey = 'SUA_CHAVE_OPENAI_AQUI'; // Substitua pela sua chave
  
  final cacheManager = DefaultCacheManager();
  
  // Gerar imagem usando Pollinations (Gratuito)
  Future<String?> gerarImagemPollinations(String prompt, {String? seed}) async {
    try {
      // Pollinations retorna diretamente a URL da imagem
      final url = Uri.parse('$_pollinationsBaseUrl/${Uri.encodeComponent(prompt)}');
      final queryParams = {
        'width': '1024',
        'height': '1024',
        'seed': seed ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'nologo': 'true',
      };
      
      final urlWithParams = url.replace(queryParameters: queryParams);
      
      // Fazer cache da imagem
      await cacheManager.downloadFile(urlWithParams.toString());
      
      return urlWithParams.toString();
    } catch (e) {
      print('Erro ao gerar imagem Pollinations: $e');
      return null;
    }
  }
  
  // Gerar imagem usando OpenAI DALL-E (Pago, mas melhor qualidade)
  Future<String?> gerarImagemOpenAI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_openAIBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data'][0]['url'];
        
        // Fazer cache da imagem
        await cacheManager.downloadFile(imageUrl);
        
        return imageUrl;
      } else {
        print('Erro OpenAI: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erro ao gerar imagem OpenAI: $e');
      return null;
    }
  }
  
  // Limpar cache antigo
  Future<void> limparCache() async {
    await cacheManager.emptyCache();
  }
  
  // Verificar tamanho do cache (CORRIGIDO)
  Future<int> obterTamanhoCache() async {
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/image_cache');
      
      if (await cacheDir.exists()) {
        int totalSize = 0;
        await for (var file in cacheDir.list(recursive: true)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
        return totalSize;
      }
      return 0;
    } catch (e) {
      print('Erro ao calcular tamanho do cache: $e');
      return 0;
    }
  }
  
  // Contar número de arquivos em cache
  Future<int> contarArquivosCache() async {
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/image_cache');
      
      if (await cacheDir.exists()) {
        int count = 0;
        await for (var file in cacheDir.list(recursive: true)) {
          if (file is File) {
            count++;
          }
        }
        return count;
      }
      return 0;
    } catch (e) {
      print('Erro ao contar arquivos do cache: $e');
      return 0;
    }
  }
}
