import 'package:flutter/material.dart';
import 'mensagens_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categorias = [
    {'nome': 'Bom Dia', 'icone': Icons.wb_sunny, 'cor': Colors.orange},
    {'nome': 'Boa Noite', 'icone': Icons.nightlight_round, 'cor': Colors.indigo},
    {'nome': 'Natal', 'icone': Icons.celebration, 'cor': Colors.red},
    {'nome': 'Ano Novo', 'icone': Icons.cake, 'cor': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mensagens Prontas'),
        backgroundColor: Colors.blue,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: categorias.map((cat) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MensagensScreen(
                    categoria: cat['nome'],
                  ),
                ),
              );
            },
            child: Card(
              elevation: 4,
              color: cat['cor'],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icone'], size: 50, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    cat['nome'],
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
