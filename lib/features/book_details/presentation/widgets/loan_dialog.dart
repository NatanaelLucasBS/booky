import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Diálogo para cadastrar empréstimo de livro a um amigo.
class LoanDialog extends StatefulWidget {
  final Future<bool> Function({
    required String borrowerName,
    required String borrowerContact,
    required DateTime loanDate,
    required DateTime expectedReturnDate,
  }) onConfirm;

  const LoanDialog({super.key, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required Future<bool> Function({
      required String borrowerName,
      required String borrowerContact,
      required DateTime loanDate,
      required DateTime expectedReturnDate,
    }) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => LoanDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends State<LoanDialog> {
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  DateTime _loanDate = DateTime.now();
  DateTime _expectedReturnDate = DateTime.now().add(const Duration(days: 14));
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _selectDate({required bool isLoanDate}) async {
    final initial = isLoanDate ? _loanDate : _expectedReturnDate;
    final first = isLoanDate ? DateTime(2020) : _loanDate;
    final last = DateTime(2035);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        if (isLoanDate) {
          _loanDate = picked;
          if (_expectedReturnDate.isBefore(_loanDate)) {
            _expectedReturnDate = _loanDate.add(const Duration(days: 7));
          }
        } else {
          _expectedReturnDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final contact = _contactCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o nome do amigo.'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      return;
    }
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o contato do amigo.'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await widget.onConfirm(
      borrowerName: name,
      borrowerContact: contact,
      loanDate: _loanDate,
      expectedReturnDate: _expectedReturnDate,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Emprestar Livro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do Amigo *',
                hintText: 'Ex: Mariana Silva',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactCtrl,
              decoration: const InputDecoration(
                labelText: 'Contato (Telefone / WhatsApp / E-mail)',
                hintText: 'Ex: (84) 99999-9999',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(isLoanDate: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data do Empréstimo'),
                      child: Text(_formatDate(_loanDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(isLoanDate: false),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data de Devolução'),
                      child: Text(_formatDate(_expectedReturnDate)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lightCream),
                )
              : const Text('CONFIRMAR EMPRÉSTIMO'),
        ),
      ],
    );
  }
}
