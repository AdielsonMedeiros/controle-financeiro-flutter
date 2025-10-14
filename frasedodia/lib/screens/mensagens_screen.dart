import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/mensagem.dart';
import '../services/mensagens_service.dart';
import '../services/favoritos_service.dart';

class MensagensScreen extends StatefulWidget {
  final String categoria;
  MensagensScreen({required this.categoria});

  @override
  _MensagensScreenState createState() => _MensagensScreenState();
}

class _MensagensScreenState extends State<MensagensScreen> {
  final MensagensService _mensagensService = MensagensService();
  final FavoritosService _favoritosService = FavoritosService();
  List<Mensagem> mensagens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarMensagens();
  }

  Future<void> _carregarMensagens() async {
    setState(() => _isLoading = true);
    final msgs = await _mensagensService.carregarMensagens(widget.categoria);
    setState(() {
      mensagens = msgs;
      _isLoading = false;
    });
  }

  Future<void> _regenerarImagem(int index) async {
    setState(() => _isLoading = true);
    final mensagemAtualizada = await _mensagensService.regenerarImagem(
      mensagens[index], 
      index
    );
    setState(() {
      mensagens[index] = mensagemAtualizada;
      _isLoading = false;
    });
    await _mensagensService.salvarMensagens(widget.categoria, mensagens);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoria),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarMensagens,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: mensagens.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final mensagem = mensagens[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagem com texto sobreposto usando Stack
                      if (mensagem.imagemUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                          child: Stack(
                            children: [
                              // Imagem de fundo
                              CachedNetworkImage(
                                imageUrl: mensagem.imagemUrl!,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 250,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 250,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error, size: 50),
                                ),
                              ),
                              
                              // Gradiente para melhor legibilidade do texto
                              Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Texto sobreposto
                              Positioned(
                                bottom: 20,
                                left: 16,
                                right: 16,
                                child: Text(
                                  mensagem.texto,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                        color: Colors.black87,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Botões de ação
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Regenerar imagem
                            TextButton.icon(
                              icon: Icon(Icons.auto_awesome, size: 20),
                              label: Text('Regenerar'),
                              onPressed: () => _regenerarImagem(index),
                            ),
                            
                            // Favoritar
                            TextButton.icon(
                              icon: Icon(
                                mensagem.favorita ? Icons.favorite : Icons.favorite_border,
                                color: mensagem.favorita ? Colors.red : null,
                                size: 20,
                              ),
                              label: Text('Favorito'),
                              onPressed: () async {
                                setState(() {
                                  mensagem.favorita = !mensagem.favorita;
                                });
                                if (mensagem.favorita) {
                                  await _favoritosService.salvarFavorito(mensagem);
                                } else {
                                  await _favoritosService.removerFavorito(mensagem.id);
                                }
                              },
                            ),
                            
                            // Compartilhar
                            TextButton.icon(
                              icon: Icon(Icons.share, size: 20),
                              label: Text('Compartilhar'),
                              onPressed: () {
                                Share.share('${mensagem.texto}\n\n${mensagem.imagemUrl ?? ""}');
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Indicador de gerado por IA
                      if (mensagem.promptIA != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8, right: 16),
                          child: Text(
                            'Gerado por IA',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
