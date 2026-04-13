import 'package:flutter/material.dart';

import '../models/models.dart';
import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _sceneType = 'Portrait créatif';
  String _mood = 'Énergique';
  double _duration = 30;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _openPreview() {
    final draft = TakeDraft(
      title: _titleController.text.isEmpty ? 'Mon nouveau Take30' : _titleController.text,
      description: _descriptionController.text.isEmpty
          ? 'Une scène courte préparée pour le défi.'
          : _descriptionController.text,
      sceneType: _sceneType,
      duration: _duration.round(),
      mood: _mood,
    );

    Navigator.pushNamed(context, AppRouter.preview, arguments: draft);
  }

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Créer un Take',
      children: [
        const SectionCard(
          title: 'Préparer la scène',
          subtitle: 'Renseigne les infos du take avant la prévisualisation.',
          icon: Icons.videocam_outlined,
        ),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Titre de la prise'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description courte'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _sceneType,
          decoration: const InputDecoration(labelText: 'Type de scène'),
          items: const [
            DropdownMenuItem(value: 'Portrait créatif', child: Text('Portrait créatif')),
            DropdownMenuItem(value: 'Cuisine rapide', child: Text('Cuisine rapide')),
            DropdownMenuItem(value: 'Mini reportage', child: Text('Mini reportage')),
          ],
          onChanged: (value) => setState(() => _sceneType = value ?? _sceneType),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _mood,
          decoration: const InputDecoration(labelText: 'Ambiance'),
          items: const [
            DropdownMenuItem(value: 'Énergique', child: Text('Énergique')),
            DropdownMenuItem(value: 'Cinématique', child: Text('Cinématique')),
            DropdownMenuItem(value: 'Douce', child: Text('Douce')),
          ],
          onChanged: (value) => setState(() => _mood = value ?? _mood),
        ),
        const SizedBox(height: 12),
        Text('Durée cible : ${_duration.round()} min'),
        Slider(
          min: 10,
          max: 60,
          divisions: 10,
          value: _duration,
          onChanged: (value) => setState(() => _duration = value),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _openPreview,
          child: const Text('Prévisualiser'),
        ),
      ],
    );
  }
}
