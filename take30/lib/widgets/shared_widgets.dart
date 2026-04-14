import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

enum TakeTab { home, explore, record, battle, profile }

enum TakePillTone { cyan, yellow, purple, red, green, neutral }

class TakeScreenScaffold extends StatelessWidget {
  const TakeScreenScaffold({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.trailing,
    this.showBottomNav = false,
    this.activeTab,
    this.scrollable = true,
    this.showHeader = true,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final bool showBottomNav;
  final TakeTab? activeTab;
  final bool scrollable;
  final bool showHeader;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: contentPadding,
      child: scrollable ? SingleChildScrollView(child: child) : child,
    );

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060A14), AppColors.navy, Color(0xFF0A0F1D)],
            stops: [0, 0.35, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              left: -40,
              child: _GlowCircle(color: Color(0x3300D4FF), size: 220),
            ),
            const Positioned(
              top: 120,
              right: -60,
              child: _GlowCircle(color: Color(0x336C5CE7), size: 220),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const _StatusBar(),
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                      child: Row(
                        children: [
                          leading ?? const SizedBox(width: 36),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          trailing ?? const SizedBox(width: 36),
                        ],
                      ),
                    ),
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav && activeTab != null
          ? TakeTabBar(selected: activeTab!)
          : null,
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle = '',
    this.icon,
    this.trailing,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.child,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty || subtitle.isNotEmpty || icon != null || trailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x2200D4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: AppColors.cyan),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: Color(0x99FFFFFF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
          if (child != null) ...[
            if (title.isNotEmpty || subtitle.isNotEmpty || icon != null || trailing != null)
              const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      ),
    );
  }
}

class InfoStat extends StatelessWidget {
  const InfoStat({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class PageWrap extends StatelessWidget {
  const PageWrap({
    super.key,
    required this.title,
    required this.children,
    this.leading,
    this.trailing,
    this.showBottomNav = false,
    this.activeTab,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  });

  final String title;
  final List<Widget> children;
  final Widget? leading;
  final Widget? trailing;
  final bool showBottomNav;
  final TakeTab? activeTab;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return TakeScreenScaffold(
      title: title,
      leading: leading,
      trailing: trailing,
      showBottomNav: showBottomNav,
      activeTab: activeTab,
      contentPadding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class TakePill extends StatelessWidget {
  const TakePill({
    super.key,
    required this.label,
    this.tone = TakePillTone.neutral,
  });

  final String label;
  final TakePillTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      TakePillTone.cyan => (const Color(0x3300D4FF), AppColors.cyan),
      TakePillTone.yellow => (const Color(0x33FFB800), AppColors.yellow),
      TakePillTone.purple => (const Color(0x336C5CE7), AppColors.purple),
      TakePillTone.red => (const Color(0x33FF4D4F), const Color(0xFFFF4D4F)),
      TakePillTone.green => (const Color(0x2200E676), const Color(0xFF00E676)),
      TakePillTone.neutral => (const Color(0x14FFFFFF), Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.$2,
        ),
      ),
    );
  }
}

class TakePillButton extends StatelessWidget {
  const TakePillButton({
    super.key,
    required this.label,
    required this.tone,
    this.onTap,
  });

  final String label;
  final TakePillTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TakePill(label: label, tone: tone),
    );
  }
}

class TakeProgressBar extends StatelessWidget {
  const TakeProgressBar({
    super.key,
    required this.value,
    this.colors = const [Color(0xFFFF4D4F), AppColors.yellow],
  });

  final double value;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        color: const Color(0x14FFFFFF),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(colors: colors),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TakeVideoPlaceholder extends StatelessWidget {
  const TakeVideoPlaceholder({
    super.key,
    required this.emoji,
    this.height = 200,
  });

  final String emoji;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x2600D4FF), Color(0x226C5CE7)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 48)),
    );
  }
}

