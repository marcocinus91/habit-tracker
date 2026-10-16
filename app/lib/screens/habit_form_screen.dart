import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/date_format.dart';
import '../state/providers.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key});

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  static const _dayLabels = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const _palette = [
    Color(0xFF4F8EF7),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFFF3B30),
    Color(0xFFAF52DE),
    Color(0xFF00C7BE),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🎯');
  final _selectedDays = <int>{};
  Color _color = _palette.first;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  String _toHex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final days = _selectedDays.length == 7
          ? <int>[]
          : (_selectedDays.toList()..sort());
      await ref
          .read(habitsProvider.notifier)
          .create(
            name: _nameController.text.trim(),
            emoji: _emojiController.text.trim(),
            color: _toHex(_color),
            scheduledWeekdays: days,
            startDate: formatDate(DateTime.now()),
          );
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salvataggio non riuscito, riprova.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo habit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci un nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emojiController,
              decoration: const InputDecoration(labelText: 'Emoji'),
              maxLength: 1,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Inserisci un\'emoji'
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Colore', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      backgroundColor: c,
                      radius: 18,
                      child: _color == c
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Giorni', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              _selectedDays.isEmpty
                  ? 'Nessuno selezionato: ogni giorno'
                  : 'Solo i giorni selezionati',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(_dayLabels[i]),
                    selected: _selectedDays.contains(i + 1),
                    onSelected: (on) => setState(() {
                      on
                          ? _selectedDays.add(i + 1)
                          : _selectedDays.remove(i + 1);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
