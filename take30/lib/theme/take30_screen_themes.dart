import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TAKE30 - PIXEL PERFECT SCREEN THEMES
/// Base visuelle extraite du mockup fourni.

class T30Colors {
  static const Color navy = Color(0xFF081020);
  static const Color dark = Color(0xFF111827);
  static const Color purple = Color(0xFF6C5CE7);
  static const Color cyan = Color(0xFF00D4FF);
  static const Color yellow = Color(0xFFFFB800);
  static const Color white = Color(0xFFFFFFFF);

  static const Color black = Color(0xFF000000);

  static const Color surface = Color(0xFF0D1626);
  static const Color surfaceCard = Color(0xFF141E2E);
  static const Color surfaceElevated = Color(0xFF1A2540);
  static const Color surfaceOverlay = Color(0xFF1E2D45);

  static const Color borderSubtle = Color(0xFF243046);
  static const Color borderStrong = Color(0xFF32445F);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BAC9);
  static const Color textMuted = Color(0xFF6B7A93);
  static const Color textDisabled = Color(0xFF4B5A73);

  static const Color red = Color(0xFFFF4757);
  static const Color green = Color(0xFF2ED573);
  static const Color orange = Color(0xFFFF8C00);

  static const Color battleBlue = Color(0xFF1E3A8A);

  static const Color notifLikeBg = Color(0x26FF4757);
  static const Color notifCommentBg = Color(0x2600D4FF);
  static const Color notifDuelBg = Color(0x266C5CE7);
  static const Color notifTrophyBg = Color(0x26FFB800);

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient purpleCyanGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient photoOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.45, 1.0],
  );

  static const LinearGradient feedOverlay = LinearGradient(
    colors: [
      Colors.transparent,
      Colors.transparent,
      Color(0x99000000),
      Color(0xE6000000),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.38, 0.70, 1.0],
  );

  static const LinearGradient onboardingOverlay = LinearGradient(
    colors: [
      Color(0x33000000),
      Color(0x77000000),
      Color(0xD9081020),
      Color(0xFF081020),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.32, 0.70, 1.0],
  );

  static const LinearGradient recordBottomOverlay = LinearGradient(
    colors: [Color(0xF0000000), Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient profileHeaderGradient = LinearGradient(
    colors: [Color(0xFF0D1626), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class T30Text {
  static TextStyle logo = GoogleFonts.dmSans(
    fontSize: 72,
    fontWeight: FontWeight.w900,
    color: T30Colors.white,
    letterSpacing: -3.0,
    height: 1,
  );

  static TextStyle h1 = GoogleFonts.dmSans(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: T30Colors.white,
    letterSpacing: -0.8,
    height: 1.12,
  );

  static TextStyle h2 = GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: T30Colors.white,
    letterSpacing: -0.2,
    height: 1.18,
  );

  static TextStyle body = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: T30Colors.white,
    height: 1.45,
  );

  static TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: T30Colors.white,
    height: 1.35,
  );

  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: T30Colors.textSecondary,
    height: 1.3,
  );

  static TextStyle micro = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: T30Colors.textMuted,
    height: 1.2,
  );

  static TextStyle buttonPrimary = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: T30Colors.navy,
    letterSpacing: 0.1,
  );

  static TextStyle buttonSecondary = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: T30Colors.white,
  );

  static TextStyle nav = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: T30Colors.textMuted,
  );

  static TextStyle stat = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: T30Colors.white,
  );

  static TextStyle username = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: T30Colors.white,
  );

  static TextStyle recordTimer = GoogleFonts.dmSans(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    color: T30Colors.white,
    letterSpacing: -2,
    height: 1,
  );
}

class T30BaseTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: T30Colors.navy,
        primaryColor: T30Colors.yellow,
        colorScheme: const ColorScheme.dark(
          primary: T30Colors.yellow,
          secondary: T30Colors.cyan,
          tertiary: T30Colors.purple,
          surface: T30Colors.surfaceCard,
          error: T30Colors.red,
          onPrimary: T30Colors.navy,
          onSecondary: T30Colors.white,
          onSurface: T30Colors.white,
          onError: T30Colors.white,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: T30Colors.navy,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: T30Colors.white,
          ),
          iconTheme: const IconThemeData(color: T30Colors.white, size: 22),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: T30Colors.surfaceElevated,
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: T30Colors.textMuted,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: T30Colors.borderSubtle, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: T30Colors.borderSubtle, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: T30Colors.cyan, width: 1.4),
          ),
        ),
      );
}

/// 1 - SPLASH
class SplashScreenTheme {
  static const Color background = T30Colors.navy;
  static const Color glow = T30Colors.purple;
  static const double glowOpacity = 0.16;
  static const Color homePill = T30Colors.white;
  static const EdgeInsets contentPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 24);
}

