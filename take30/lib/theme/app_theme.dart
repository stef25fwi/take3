import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'take30_screen_themes.dart';

class AppColors {
  static const Color navy = T30Colors.navy;
  static const Color dark = T30Colors.dark;
  static const Color purple = T30Colors.purple;
  static const Color cyan = T30Colors.cyan;
  static const Color yellow = T30Colors.yellow;
  static const Color white = T30Colors.white;

  static const Color surface = T30Colors.surface;
  static const Color surfaceCard = T30Colors.surfaceCard;
  static const Color surfaceElevated = T30Colors.surfaceElevated;
  static const Color surfaceOverlay = T30Colors.surfaceOverlay;
  static const Color borderSubtle = T30Colors.borderSubtle;
  static const Color borderMedium = T30Colors.borderStrong;

  static const Color textPrimary = T30Colors.textPrimary;
  static const Color textSecondary = T30Colors.textSecondary;
  static const Color textMuted = T30Colors.textMuted;
  static const Color textDisabled = T30Colors.textDisabled;

  static const Color red = T30Colors.red;
  static const Color green = T30Colors.green;
  static const Color orange = T30Colors.orange;

  static const Color navBackground = T30Colors.surface;
  static const Color navActive = T30Colors.yellow;
  static const Color navInactive = T30Colors.textMuted;
  static const Color navPlusButton = T30Colors.yellow;

  static const Color catDrama = ExploreScreenTheme.drama;
  static const Color catComedy = ExploreScreenTheme.comedy;
  static const Color catAction = ExploreScreenTheme.action;
  static const Color catRomance = ExploreScreenTheme.romance;
  static const Color catThriller = ExploreScreenTheme.thriller;

  static const Color badgeGold = BadgesStatsScreenTheme.gold;
  static const Color badgeSilver = BadgesStatsScreenTheme.silver;
  static const Color badgeBronze = BadgesStatsScreenTheme.bronze;
  static const Color badgeBlue = BadgesStatsScreenTheme.special;

  static const Color notifLike = T30Colors.red;
  static const Color notifComment = T30Colors.cyan;
  static const Color notifDuel = T30Colors.purple;
  static const Color notifTrophy = T30Colors.yellow;

  static const LinearGradient ctaGradient = T30Colors.ctaGradient;

  static const LinearGradient purpleCyanGradient = T30Colors.purpleCyanGradient;

  static const LinearGradient photoOverlayGradient = T30Colors.photoOverlay;

  static const LinearGradient feedCardOverlay = T30Colors.feedOverlay;

  static const LinearGradient onboardingOverlay = T30Colors.onboardingOverlay;

  static const LinearGradient recordBottomGradient = T30Colors.recordBottomOverlay;

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
  static const Color background = SplashScreenTheme.background;
  static const Color logoText = T30Colors.white;
  static const Color tagline = T30Colors.textSecondary;
  static const Color homePill = SplashScreenTheme.homePill;
  static const Color glowColor = SplashScreenTheme.glow;
  static const double glowOpacity = SplashScreenTheme.glowOpacity;
}

class OnboardingTheme {
  static const Color background = OnboardingScreenTheme.background;
  static const Color headlineText = T30Colors.white;
  static const Color taglineText = T30Colors.textSecondary;
  static const Color featureIconBg = OnboardingScreenTheme.featureBox;
  static const Color featureText = OnboardingScreenTheme.featureText;
  static const Color btnPrimaryBg = OnboardingScreenTheme.primaryButton;
  static const Color btnPrimaryText = T30Colors.navy;
  static const Color btnSecondaryBorder = OnboardingScreenTheme.secondaryBorder;
  static const Color btnSecondaryText = OnboardingScreenTheme.secondaryText;
  static const Color linkText = OnboardingScreenTheme.link;
  static LinearGradient get overlay => OnboardingScreenTheme.overlay;
}

class FeedTheme {
  static const Color background = HomeScreenTheme.background;
  static const Color appBarBg = HomeScreenTheme.appBar;
  static const Color filterIconBg = HomeScreenTheme.topActionBg;
  static const Color filterIconColor = T30Colors.white;
  static const Color filterIconBorder = HomeScreenTheme.topActionBorder;
  static const Color cardBg = HomeScreenTheme.cardBg;
  static const Color cardRadius = AppColors.surfaceCard;
  static LinearGradient get cardOverlay => HomeScreenTheme.overlay;
  static const Color likeActive = HomeScreenTheme.like;
  static const Color likeInactive = T30Colors.white;
  static const Color commentColor = HomeScreenTheme.sideAction;
  static const Color shareColor = HomeScreenTheme.sideAction;
  static const Color actionCount = T30Colors.white;
  static const Color categoryBadgeBg = HomeScreenTheme.categoryBadge;
  static const Color categoryBadgeText = T30Colors.white;
  static const Color statsText = HomeScreenTheme.bottomStats;
}

