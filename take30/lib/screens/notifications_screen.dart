import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Notifications',
      leading: TakeHeaderButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => context.go(AppRouter.home),
      ),
      children: [
        TakeNotificationItem(
          title: 'Battle terminée',
          body: 'Ton duel est clos. Consulte les résultats maintenant.',
          when: 'Il y a 5 min',
          onTap: () => context.push(AppRouter.battle),
        ),
        const Divider(color: Color(0x14FFFFFF), height: 1),
        TakeNotificationItem(
          title: 'Streak x5',
          body: 'Bravo, tu as créé pendant 5 jours consécutifs.',
          when: 'Il y a 20 min',
          onTap: () => context.push(AppRouter.badges),
        ),
        const Divider(color: Color(0x14FFFFFF), height: 1),
        TakeNotificationItem(
          title: 'Commentaire',
          body: 'Marie L. a commenté ton dernier Take.',
          when: 'Hier',
          isRead: true,
          onTap: () => context.go(AppRouter.home),
        ),
        const Divider(color: Color(0x14FFFFFF), height: 1),
        TakeNotificationItem(
          title: 'Nouvelle battle',
          body: 'Un nouveau thème est disponible pour ce soir.',
          when: 'Hier',
          isRead: true,
          onTap: () => context.push(AppRouter.battle),
        ),
      ],
    );
  }
}