/// 2 - ONBOARDING
class OnboardingScreenTheme {
  static const Color background = T30Colors.navy;
  static const LinearGradient overlay = T30Colors.onboardingOverlay;
  static const Color featureBox = Color(0x14FFFFFF);
  static const Color featureText = T30Colors.white;
  static const Color primaryButton = T30Colors.yellow;
  static const Color secondaryBorder = Color(0x4DFFFFFF);
  static const Color secondaryText = T30Colors.white;
  static const Color link = T30Colors.yellow;
}

/// 3 - HOME / FEED
class HomeScreenTheme {
  static const Color background = T30Colors.navy;
  static const Color appBar = T30Colors.navy;
  static const Color topActionBg = T30Colors.surfaceElevated;
  static const Color topActionBorder = T30Colors.borderSubtle;
  static const Color cardBg = T30Colors.surfaceCard;
  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(20));
  static const LinearGradient overlay = T30Colors.feedOverlay;
  static const Color categoryBadge = T30Colors.purple;
  static const Color like = T30Colors.red;
  static const Color sideAction = T30Colors.white;
  static const Color bottomStats = Color(0xCCFFFFFF);
}

/// 4 - EXPLORE
class ExploreScreenTheme {
  static const Color background = T30Colors.navy;
  static const Color searchBg = T30Colors.surfaceElevated;
  static const Color searchBorder = T30Colors.borderSubtle;
  static const Color sectionTitle = T30Colors.white;
  static const Color chipBg = T30Colors.surfaceElevated;
  static const Color chipBorder = T30Colors.borderSubtle;
  static const Color chipActiveBg = T30Colors.yellow;
  static const Color chipActiveText = T30Colors.navy;
  static const Color durationBadgeBg = Color(0x88000000);

  static const Color drama = Color(0xFF8B5CF6);
  static const Color comedy = Color(0xFF06B6D4);
  static const Color action = Color(0xFFEF4444);
  static const Color romance = Color(0xFFEC4899);
  static const Color thriller = Color(0xFF6B7280);
}

/// 5 - RECORD
class RecordScreenTheme {
  static const Color background = T30Colors.black;
  static const Color overlayButtonBg = Color(0x66000000);
  static const Color scenePillBg = Color(0x88000000);
  static const Color timerNormal = T30Colors.white;
  static const Color timerUrgent = T30Colors.red;
  static const Color progressBg = Color(0x33FFFFFF);
  static const Color progressNormal = T30Colors.yellow;
  static const Color progressUrgent = T30Colors.red;
  static const LinearGradient bottomOverlay = T30Colors.recordBottomOverlay;
  static const Color recordRing = T30Colors.white;
  static const Color recordIdleCore = T30Colors.white;
  static const Color recordActiveCore = T30Colors.red;
  static const Color bottomMiniControl = Color(0x1FFFFFFF);
}

/// 6 - PREVIEW / PUBLISH
class PreviewPublishScreenTheme {
  static const Color background = T30Colors.navy;
  static const Color appBar = T30Colors.navy;
  static const LinearGradient mediaOverlay = T30Colors.photoOverlay;
  static const Color tagBg = Color(0xCC6C5CE7);
  static const Color fieldLabel = T30Colors.textSecondary;
  static const Color fieldBg = T30Colors.surfaceElevated;
  static const Color publishButton = T30Colors.yellow;
  static const Color publishText = T30Colors.navy;
  static const Color secondaryBorder = T30Colors.borderSubtle;
  static const Color chipActiveBg = Color(0x26FFB800);
  static const Color chipActiveBorder = T30Colors.yellow;
  static const Color chipActiveText = T30Colors.yellow;
}

/// 7 - BATTLE
class BattleScreenTheme {
  static const Color background = T30Colors.navy;
  static const Color title = T30Colors.white;
  static const Color vsBg = T30Colors.surfaceElevated;
  static const Color vsBorder = T30Colors.borderSubtle;
  static const Color vsText = T30Colors.yellow;
  static const LinearGradient mediaOverlay = T30Colors.photoOverlay;
  static const Color voteA = T30Colors.yellow;
  static const Color voteAText = T30Colors.navy;
  static const Color voteB = T30Colors.battleBlue;
  static const Color voteBBorder = Color(0x80007FFF);
  static const Color voteBText = T30Colors.white;
  static const Color resultA = T30Colors.yellow;
  static const Color resultB = T30Colors.cyan;
  static const Color resultBg = T30Colors.surfaceElevated;
}

/// 8 - LEADERBOARD
class LeaderboardScreenTheme {
  static const Color background = T30Colors.navy;
  static const Color tabActiveBg = T30Colors.yellow;
  static const Color tabActiveText = T30Colors.navy;
  static const Color tabInactiveText = T30Colors.textMuted;
  static const Color rowBg = T30Colors.surfaceCard;
  static const Color rowBorder = T30Colors.borderSubtle;
  static const Color rowTopBg = Color(0x15FFB800);
  static const Color rowTopBorder = Color(0x40FFB800);
  static const Color rankTop = T30Colors.yellow;
  static const Color rankOther = T30Colors.textMuted;
  static const Color heart = T30Colors.red;
}

