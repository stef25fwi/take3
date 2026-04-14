import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color navy = Color(0xFF081020);
  static const Color dark = Color(0xFF111827);
  static const Color purple = Color(0xFF6C5CE7);
  static const Color cyan = Color(0xFF00D4FF);
  static const Color yellow = Color(0xFFFFB800);
  static const Color white = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFF0D1626);
  static const Color surfaceCard = Color(0xFF141E2E);
  static const Color surfaceElevated = Color(0xFF1A2540);
  static const Color surfaceOverlay = Color(0xFF1E2D45);
  static const Color borderSubtle = Color(0xFF1E2D45);
  static const Color borderMedium = Color(0xFF243352);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BAC9);
  static const Color textMuted = Color(0xFF6B7A93);
  static const Color textDisabled = Color(0xFF3D4F6B);

  static const Color red = Color(0xFFFF4757);
  static const Color green = Color(0xFF2ED573);
  static const Color orange = Color(0xFFFF6B35);

  static const Color navBackground = Color(0xFF0D1626);
  static const Color navActive = Color(0xFFFFB800);
  static const Color navInactive = Color(0xFF5A6A82);
  static const Color navPlusButton = Color(0xFFFFB800);

  static const Color catDrama = Color(0xFF8B5CF6);
  static const Color catComedy = Color(0xFF06B6D4);
  static const Color catAction = Color(0xFFEF4444);
  static const Color catRomance = Color(0xFFEC4899);
  static const Color catThriller = Color(0xFF6B7280);

  static const Color badgeGold = Color(0xFFFFB800);
  static const Color badgeSilver = Color(0xFFB0BAC9);
  static const Color badgeBronze = Color(0xFFCD7F32);
  static const Color badgeBlue = Color(0xFF6C5CE7);

  static const Color notifLike = Color(0xFFFF4757);
  static const Color notifComment = Color(0xFF00D4FF);
  static const Color notifDuel = Color(0xFF6C5CE7);
  static const Color notifTrophy = Color(0xFFFFB800);

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

  static const LinearGradient photoOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xBB000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.4, 1.0],
  );

  static const LinearGradient feedCardOverlay = LinearGradient(
    colors: [
      Colors.transparent,
      Colors.transparent,
      Color(0xCC000000),
      Color(0xF0000000),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4, 0.72, 1.0],
  );

  static const LinearGradient onboardingOverlay = LinearGradient(
    colors: [
      Color(0x55000000),
      Color(0x99000000),
      Color(0xEB081020),
      Color(0xFF081020),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.35, 0.68, 1.0],
  );

  static const LinearGradient recordBottomGradient = LinearGradient(
    colors: [Color(0xE0000000), Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient rank1Highlight = LinearGradient(
    colors: [Color(0x15FFB800), Color(0x08FFB800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient challengeCardGradient = LinearGradient(
    colors: [Color(0xFF141E2E), Color(0xFF1A1035)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color grey = textMuted;
  static const Color greyLight = textSecondary;
  static const Color surfaceLight = surfaceElevated;
  static const Color cardDark = surfaceCard;
  static const Color border = borderSubtle;
  static const LinearGradient primaryGradient = ctaGradient;
  static const LinearGradient darkOverlay = feedCardOverlay;
}

class AppTextStyles {
  static TextStyle heading1(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        letterSpacing: -0.8,
        height: 1.15,
      );

  static TextStyle heading2(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: -0.3,
        height: 1.2,
      );

  static TextStyle body(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.white,
        height: 1.5,
      );

  static TextStyle caption(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static final logoStyle = GoogleFonts.dmSans(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    letterSpacing: -2.0,
    height: 1.0,
  );

  static final taglineStyle = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  static final buttonPrimary = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
    letterSpacing: 0.2,
  );

  static final buttonSecondary = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.1,
  );

  static final username = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static final statCount = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static final navLabel = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static final leaderScore = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static final recordTimer = GoogleFonts.dmSans(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    letterSpacing: -2.0,
  );

  static final sceneTitle = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    height: 1.3,
  );

  static final chipLabel = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static final profileStatValue = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
  );

  static final profileStatLabel = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static final statValue = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
  );

  static final durationBadge = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static final notifMessage = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.3,
  );

  static final notifTime = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static final challengeQuote = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    fontStyle: FontStyle.italic,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.yellow,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.yellow,
      onPrimary: AppColors.navy,
      secondary: AppColors.cyan,
      onSecondary: AppColors.white,
      tertiary: AppColors.purple,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.white,
      error: AppColors.red,
      onError: AppColors.white,
      outline: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.navy,
      primaryColor: AppColors.yellow,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      cardTheme: _buildCardTheme(),
      inputDecorationTheme: _buildInputTheme(),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 0.5,
        space: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.white, size: 22),
    );
  }

  static ThemeData get lightTheme => darkTheme;

  static TextTheme _buildTextTheme() {
    return GoogleFonts.dmSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
          letterSpacing: -0.8,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.white,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    ).apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.white, size: 22),
      actionsIconTheme: const IconThemeData(color: AppColors.white, size: 22),
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme() {
    return const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navBackground,
      selectedItemColor: AppColors.navActive,
      unselectedItemColor: AppColors.navInactive,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.navy,
        disabledBackgroundColor: AppColors.surfaceOverlay,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.borderMedium, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.cyan,
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: AppColors.surfaceCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static InputDecorationTheme _buildInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
      labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
    );
  }
}