class ExploreTheme {
  static const Color background = ExploreScreenTheme.background;
  static const Color searchBg = ExploreScreenTheme.searchBg;
  static const Color searchBorder = ExploreScreenTheme.searchBorder;
  static const Color searchHint = T30Colors.textMuted;
  static const Color searchIcon = T30Colors.textMuted;
  static const Color sectionTitle = ExploreScreenTheme.sectionTitle;
  static const Color chipInactiveBg = ExploreScreenTheme.chipBg;
  static const Color chipInactiveBorder = ExploreScreenTheme.chipBorder;
  static const Color chipInactiveText = T30Colors.white;
  static const Color chipActiveBg = ExploreScreenTheme.chipActiveBg;
  static const Color chipActiveText = ExploreScreenTheme.chipActiveText;
  static const Color iconDrama = ExploreScreenTheme.drama;
  static const Color iconComedy = ExploreScreenTheme.comedy;
  static const Color iconAction = ExploreScreenTheme.action;
  static const Color iconRomance = ExploreScreenTheme.romance;
  static const Color iconThriller = ExploreScreenTheme.thriller;
  static const Color thumbRadius = AppColors.surfaceCard;
  static const Color durationBadgeBg = ExploreScreenTheme.durationBadgeBg;
  static const Color durationBadgeText = T30Colors.white;
}

class RecordTheme {
  static const Color background = RecordScreenTheme.background;
  static const Color cameraAreaBg = T30Colors.black;
  static const Color overlayBtnBg = RecordScreenTheme.overlayButtonBg;
  static const Color overlayBtnIcon = T30Colors.white;
  static const Color sceneTitleBg = RecordScreenTheme.scenePillBg;
  static const Color sceneTitleText = T30Colors.white;
  static const Color timerNormal = RecordScreenTheme.timerNormal;
  static const Color timerUrgent = RecordScreenTheme.timerUrgent;
  static const Color recordRing = RecordScreenTheme.recordRing;
  static const Color recordIdleDot = RecordScreenTheme.recordIdleCore;
  static const Color recordActiveDot = RecordScreenTheme.recordActiveCore;
  static const Color progressBg = RecordScreenTheme.progressBg;
  static const Color progressNormal = RecordScreenTheme.progressNormal;
  static const Color progressUrgent = RecordScreenTheme.progressUrgent;
  static LinearGradient get bottomGrad => RecordScreenTheme.bottomOverlay;
  static const Color ctrlBtnBg = RecordScreenTheme.bottomMiniControl;
  static const Color ctrlBtnIcon = T30Colors.white;
  static const Color ctrlBtnLabel = Color(0xB3FFFFFF);
}

class PreviewTheme {
  static const Color background = PreviewPublishScreenTheme.background;
  static const Color appBarBg = PreviewPublishScreenTheme.appBar;
  static const Color appBarText = T30Colors.white;
  static const Color modifyBtnText = T30Colors.white;
  static const Color playIconColor = T30Colors.white;
  static LinearGradient get videoOverlay => PreviewPublishScreenTheme.mediaOverlay;
  static const Color tagChipBg = PreviewPublishScreenTheme.tagBg;
  static const Color tagChipText = T30Colors.white;
  static const Color fieldLabel = PreviewPublishScreenTheme.fieldLabel;
  static const Color fieldBg = PreviewPublishScreenTheme.fieldBg;
  static const Color fieldBorder = T30Colors.borderSubtle;
  static const Color fieldText = T30Colors.white;
  static const Color catChipInactive = T30Colors.surfaceElevated;
  static const Color catChipActive = PreviewPublishScreenTheme.chipActiveBg;
  static const Color catChipActiveBorder = PreviewPublishScreenTheme.chipActiveBorder;
  static const Color catChipActiveText = PreviewPublishScreenTheme.chipActiveText;
  static const Color publishBtnBg = PreviewPublishScreenTheme.publishButton;
  static const Color publishBtnText = PreviewPublishScreenTheme.publishText;
  static const Color resetBtnBorder = PreviewPublishScreenTheme.secondaryBorder;
  static const Color resetBtnText = T30Colors.white;
}

