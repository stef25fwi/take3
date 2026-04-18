import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.navy),
                ),
              )
            : Text(label),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

String? avatarPhotoAssetForUserId(String? userId) {
  switch (userId) {
    case 'u1':
      return 'assets/avatars/avatar_ia_female_lead.webp';
    case 'u4':
    case 'u6':
      return 'assets/avatars/avatar_ia_female_alt.webp';
    case 'u2':
    case 'u3':
    case 'u5':
    case 'u7':
      return 'assets/avatars/avatar_ia_male_lead.webp';
    default:
      return null;
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.url,
    this.userId,
    this.size = 40,
    this.showBorder = false,
  });

  final String? url;
  final String? userId;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final preferredAsset = avatarPhotoAssetForUserId(userId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: AppColors.yellow, width: 2) : null,
        color: AppColors.surfaceLight,
      ),
      child: ClipOval(
        child: _buildAvatarImage(preferredAsset),
      ),
    );
  }

  Widget _buildAvatarImage(String? preferredAsset) {
    final cacheDim = (size * 2).round();
    if (preferredAsset != null) {
      return Image.asset(
        preferredAsset,
        fit: BoxFit.cover,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (_, __, ___) => _buildUrlImage(),
      );
    }
    return _buildUrlImage();
  }

  Widget _buildUrlImage() {
    final cacheDim = (size * 2).round();
    if (url == null) {
      return _placeholder();
    }
    if (url!.startsWith('assets/')) {
      return Image.asset(
        url!,
        fit: BoxFit.cover,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      cacheWidth: cacheDim,
      cacheHeight: cacheDim,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.person,
      size: size * 0.6,
      color: AppColors.grey,
    );
  }
}

class SceneCard extends StatelessWidget {
  const SceneCard({
    super.key,
    required this.scene,
    this.onTap,
    this.width,
    this.height,
  });

  final SceneModel scene;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height ?? 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardDark,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              scene.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.cardDark),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.darkOverlay,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 10, color: AppColors.red),
                      const SizedBox(width: 3),
                      Text(
                        MockData.formatCount(scene.likesCount),
                        style: const TextStyle(fontSize: 10, color: AppColors.greyLight),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.play_circle_filled, size: 10, color: AppColors.cyan),
                      const SizedBox(width: 3),
                      Text(
                        scene.durationFormatted,
                        style: const TextStyle(fontSize: 10, color: AppColors.greyLight),
                      ),
                    ],
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

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  final CategoryModel category;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.yellow : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.yellow : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.navy : AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.grey),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        final stop1 = (_animation.value - 1).clamp(0.0, 1.0).toDouble();
        final stop2 = _animation.value.clamp(0.0, 1.0).toDouble();
        final stop3 = (_animation.value + 1).clamp(0.0, 1.0).toDouble();

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.surfaceLight,
                Color(0xFF243048),
                AppColors.surfaceLight,
              ],
              stops: [stop1, stop2, stop3],
            ),
          ),
        );
      },
    );
  }
}

class NotifIcon extends StatelessWidget {
  const NotifIcon({super.key, required this.type});

  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;

    switch (type) {
      case NotificationType.like:
        icon = Icons.favorite;
        color = AppColors.red;
      case NotificationType.comment:
        icon = Icons.comment;
        color = AppColors.cyan;
      case NotificationType.duel:
        icon = Icons.sports_mma;
        color = AppColors.purple;
      case NotificationType.achievement:
        icon = Icons.emoji_events;
        color = AppColors.yellow;
      case NotificationType.system:
        icon = Icons.info;
        color = AppColors.grey;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
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