class SplashTheme {
  static const Color background = AppColors.navy;
  static const Color logoText = AppColors.white;
  static const Color tagline = AppColors.textSecondary;
  static const Color homePill = AppColors.white;
  static const Color glowColor = AppColors.purple;
  static const double glowOpacity = 0.16;
}

class OnboardingTheme {
  static const Color background = AppColors.navy;
  static const Color headlineText = AppColors.white;
  static const Color taglineText = AppColors.textSecondary;
  static const Color featureIconBg = Color(0x14FFFFFF);
  static const Color featureText = AppColors.white;
  static const Color btnPrimaryBg = AppColors.yellow;
  static const Color btnPrimaryText = AppColors.navy;
  static const Color btnSecondaryBorder = Color(0x4DFFFFFF);
  static const Color btnSecondaryText = AppColors.white;
  static const Color linkText = AppColors.yellow;
  static LinearGradient get overlay => AppColors.onboardingOverlay;
}

class FeedTheme {
  static const Color background = AppColors.navy;
  static const Color appBarBg = AppColors.navy;
  static const Color filterIconBg = AppColors.surfaceElevated;
  static const Color filterIconColor = AppColors.white;
  static const Color filterIconBorder = AppColors.borderSubtle;
  static const Color cardBg = AppColors.surfaceCard;
  static const Color cardRadius = AppColors.surfaceCard;
  static LinearGradient get cardOverlay => AppColors.feedCardOverlay;
  static const Color likeActive = AppColors.red;
  static const Color likeInactive = AppColors.white;
  static const Color commentColor = AppColors.white;
  static const Color shareColor = AppColors.white;
  static const Color actionCount = AppColors.white;
  static const Color categoryBadgeBg = AppColors.purple;
  static const Color categoryBadgeText = AppColors.white;
  static const Color statsText = Color(0xCCFFFFFF);
}

class ExploreTheme {
  static const Color background = AppColors.navy;
  static const Color searchBg = AppColors.surfaceElevated;
  static const Color searchBorder = AppColors.borderSubtle;
  static const Color searchHint = AppColors.textMuted;
  static const Color searchIcon = AppColors.textMuted;
  static const Color sectionTitle = AppColors.white;
  static const Color chipInactiveBg = AppColors.surfaceElevated;
  static const Color chipInactiveBorder = AppColors.borderSubtle;
  static const Color chipInactiveText = AppColors.white;
  static const Color chipActiveBg = AppColors.yellow;
  static const Color chipActiveText = AppColors.navy;
  static const Color iconDrama = AppColors.catDrama;
  static const Color iconComedy = AppColors.catComedy;
  static const Color iconAction = AppColors.catAction;
  static const Color iconRomance = AppColors.catRomance;
  static const Color iconThriller = AppColors.catThriller;
  static const Color thumbRadius = AppColors.surfaceCard;
  static const Color durationBadgeBg = Color(0x88000000);
  static const Color durationBadgeText = AppColors.white;
}

class RecordTheme {
  static const Color background = Color(0xFF000000);
  static const Color cameraAreaBg = Color(0xFF0A0A0A);
  static const Color overlayBtnBg = Color(0x66000000);
  static const Color overlayBtnIcon = AppColors.white;
  static const Color sceneTitleBg = Color(0x88000000);
  static const Color sceneTitleText = AppColors.white;
  static const Color timerNormal = AppColors.white;
  static const Color timerUrgent = AppColors.red;
  static const Color recordRing = AppColors.white;
  static const Color recordIdleDot = AppColors.white;
  static const Color recordActiveDot = AppColors.red;
  static const Color progressBg = Color(0x33FFFFFF);
  static const Color progressNormal = AppColors.yellow;
  static const Color progressUrgent = AppColors.red;
  static LinearGradient get bottomGrad => AppColors.recordBottomGradient;
  static const Color ctrlBtnBg = Color(0x1FFFFFFF);
  static const Color ctrlBtnIcon = AppColors.white;
  static const Color ctrlBtnLabel = Color(0xB3FFFFFF);
}