class BattleTheme {
  static const Color background = BattleScreenTheme.background;
  static const Color appBarBg = BattleScreenTheme.background;
  static const Color titleText = BattleScreenTheme.title;
  static const Color vsBadgeBg = BattleScreenTheme.vsBg;
  static const Color vsBadgeBorder = BattleScreenTheme.vsBorder;
  static const Color vsBadgeText = BattleScreenTheme.vsText;
  static const Color videoBorder = T30Colors.borderSubtle;
  static LinearGradient get videoOverlay => BattleScreenTheme.mediaOverlay;
  static const Color labelA = BattleScreenTheme.voteA;
  static const Color labelB = BattleScreenTheme.resultB;
  static const Color voteABg = BattleScreenTheme.voteA;
  static const Color voteAText = BattleScreenTheme.voteAText;
  static const Color voteBBg = BattleScreenTheme.voteB;
  static const Color voteBBorder = BattleScreenTheme.voteBBorder;
  static const Color voteBText = BattleScreenTheme.voteBText;
  static const Color resultBarA = BattleScreenTheme.resultA;
  static const Color resultBarB = BattleScreenTheme.resultB;
  static const Color resultBarBg = BattleScreenTheme.resultBg;
  static const Color trophyColor = T30Colors.yellow;
}

class LeaderboardTheme {
  static const Color background = LeaderboardScreenTheme.background;
  static const Color appBarBg = LeaderboardScreenTheme.background;
  static const Color tabActiveBg = LeaderboardScreenTheme.tabActiveBg;
  static const Color tabActiveText = LeaderboardScreenTheme.tabActiveText;
  static const Color tabInactiveBg = Colors.transparent;
  static const Color tabInactiveText = LeaderboardScreenTheme.tabInactiveText;
  static const Color rowBg = LeaderboardScreenTheme.rowBg;
  static const Color rowBorder = LeaderboardScreenTheme.rowBorder;
  static const Color row1Bg = LeaderboardScreenTheme.rowTopBg;
  static const Color row1Border = LeaderboardScreenTheme.rowTopBorder;
  static const Color rankTop3 = LeaderboardScreenTheme.rankTop;
  static const Color rankOther = LeaderboardScreenTheme.rankOther;
  static const Color usernameText = T30Colors.white;
  static const Color scoreText = T30Colors.white;
  static const Color heartIcon = LeaderboardScreenTheme.heart;
  static const Color followerText = T30Colors.textMuted;
  static const Color badgeGlow = T30Colors.red;
}

class ProfileTheme {
  static const Color background = ProfileScreenTheme.background;
  static const LinearGradient headerGradient = ProfileScreenTheme.headerGradient;
  static const Color headerGlow = T30Colors.purple;
  static const double headerGlowOpacity = 0.18;
  static const Color avatarBorder = ProfileScreenTheme.avatarBorder;
  static const Color verifiedBg = ProfileScreenTheme.verifiedBg;
  static const Color verifiedIcon = T30Colors.white;
  static const Color nameText = T30Colors.white;
  static const Color roleText = T30Colors.textMuted;
  static const Color statValue = T30Colors.white;
  static const Color statLabel = ProfileScreenTheme.statLabel;
  static const Color statDivider = ProfileScreenTheme.divider;
  static const Color followBtnActiveBg = ProfileScreenTheme.followBg;
  static const Color followBtnActiveText = ProfileScreenTheme.followText;
  static const Color followBtnDoneBg = ProfileScreenTheme.followingBg;
  static const Color followBtnDoneText = ProfileScreenTheme.followingText;
  static const Color messageBtnBg = ProfileScreenTheme.secondaryButtonBg;
  static const Color messageBtnBorder = ProfileScreenTheme.secondaryButtonBorder;
  static const Color messageBtnText = T30Colors.white;
  static const Color downloadBtnBg = ProfileScreenTheme.secondaryButtonBg;
  static const Color downloadBtnBorder = ProfileScreenTheme.secondaryButtonBorder;
  static const Color downloadIcon = T30Colors.white;
  static const Color tabIndicator = ProfileScreenTheme.tabIndicator;
  static const Color tabActiveText = T30Colors.white;
  static const Color tabInactiveText = T30Colors.textMuted;
  static const Color gridBg = ProfileScreenTheme.background;
  static const Color thumbStatsBg = Color(0x88000000);
}

