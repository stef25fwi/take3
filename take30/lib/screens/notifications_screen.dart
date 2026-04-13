import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationItem>>(
      future: ApiService().fetchNotifications(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <NotificationItem>[];

        if (snapshot.connectionState == ConnectionState.waiting && data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return PageWrap(
          title: 'Notifications',
          children: [
            for (final item in data)
              SectionCard(
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
                trailing: item.isNew
                    ? const Chip(label: Text('Nouveau'))
                    : const Icon(Icons.chevron_right),
              ),
          ],
        );
      },
    );
  }
}