class PreviewTheme {
  static const Color background = AppColors.navy;
  static const Color appBarBg = AppColors.navy;
  static const Color appBarText = AppColors.white;
  static const Color modifyBtnText = AppColors.white;
  static const Color playIconColor = AppColors.white;
  static LinearGradient get videoOverlay => AppColors.photoOverlayGradient;
  static const Color tagChipBg = AppColors.purple;
  static const Color tagChipText = AppColors.white;
  static const Color fieldLabel = AppColors.textSecondary;
  static const Color fieldBg = AppColors.surfaceElevated;
  static const Color fieldBorder = AppColors.borderSubtle;
  static const Color fieldText = AppColors.white;
  static const Color catChipInactive = AppColors.surfaceElevated;
  static const Color catChipActive = Color(0x26FFB800);
  static const Color catChipActiveBorder = AppColors.yellow;
  static const Color catChipActiveText = AppColors.yellow;
  static const Color publishBtnBg = AppColors.yellow;
  static const Color publishBtnText = AppColors.navy;
  static const Color resetBtnBorder = AppColors.borderSubtle;
  static const Color resetBtnText = AppColors.white;
}

class BattleTheme {
  static const Color background = AppColors.navy;
  static const Color appBarBg = AppColors.navy;
  static const Color titleText = AppColors.white;
  static const Color vsBadgeBg = AppColors.surfaceElevated;
  static const Color vsBadgeBorder = AppColors.borderSubtle;
  static const Color vsBadgeText = AppColors.yellow;
  static const Color videoBorder = AppColors.borderSubtle;
  static LinearGradient get videoOverlay => AppColors.photoOverlayGradient;
  static const Color labelA = AppColors.yellow;
  static const Color labelB = AppColors.cyan;
  static const Color voteABg = AppColors.yellow;
  static const Color voteAText = AppColors.navy;
  static const Color voteBBg = Color(0xFF1E3A8A);
  static const Color voteBBorder = Color(0x80007FFF);
  static const Color voteBText = AppColors.white;
  static const Color resultBarA = AppColors.yellow;
  static const Color resultBarB = AppColors.cyan;
  static const Color resultBarBg = AppColors.surfaceElevated;
  static const Color trophyColor = AppColors.yellow;
}

class LeaderboardTheme {
  static const Color background = AppColors.navy;
  static const Color appBarBg = AppColors.navy;
  static const Color tabActiveBg = AppColors.yellow;
  static const Color tabActiveText = AppColors.navy;
  static const Color tabInactiveBg = Colors.transparent;
  static const Color tabInactiveText = AppColors.textMuted;
  static const Color rowBg = AppColors.surfaceCard;
  static const Color rowBorder = AppColors.borderSubtle;
  static const Color row1Bg = Color(0x15FFB800);
  static const Color row1Border = Color(0x40FFB800);
  static const Color rankTop3 = AppColors.yellow;
  static const Color rankOther = AppColors.textMuted;
  static const Color usernameText = AppColors.white;
  static const Color scoreText = AppColors.white;
  static const Color heartIcon = AppColors.red;
  static const Color followerText = AppColors.textMuted;
  static const Color badgeGlow = AppColors.red;
}

