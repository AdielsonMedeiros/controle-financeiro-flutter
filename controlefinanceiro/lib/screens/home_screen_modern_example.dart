// EXEMPLO DE IMPLEMENTAÇÃO - home_screen com layout moderno
// Este arquivo serve como referência para implementar as melhorias

import 'package:flutter/material.dart';
import '../widgets/modern_header.dart';
import '../widgets/modern_summary_section.dart';
import '../widgets/animated_fab.dart';
import '../widgets/animated_card.dart';
import '../widgets/shimmer_loading.dart';

class HomeScreenModernExample extends StatelessWidget {
  const HomeScreenModernExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar transparente e moderna
      appBar: AppBar(
        title: const Text('Controle Financeiro'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notificações',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
            tooltip: 'Configurações',
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header com saudação
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: ModernHeader(
                userName: 'João Silva',
                userPhoto: null,
                onProfileTap: () {
                  // Navegar para perfil
                },
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          
          // Resumo financeiro moderno
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ModernSummarySection(
                income: 5000.00,
                expenses: 3200.00,
                balance: 1800.00,
                incomePercentage: 12.5,
                expensesPercentage: -8.3,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          
          // Seção de insights
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedCard(
                gradient: [
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
                ],
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dica do Dia',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Você gastou 15% menos este mês! Continue assim! 🎉',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          
          // Header da lista de transações
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Transações Recentes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Lista de transações
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Aqui você usaria seus dados reais
                  // Este é apenas um exemplo
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: ShimmerLoading(
                      width: double.infinity,
                      height: 80,
                    ),
                  );
                },
                childCount: 5,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      
      // FAB animado
      floatingActionButton: AnimatedFAB(
        onPressed: () {
          // Adicionar transação
        },
        icon: Icons.add_rounded,
        label: 'Nova',
      ),
    );
  }
}
