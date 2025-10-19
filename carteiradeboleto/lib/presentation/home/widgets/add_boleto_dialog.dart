import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../data/models/boleto_model.dart';
import '../../../data/services/firestore_service.dart';
import 'barcode_scanner_screen.dart';
import '../../../theme/financial_gradients.dart';

class AddBoletoDialog extends StatefulWidget {
  const AddBoletoDialog({super.key});

  @override
  State<AddBoletoDialog> createState() => _AddBoletoDialogState();
}

class _AddBoletoDialogState extends State<AddBoletoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _tagController = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // LÓGICA DE COR PARA O INPUT
    // ALTERAÇÃO: Usa uma cor do tema que oferece melhor contraste no modo claro.
    final fillColor = isDarkMode
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.6)
        : theme.colorScheme.surfaceContainerHighest;

    // Tema de decoração para os campos de texto
    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 40,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF059669).withOpacity(0.2),
                    const Color(0xFFD97706).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 56, 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF059669).withOpacity(0.3),
                                const Color(0xFF0891B2).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF059669).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            PhosphorIcons.receiptFill,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Novo Boleto',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Preencha os dados abaixo',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: Icon(
                        PhosphorIcons.x,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Fechar',
                    ),
                  ),
                ],
              ),
            ),
            // Formulário
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _descriptionController,
                        decoration: inputDecorationTheme.copyWith(
                          labelText: 'Descrição',
                          helperText: 'Ex: Conta de luz, Internet, etc.',
                          prefixIcon: Icon(PhosphorIcons.textAa, color: theme.colorScheme.primary),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Campo obrigatório' : null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _valueController,
                        decoration: inputDecorationTheme.copyWith(
                          labelText: 'Valor',
                          hintText: '150,75',
                          helperText: 'Digite o valor do boleto',
                          prefixIcon: Icon(PhosphorIcons.currencyCircleDollar, color: theme.colorScheme.primary),
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) =>
                            value!.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _dueDateController,
                        decoration: inputDecorationTheme.copyWith(
                          labelText: 'Data de Vencimento',
                          hintText: 'Selecione a data',
                          helperText: 'Toque para abrir o calendário',
                          prefixIcon: Icon(PhosphorIcons.calendarCheck, color: theme.colorScheme.primary),
                        ),
                        readOnly: true,
                              onTap: () async {
                                _selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: theme.copyWith(
                                        dialogTheme: DialogThemeData(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (_selectedDate != null) {
                                  _dueDateController.text =
                                      DateFormat('dd/MM/yyyy')
                                          .format(_selectedDate!);
                                }
                              },
                        validator: (value) =>
                            value!.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _tagController,
                        decoration: inputDecorationTheme.copyWith(
                          labelText: 'Categoria',
                          helperText: 'Ex: Contas, Lazer, Saúde',
                          prefixIcon: Icon(PhosphorIcons.tagSimple, color: theme.colorScheme.primary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'A categoria é obrigatória';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: inputDecorationTheme.copyWith(
                          labelText: 'Código de Barras',
                          helperText: 'Opcional - Toque na câmera para escanear',
                          prefixIcon: Icon(PhosphorIcons.barcode, color: theme.colorScheme.primary),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: Icon(
                                PhosphorIcons.camera,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              tooltip: 'Escanear código',
                              onPressed: () async {
                                final barcode = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BarcodeScannerScreen(),
                                  ),
                                );
                                if (barcode != null) {
                                  _barcodeController.text = barcode;
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer com botões
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981),
                            const Color(0xFF059669),
                            const Color(0xFF047857),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(PhosphorIcons.check, size: 18),
                        label: const Text('Adicionar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final newBoleto = Boleto(
                            id: '',
                            description: _descriptionController.text.trim(),
                            value: double.parse(_valueController.text
                                .replaceFirst(',', '.')
                                .trim()),
                            dueDate: _selectedDate!,
                            tag: _tagController.text.trim(),
                            barcode: _barcodeController.text.trim(),
                            isPaid: false,
                          );
                          await FirestoreService().addBoleto(newBoleto);

                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(PhosphorIcons.checkCircle,
                                        color: Colors.white),
                                    const SizedBox(width: 12),
                                    const Text('Boleto adicionado com sucesso!'),
                                  ],
                                ),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