class TakeAvatar extends StatelessWidget {
  const TakeAvatar({
    super.key,
    required this.label,
    this.size = 42,
    this.colors = const [AppColors.cyan, AppColors.purple],
  });

  final String label;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TakeHeaderButton extends StatelessWidget {
  const TakeHeaderButton({
    super.key,
    required this.icon,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: Colors.white),
          splashRadius: 18,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class TakeFeedItem extends StatelessWidget {
  const TakeFeedItem({
    super.key,
    required this.avatar,
    required this.name,
    required this.description,
    required this.time,
  });

  final Widget avatar;
  final String name;
  final String description;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TakeLeaderboardRow extends StatelessWidget {
  const TakeLeaderboardRow({
    super.key,
    required this.rank,
    required this.name,
    required this.scoreLabel,
    required this.score,
    this.highlight = false,
  });

  final String rank;
  final String name;
  final String scoreLabel;
  final String score;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: highlight ? 8 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0x14FFB800) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(rank, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(scoreLabel, style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
              ],
            ),
          ),
          Text(score, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.yellow)),
        ],
      ),
    );
  }
}

class TakeNotificationItem extends StatelessWidget {
  const TakeNotificationItem({
    super.key,
    required this.title,
    required this.body,
    required this.when,
    this.isRead = false,
    this.onTap,
  });

  final String title;
  final String body;
  final String when;
  final bool isRead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead ? Colors.transparent : AppColors.cyan,
                border: isRead ? Border.all(color: const Color(0x22FFFFFF)) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
                  const SizedBox(height: 4),
                  Text(when, style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TakeCountdownBox extends StatelessWidget {
  const TakeCountdownBox({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 58),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.yellow),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0x99FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class TakeTabBar extends StatelessWidget {
  const TakeTabBar({
    super.key,
    required this.selected,
  });

  final TakeTab selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
      decoration: const BoxDecoration(
        color: Color(0xF2081020),
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TakeTabItem(
            icon: Icons.home_outlined,
            label: 'Accueil',
            active: selected == TakeTab.home,
            onTap: () => _goTo(context, TakeTab.home),
          ),
          _TakeTabItem(
            icon: Icons.explore_outlined,
            label: 'Explorer',
            active: selected == TakeTab.explore,
            onTap: () => _goTo(context, TakeTab.explore),
          ),
          _TakeTabItem(
            icon: Icons.fiber_manual_record,
            label: 'Record',
            active: selected == TakeTab.record,
            isRecord: true,
            onTap: () => _goTo(context, TakeTab.record),
          ),
          _TakeTabItem(
            icon: Icons.sports_mma_outlined,
            label: 'Battle',
            active: selected == TakeTab.battle,
            onTap: () => _goTo(context, TakeTab.battle),
          ),
          _TakeTabItem(
            icon: Icons.person_outline,
            label: 'Profil',
            active: selected == TakeTab.profile,
            onTap: () => _goTo(context, TakeTab.profile),
          ),
        ],
      ),
    );
  }

  void _goTo(BuildContext context, TakeTab tab) {
    final route = switch (tab) {
      TakeTab.home => '/home',
      TakeTab.explore => '/explore',
      TakeTab.record => '/record',
      TakeTab.battle => '/battle',
      TakeTab.profile => '/profile',
    };
    context.go(route);
  }
}

class _TakeTabItem extends StatelessWidget {
  const _TakeTabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.isRecord = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool isRecord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = isRecord
        ? Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFFF4D4F), Color(0xFFFF6B6B)]),
              boxShadow: [
                BoxShadow(color: Color(0x66FF4D4F), blurRadius: 20, offset: Offset(0, 4)),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.fiber_manual_record, color: Colors.white, size: 18),
          )
        : Icon(icon, color: active ? AppColors.yellow : const Color(0x99FFFFFF), size: 22);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecord) Transform.translate(offset: const Offset(0, -14), child: content) else content,
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.yellow : const Color(0x99FFFFFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text('📶 🔋', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