class BadgesTheme {
  static const Color background = BadgesStatsScreenTheme.background;
  static const Color appBarBg = BadgesStatsScreenTheme.background;
  static const Color headerTitle = T30Colors.white;
  static const Color voirToutLink = BadgesStatsScreenTheme.link;
  static const Color badgeCardBg = BadgesStatsScreenTheme.cardBg;
  static const Color badgeGoldCircle = BadgesStatsScreenTheme.gold;
  static const Color badgeSilverCircle = BadgesStatsScreenTheme.silver;
  static const Color badgeBronzeCircle = BadgesStatsScreenTheme.bronze;
  static const Color badgeBlueCircle = BadgesStatsScreenTheme.special;
  static const Color statRowBg = BadgesStatsScreenTheme.cardBg;
  static const Color statRowBorder = BadgesStatsScreenTheme.cardBorder;
  static const Color iconContainerBg = Color(0x1EFFFFFF);
  static const Color statValueText = T30Colors.white;
  static const Color statLabelText = T30Colors.textSecondary;
  static const Color statArrow = T30Colors.textMuted;
  static const Color progressBg = BadgesStatsScreenTheme.progressBg;
  static const Color progressFill = BadgesStatsScreenTheme.progressFill;
  static const Color chartBarFill = BadgesStatsScreenTheme.chartBar;
  static const Color chartBarBg = T30Colors.surfaceElevated;
}

class NotificationsTheme {
  static const Color background = NotificationsScreenTheme.background;
  static const Color appBarBg = NotificationsScreenTheme.background;
  static const Color rowReadBg = NotificationsScreenTheme.rowRead;
  static const Color rowReadBorder = NotificationsScreenTheme.rowReadBorder;
  static const Color rowUnreadBg = NotificationsScreenTheme.rowUnread;
  static const Color rowUnreadBorder = NotificationsScreenTheme.rowUnreadBorder;
  static const Color iconLikeBg = NotificationsScreenTheme.likeBg;
  static const Color iconCommentBg = NotificationsScreenTheme.commentBg;
  static const Color iconDuelBg = NotificationsScreenTheme.duelBg;
  static const Color iconTrophyBg = NotificationsScreenTheme.trophyBg;
  static const Color messageText = T30Colors.white;
  static const Color timeText = T30Colors.textMuted;
  static const Color unreadDot = NotificationsScreenTheme.unreadDot;
  static const Color actionBtnBg = NotificationsScreenTheme.actionBg;
  static const Color actionBtnBorder = NotificationsScreenTheme.actionBorder;
  static const Color actionBtnText = NotificationsScreenTheme.actionText;
}

class ChallengeTheme {
  static const Color background = DailyChallengeScreenTheme.background;
  static const Color appBarBg = DailyChallengeScreenTheme.background;
  static const Color bellIcon = DailyChallengeScreenTheme.bell;
  static const Color bellDot = DailyChallengeScreenTheme.bellDot;
  static const Color cardBg = DailyChallengeScreenTheme.cardBg;
  static const Color cardBorder = DailyChallengeScreenTheme.cardBorder;
  static const Color fireBadgeBg = DailyChallengeScreenTheme.fireBadgeBg;
  static const Color fireBadgeText = DailyChallengeScreenTheme.fireBadgeText;
  static const Color sceneTitleText = T30Colors.white;
  static const Color quoteText = DailyChallengeScreenTheme.quote;
  static const Color bulletColor = DailyChallengeScreenTheme.bullet;
  static const Color ruleText = DailyChallengeScreenTheme.rule;
  static const Color photoBg = T30Colors.surface;
  static const Color timerBg = DailyChallengeScreenTheme.timerBg;
  static const Color timerBorder = DailyChallengeScreenTheme.timerBorder;
  static const Color timerIcon = T30Colors.yellow;
  static const Color timerText = T30Colors.white;
  static const Color participantsText = T30Colors.textSecondary;
  static const Color challengeBtnBg = DailyChallengeScreenTheme.challengeButton;
  static const Color challengeBtnText = DailyChallengeScreenTheme.challengeButtonText;
  static const Color outlineBtnBorder = T30Colors.borderSubtle;
  static const Color outlineBtnText = T30Colors.white;
  static const Color pastCardBorder = T30Colors.borderSubtle;
  static const Color dayBadgeBg = Color(0x88000000);
  static const Color dayBadgeText = T30Colors.textSecondary;
}

class AppButtonStyles {
  static ButtonStyle primary({double height = 52}) {
    return T30Buttons.primary(height: height);
  }

  static ButtonStyle secondary({double height = 52}) {
    return T30Buttons.secondary(height: height);
  }

  static ButtonStyle outline({double height = 52}) {
    return T30Buttons.outline(height: height);
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