/// 9 - PROFILE
class ProfileScreenTheme {
  static const LinearGradient headerGradient =
      T30Colors.profileHeaderGradient;
  static const Color background = T30Colors.navy;
  static const Color avatarBorder = T30Colors.yellow;
  static const Color verifiedBg = T30Colors.cyan;
  static const Color statLabel = T30Colors.textMuted;
  static const Color divider = T30Colors.borderSubtle;
  static const Color followBg = T30Colors.yellow;
  static const Color followText = T30Colors.navy;
  static const Color followingBg = T30Colors.surfaceElevated;
  static const Color followingText = T30Colors.textSecondary;
  static const Color secondaryButtonBg = T30Colors.surfaceElevated;
  static const Color secondaryButtonBorder = T30Colors.borderSubtle;
  static const Color tabIndicator = T30Colors.yellow;
}

/// 10 - BADGES & STATS
class BadgesStatsScreenTheme {
  static const Color background = T30Colors.navy;
  static const Color cardBg = T30Colors.surfaceCard;
  static const Color cardBorder = T30Colors.borderSubtle;
  static const Color gold = T30Colors.yellow;
  static const Color silver = T30Colors.textSecondary;
  static const Color bronze = Color(0xFFCD7F32);
  static const Color special = T30Colors.purple;
  static const Color progressBg = T30Colors.surfaceElevated;
  static const Color progressFill = T30Colors.green;
  static const Color chartBar = T30Colors.cyan;
  static const Color link = T30Colors.cyan;
}

/// 11 - NOTIFICATIONS
class NotificationsScreenTheme {
  static const Color background = T30Colors.navy;
  static const Color rowRead = T30Colors.surfaceCard;
  static const Color rowUnread = T30Colors.surfaceElevated;
  static const Color rowReadBorder = T30Colors.borderSubtle;
  static const Color rowUnreadBorder = Color(0x40FFB800);
  static const Color likeBg = T30Colors.notifLikeBg;
  static const Color commentBg = T30Colors.notifCommentBg;
  static const Color duelBg = T30Colors.notifDuelBg;
  static const Color trophyBg = T30Colors.notifTrophyBg;
  static const Color unreadDot = T30Colors.cyan;
  static const Color actionBg = Color(0x1FFFB800);
  static const Color actionBorder = Color(0x4DFFB800);
  static const Color actionText = T30Colors.yellow;
}

/// 12 - DAILY CHALLENGE
class DailyChallengeScreenTheme {
  static const Color background = T30Colors.navy;
  static const Color bell = T30Colors.yellow;
  static const Color bellDot = T30Colors.red;
  static const Color cardBg = T30Colors.surfaceCard;
  static const Color cardBorder = T30Colors.borderSubtle;
  static const Color fireBadgeBg = Color(0x26FF4757);
  static const Color fireBadgeText = T30Colors.red;
  static const Color quote = T30Colors.textSecondary;
  static const Color bullet = T30Colors.yellow;
  static const Color rule = T30Colors.textSecondary;
  static const Color timerBg = T30Colors.surfaceCard;
  static const Color timerBorder = Color(0x33FFB800);
  static const Color challengeButton = T30Colors.yellow;
  static const Color challengeButtonText = T30Colors.navy;
}

/// Widgets utilitaires pixel perfect.
class T30Buttons {
  static ButtonStyle primary({double height = 52}) {
    return ElevatedButton.styleFrom(
      backgroundColor: T30Colors.yellow,
      foregroundColor: T30Colors.navy,
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: Size(double.infinity, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: T30Text.buttonPrimary,
    );
  }

  static ButtonStyle secondary({double height = 52}) {
    return OutlinedButton.styleFrom(
      foregroundColor: T30Colors.white,
      backgroundColor: T30Colors.surfaceElevated,
      side: const BorderSide(color: T30Colors.borderSubtle, width: 1.2),
      minimumSize: Size(double.infinity, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: T30Text.buttonSecondary,
    );
  }

  static ButtonStyle outline({double height = 52}) {
    return OutlinedButton.styleFrom(
      foregroundColor: T30Colors.white,
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: T30Colors.borderSubtle, width: 1.2),
      minimumSize: Size(double.infinity, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: T30Text.buttonSecondary,
    );
  }
}

class T30Decor {
  static BoxDecoration card({
    BorderRadius radius = const BorderRadius.all(Radius.circular(16)),
  }) {
    return BoxDecoration(
      color: T30Colors.surfaceCard,
      borderRadius: radius,
      border: Border.all(color: T30Colors.borderSubtle, width: 0.6),
    );
  }

  static BoxDecoration glassChip({
    required Color bg,
    Color border = T30Colors.borderSubtle,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: 0.8),
    );
  }

  static BoxDecoration circularAction() {
    return const BoxDecoration(
      color: T30Colors.surfaceElevated,
      shape: BoxShape.circle,
    );
  }

  static BoxDecoration imageOverlayCard({
    BorderRadius radius = const BorderRadius.all(Radius.circular(20)),
  }) {
    return BoxDecoration(
      borderRadius: radius,
      gradient: T30Colors.feedOverlay,
    );
  }
}