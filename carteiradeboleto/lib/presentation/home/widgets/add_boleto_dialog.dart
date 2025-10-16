import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../data/models/boleto_model.dart';
import '../../../data/services/firestore_service.dart';
import 'barcode_scanner_screen.dart';

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
      fillColor: fillColor, // APLICA A COR DEFINIDA ACIMA
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Adicionar Novo Boleto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: inputDecorationTheme.copyWith(
                  labelText: 'Descrição',
                  prefixIcon: const Icon(PhosphorIcons.textAlignLeft),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: inputDecorationTheme.copyWith(
                  labelText: 'Valor',
                  hintText: 'ex: 150.75',
                  prefixIcon: const Icon(PhosphorIcons.coins),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dueDateController,
                decoration: inputDecorationTheme.copyWith(
                  labelText: 'Data de Vencimento',
                  prefixIcon: const Icon(PhosphorIcons.calendar),
                ),
                readOnly: true,
                onTap: () async {
                  _selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (_selectedDate != null) {
                    _dueDateController.text =
                        DateFormat('dd/MM/yyyy').format(_selectedDate!);
                  }
                },
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagController,
                decoration: inputDecorationTheme.copyWith(
                  labelText: 'Tag',
                  hintText: 'ex: Contas, Lazer',
                  prefixIcon: const Icon(PhosphorIcons.tag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'A tag é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: inputDecorationTheme.copyWith(
                  labelText: 'Código de Barras (Opcional)',
                  prefixIcon: const Icon(PhosphorIcons.barcode),
                  suffixIcon: IconButton(
                    icon: const Icon(PhosphorIcons.camera),
                    tooltip: 'Escanear código',
                    onPressed: () async {
                      final barcode = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarcodeScannerScreen(),
                        ),
                      );
                      if (barcode != null) {
                        _barcodeController.text = barcode;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newBoleto = Boleto(
                      id: '',
                      description: _descriptionController.text.trim(),
                      value: double.parse(
                          _valueController.text.replaceFirst(',', '.').trim()),
                      dueDate: _selectedDate!,
                      tag: _tagController.text.trim(),
                      barcode: _barcodeController.text.trim(),
                      isPaid: false,
                    );
                    await FirestoreService().addBoleto(newBoleto);

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

