import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mensagem.dart';

class FavoritosService {
  Future<void> salvarFavorito(Mensagem mensagem) async {
    final prefs = await SharedPreferences.getInstance();
    List<Mensagem> favoritos = await carregarFavoritos();
    
    // Verificar se já não existe
    if (!favoritos.any((m) => m.id == mensagem.id)) {
      favoritos.add(mensagem);
      final favoritosJson = jsonEncode(favoritos.map((m) => m.toJson()).toList());
      await prefs.setString('favoritos', favoritosJson);
    }
  }

  Future<List<Mensagem>> carregarFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritosJson = prefs.getString('favoritos');
    
    if (favoritosJson != null) {
      final List<dynamic> lista = jsonDecode(favoritosJson);
      return lista.map((json) => Mensagem.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> removerFavorito(String mensagemId) async {
    final prefs = await SharedPreferences.getInstance();
    List<Mensagem> favoritos = await carregarFavoritos();
    
    favoritos.removeWhere((m) => m.id == mensagemId);
    final favoritosJson = jsonEncode(favoritos.map((m) => m.toJson()).toList());
    await prefs.setString('favoritos', favoritosJson);
  }
  
  Future<bool> isFavorito(String mensagemId) async {
    final favoritos = await carregarFavoritos();
    return favoritos.any((m) => m.id == mensagemId);
  }
}
