import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/financial_transaction.dart';

class TransactionItem extends StatefulWidget {
  final FinancialTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.type == 'income';
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
        child: Dismissible(
          key: Key(widget.transaction.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => widget.onDelete(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.error,
                ],
              ),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 1),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onEdit,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'transaction_icon_${widget.transaction.id}',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isIncome
                                  ? [
                                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                    ]
                                  : [
                                      Theme.of(context).colorScheme.error.withOpacity(0.2),
                                      Theme.of(context).colorScheme.error.withOpacity(0.1),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (isIncome
                                        ? Theme.of(context).colorScheme.secondary
                                        : Theme.of(context).colorScheme.error)
                                    .withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: isIncome
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.error,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.transaction.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.transaction.category,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd/MM/yy').format(widget.transaction.createdAt),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'} ${formatter.format(widget.transaction.amount)}',
                            style: TextStyle(
                              color: isIncome
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