class ProfileTheme {
  static const Color background = AppColors.navy;
  static final LinearGradient headerGradient = const LinearGradient(
    colors: [Color(0xFF0D1626), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const Color headerGlow = AppColors.purple;
  static const double headerGlowOpacity = 0.18;
  static const Color avatarBorder = AppColors.yellow;
  static const Color verifiedBg = AppColors.cyan;
  static const Color verifiedIcon = AppColors.white;
  static const Color nameText = AppColors.white;
  static const Color roleText = AppColors.textMuted;
  static const Color statValue = AppColors.white;
  static const Color statLabel = AppColors.textMuted;
  static const Color statDivider = AppColors.borderSubtle;
  static const Color followBtnActiveBg = AppColors.yellow;
  static const Color followBtnActiveText = AppColors.navy;
  static const Color followBtnDoneBg = AppColors.surfaceElevated;
  static const Color followBtnDoneText = AppColors.textSecondary;
  static const Color messageBtnBg = AppColors.surfaceElevated;
  static const Color messageBtnBorder = AppColors.borderSubtle;
  static const Color messageBtnText = AppColors.white;
  static const Color downloadBtnBg = AppColors.surfaceElevated;
  static const Color downloadBtnBorder = AppColors.borderSubtle;
  static const Color downloadIcon = AppColors.white;
  static const Color tabIndicator = AppColors.yellow;
  static const Color tabActiveText = AppColors.white;
  static const Color tabInactiveText = AppColors.textMuted;
  static const Color gridBg = AppColors.navy;
  static const Color thumbStatsBg = Color(0x88000000);
}

class BadgesTheme {
  static const Color background = AppColors.navy;
  static const Color appBarBg = AppColors.navy;
  static const Color headerTitle = AppColors.white;
  static const Color voirToutLink = AppColors.cyan;
  static const Color badgeCardBg = AppColors.surfaceCard;
  static const Color badgeGoldCircle = AppColors.badgeGold;
  static const Color badgeSilverCircle = AppColors.badgeSilver;
  static const Color badgeBronzeCircle = AppColors.badgeBronze;
  static const Color badgeBlueCircle = AppColors.badgeBlue;
  static const Color statRowBg = AppColors.surfaceCard;
  static const Color statRowBorder = AppColors.borderSubtle;
  static const Color iconContainerBg = Color(0x1EFFFFFF);
  static const Color statValueText = AppColors.white;
  static const Color statLabelText = AppColors.textSecondary;
  static const Color statArrow = AppColors.textMuted;
  static const Color progressBg = AppColors.surfaceElevated;
  static const Color progressFill = AppColors.green;
  static const Color chartBarFill = AppColors.cyan;
  static const Color chartBarBg = AppColors.surfaceElevated;
}

class NotificationsTheme {
  static const Color background = AppColors.navy;
  static const Color appBarBg = AppColors.navy;
  static const Color rowReadBg = AppColors.surfaceCard;
  static const Color rowReadBorder = AppColors.borderSubtle;
  static const Color rowUnreadBg = AppColors.surfaceElevated;
  static const Color rowUnreadBorder = Color(0x40FFB800);
  static const Color iconLikeBg = Color(0x26FF4757);
  static const Color iconCommentBg = Color(0x2600D4FF);
  static const Color iconDuelBg = Color(0x266C5CE7);
  static const Color iconTrophyBg = Color(0x26FFB800);
  static const Color messageText = AppColors.white;
  static const Color timeText = AppColors.textMuted;
  static const Color unreadDot = AppColors.cyan;
  static const Color actionBtnBg = Color(0x1FFFB800);
  static const Color actionBtnBorder = Color(0x4DFFB800);
  static const Color actionBtnText = AppColors.yellow;
}

class ChallengeTheme {
  static const Color background = AppColors.navy;
  static const Color appBarBg = AppColors.navy;
  static const Color bellIcon = AppColors.yellow;
  static const Color bellDot = AppColors.red;
  static const Color cardBg = AppColors.surfaceCard;
  static const Color cardBorder = AppColors.borderSubtle;
  static const Color fireBadgeBg = Color(0x26FF4757);
  static const Color fireBadgeText = AppColors.red;
  static const Color sceneTitleText = AppColors.white;
  static const Color quoteText = AppColors.textSecondary;
  static const Color bulletColor = AppColors.yellow;
  static const Color ruleText = AppColors.textSecondary;
  static const Color photoBg = AppColors.surface;
  static const Color timerBg = AppColors.surfaceCard;
  static const Color timerBorder = Color(0x33FFB800);
  static const Color timerIcon = AppColors.yellow;
  static const Color timerText = AppColors.white;
  static const Color participantsText = AppColors.textSecondary;
  static const Color challengeBtnBg = AppColors.yellow;
  static const Color challengeBtnText = AppColors.navy;
  static const Color outlineBtnBorder = AppColors.borderSubtle;
  static const Color outlineBtnText = AppColors.white;
  static const Color pastCardBorder = AppColors.borderSubtle;
  static const Color dayBadgeBg = Color(0x88000000);
  static const Color dayBadgeText = AppColors.textSecondary;
}

class AppButtonStyles {
  static ButtonStyle primary({double height = 52}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.yellow,
      foregroundColor: AppColors.navy,
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: Size(double.infinity, height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static ButtonStyle secondary({double height = 52}) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.white,
      backgroundColor: AppColors.surfaceElevated,
      side: const BorderSide(color: AppColors.borderMedium, width: 1.5),
      minimumSize: Size(double.infinity, height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ButtonStyle outline({double height = 52}) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.white,
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
      minimumSize: Size(double.infinity, height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class NavIconStates {
  static const Color active = AppColors.yellow;
  static const Color hover = Color(0xFFD4A800);
  static const Color inactive = AppColors.navInactive;
}

class NavIcons {
  static const IconData home = Icons.home_rounded;
  static const IconData explore = Icons.explore_rounded;
  static const IconData record = Icons.add;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData profile = Icons.person_outline_rounded;
}
