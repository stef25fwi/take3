import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeatureItem>>(
      future: ApiService().fetchDashboard(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <FeatureItem>[];

        if (snapshot.connectionState == ConnectionState.waiting && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Voici les actions principales pour créer, publier et progresser sur Take30.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final item in items)
              SectionCard(
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
                trailing: const Icon(Icons.chevron_right),
                onTap: item.route == null
                    ? null
                    : () => Navigator.pushNamed(context, item.route!),
              ),
          ],
        );
      },
    );
  }
}
