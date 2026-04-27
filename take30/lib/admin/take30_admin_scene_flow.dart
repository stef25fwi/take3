import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const Take30AdminApp());
}

const _kAdminIdentifier = String.fromEnvironment(
  'TAKE30_ADMIN_ID',
  defaultValue: 'admin',
);
const _kAdminPassword = String.fromEnvironment(
  'TAKE30_ADMIN_PASSWORD',
  defaultValue: 'Take30Admin2026',
);

class AdminSession {
  const AdminSession({
    this.isAuthenticated = false,
    this.identifier,
    this.error,
    this.isLoading = false,
  });

  final bool isAuthenticated;
  final String? identifier;
  final String? error;
  final bool isLoading;

  AdminSession copyWith({
    bool? isAuthenticated,
    String? identifier,
    String? error,
    bool? isLoading,
  }) {
    return AdminSession(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      identifier: identifier ?? this.identifier,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AdminAccessController extends ValueNotifier<AdminSession> {
  AdminAccessController() : super(const AdminSession());

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    value = value.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (identifier.trim() == _kAdminIdentifier && password == _kAdminPassword) {
      value = AdminSession(
        isAuthenticated: true,
        identifier: identifier.trim(),
      );
      return true;
    }

    value = const AdminSession(
      isAuthenticated: false,
      error: 'Identifiant ou mot de passe admin invalide.',
    );
    return false;
  }

  void logout() {
    value = const AdminSession();
  }
}

final adminAccessController = AdminAccessController();

class Take30AdminApp extends StatelessWidget {
  const Take30AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Take 60 Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C4DFF),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C4DFF), width: 1.4),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const AdminAccessGate(),
    );
  }
}

class AdminAccessGate extends StatelessWidget {
  const AdminAccessGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminSession>(
      valueListenable: adminAccessController,
      builder: (context, session, _) {
        if (session.isAuthenticated) {
          return AdminDashboardPage(onLogout: adminAccessController.logout);
        }
        return const AdminLoginPage();
      },
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await adminAccessController.login(
      identifier: _identifierCtrl.text,
      password: _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminSession>(
      valueListenable: adminAccessController,
      builder: (context, session, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Connexion admin'),
            backgroundColor: Colors.transparent,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C4DFF).withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Color(0xFF6C4DFF),
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Accès administration',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Connecte-toi avec l’identifiant et le mot de passe admin.',
                                      style: TextStyle(height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _identifierCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Identifiant admin',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Identifiant requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe admin',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Mot de passe requis';
                              }
                              return null;
                            },
                          ),
                          if (session.error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE8E8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                session.error!,
                                style: const TextStyle(
                                  color: Color(0xFF9F1D1D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: session.isLoading ? null : _submit,
                              icon: session.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: const Text('Entrer dans l’admin'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SceneDraftRepository {
  static final List<SceneFormData> _items = [];

  static Future<void> save(SceneFormData data) async {
    final index = _items.indexWhere((e) => e.id == data.id);
    if (index >= 0) {
      _items[index] = data;
    } else {
      _items.add(data);
    }
  }

  static List<SceneFormData> all() => List.unmodifiable(_items);

  static List<SceneFormData> drafts() =>
      _items.where((e) => e.status == SceneStatus.draft).toList();

  static List<SceneFormData> published() =>
      _items.where((e) => e.status == SceneStatus.published).toList();
}

enum SceneStatus { draft, published }

class SceneFormData {
  final String id;
  final SceneStatus status;

  final String projectTitle;
  final String sceneName;
  final String sceneNumber;
  final String shootDate;
  final String location;
  final String director;
  final String targetDuration;

  final String characterName;
  final String apparentAge;
  final String profileRole;
  final String relationship;
  final String initialState;
  final String characterSummary;

  final String previousMoment;
  final String whereAreWe;
  final String withWho;
  final String whyImportant;
  final String contextSummary;

  final String mainObjective;
  final String mainObstacle;
  final String stakes;

  final String dominantEmotion;
  final String secondaryEmotion;
  final String intensity;
  final String evolutionStart;
  final String evolutionMiddle;
  final String evolutionEnd;
  final String emotionalNuance;

  final List<String> playStyles;
  final String actingDirection;
  final String references;

  final String textType;
  final String dialogueText;
  final String emphasizedWords;
  final String keyPhrase;

  final String block1Intention;
  final String block1Energy;
  final String block1Look;
  final String block1Rhythm;

  final String block2Intention;
  final String block2Energy;
  final String block2Look;
  final String block2Rhythm;

  final String block3Intention;
  final String block3Energy;
  final String block3Look;
  final String block3Rhythm;

  final String startPosition;
  final String plannedMovement;
  final String expectedGestures;
  final String usedObjects;
  final String keyActionMoment;
  final String bodyDirection;

  final String framingType;
  final String cameraRelation;
  final String gazePoint;
  final String faceDirection;

  final String globalTempo;
  final String silences;
  final String dramaticRise;

  final String floorMark;
  final String startCue;
  final String movementCue;
  final String exactEnd;
  final String idealTextDuration;
  final String technicalConstraints;

  final String spectatorFeeling;
  final String directorFinalNote;

  const SceneFormData({
    required this.id,
    required this.status,
    required this.projectTitle,
    required this.sceneName,
    required this.sceneNumber,
    required this.shootDate,
    required this.location,
    required this.director,
    required this.targetDuration,
    required this.characterName,
    required this.apparentAge,
    required this.profileRole,
    required this.relationship,
    required this.initialState,
    required this.characterSummary,
    required this.previousMoment,
    required this.whereAreWe,
    required this.withWho,
    required this.whyImportant,
    required this.contextSummary,
    required this.mainObjective,
    required this.mainObstacle,
    required this.stakes,
    required this.dominantEmotion,
    required this.secondaryEmotion,
    required this.intensity,
    required this.evolutionStart,
    required this.evolutionMiddle,
    required this.evolutionEnd,
    required this.emotionalNuance,
    required this.playStyles,
    required this.actingDirection,
    required this.references,
    required this.textType,
    required this.dialogueText,
    required this.emphasizedWords,
    required this.keyPhrase,
    required this.block1Intention,
    required this.block1Energy,
    required this.block1Look,
    required this.block1Rhythm,
    required this.block2Intention,
    required this.block2Energy,
    required this.block2Look,
    required this.block2Rhythm,
    required this.block3Intention,
    required this.block3Energy,
    required this.block3Look,
    required this.block3Rhythm,
    required this.startPosition,
    required this.plannedMovement,
    required this.expectedGestures,
    required this.usedObjects,
    required this.keyActionMoment,
    required this.bodyDirection,
    required this.framingType,
    required this.cameraRelation,
    required this.gazePoint,
    required this.faceDirection,
    required this.globalTempo,
    required this.silences,
    required this.dramaticRise,
    required this.floorMark,
    required this.startCue,
    required this.movementCue,
    required this.exactEnd,
    required this.idealTextDuration,
    required this.technicalConstraints,
    required this.spectatorFeeling,
    required this.directorFinalNote,
  });

  SceneFormData copyWith({
    SceneStatus? status,
  }) {
    return SceneFormData(
      id: id,
      status: status ?? this.status,
      projectTitle: projectTitle,
      sceneName: sceneName,
      sceneNumber: sceneNumber,
      shootDate: shootDate,
      location: location,
      director: director,
      targetDuration: targetDuration,
      characterName: characterName,
      apparentAge: apparentAge,
      profileRole: profileRole,
      relationship: relationship,
      initialState: initialState,
      characterSummary: characterSummary,
      previousMoment: previousMoment,
      whereAreWe: whereAreWe,
      withWho: withWho,
      whyImportant: whyImportant,
      contextSummary: contextSummary,
      mainObjective: mainObjective,
      mainObstacle: mainObstacle,
      stakes: stakes,
      dominantEmotion: dominantEmotion,
      secondaryEmotion: secondaryEmotion,
      intensity: intensity,
      evolutionStart: evolutionStart,
      evolutionMiddle: evolutionMiddle,
      evolutionEnd: evolutionEnd,
      emotionalNuance: emotionalNuance,
      playStyles: playStyles,
      actingDirection: actingDirection,
      references: references,
      textType: textType,
      dialogueText: dialogueText,
      emphasizedWords: emphasizedWords,
      keyPhrase: keyPhrase,
      block1Intention: block1Intention,
      block1Energy: block1Energy,
      block1Look: block1Look,
      block1Rhythm: block1Rhythm,
      block2Intention: block2Intention,
      block2Energy: block2Energy,
      block2Look: block2Look,
      block2Rhythm: block2Rhythm,
      block3Intention: block3Intention,
      block3Energy: block3Energy,
      block3Look: block3Look,
      block3Rhythm: block3Rhythm,
      startPosition: startPosition,
      plannedMovement: plannedMovement,
      expectedGestures: expectedGestures,
      usedObjects: usedObjects,
      keyActionMoment: keyActionMoment,
      bodyDirection: bodyDirection,
      framingType: framingType,
      cameraRelation: cameraRelation,
      gazePoint: gazePoint,
      faceDirection: faceDirection,
      globalTempo: globalTempo,
      silences: silences,
      dramaticRise: dramaticRise,
      floorMark: floorMark,
      startCue: startCue,
      movementCue: movementCue,
      exactEnd: exactEnd,
      idealTextDuration: idealTextDuration,
      technicalConstraints: technicalConstraints,
      spectatorFeeling: spectatorFeeling,
      directorFinalNote: directorFinalNote,
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    required this.onLogout,
    this.actionLabel = 'Déconnexion',
  });

  final VoidCallback onLogout;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final drafts = SceneDraftRepository.drafts().length;
    final published = SceneDraftRepository.published().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take 60 • Administration'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: Text(actionLabel),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _AdminTile(
              title: 'Ajout scène',
              subtitle: 'Créer une fiche acteur de 1 minute',
              icon: Icons.add_box_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C4DFF), Color(0xFF8D74FF)],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddScenePage(),
                  ),
                );
              },
            ),
            _AdminTile(
              title: 'Analytics full',
              subtitle: 'Vue complète des scènes, projets et tendances',
              icon: Icons.analytics_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AnalyticsFullPage(),
                  ),
                );
              },
            ),
            _AdminTile(
              title: 'Bibliothèque scène',
              subtitle: '$drafts brouillon(s) • $published publié(es)',
              icon: Icons.video_library_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF121826), Color(0xFF2B3245)],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SceneLibraryPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;

  const _AdminTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalyticsFullPage extends StatelessWidget {
  const AnalyticsFullPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = SceneDraftRepository.all();
    final drafts = SceneDraftRepository.drafts();
    final published = SceneDraftRepository.published();
    final uniqueProjects = items
        .map((item) => item.projectTitle.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
    final uniqueCharacters = items
        .map((item) => item.characterName.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;

    final topProjects = _sortedCountEntries(
      items.map((item) => item.projectTitle),
      emptyLabel: 'Sans projet',
    );
    final topEmotions = _sortedCountEntries(
      items.map((item) => item.dominantEmotion),
      emptyLabel: 'Non définie',
    );
    final topDirectors = _sortedCountEntries(
      items.map((item) => item.director),
      emptyLabel: 'Non renseigné',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics full'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _AnalyticsStatCard(
                  label: 'Scènes',
                  value: items.length.toString(),
                  color: const Color(0xFF6C4DFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalyticsStatCard(
                  label: 'Publiées',
                  value: published.length.toString(),
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AnalyticsStatCard(
                  label: 'Projets',
                  value: uniqueProjects.toString(),
                  color: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalyticsStatCard(
                  label: 'Personnages',
                  value: uniqueCharacters.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AnalyticsBreakdownCard(
            drafts: drafts.length,
            published: published.length,
            total: items.length,
          ),
          const SizedBox(height: 16),
          _AnalyticsListCard(
            title: 'Top projets',
            entries: topProjects,
          ),
          const SizedBox(height: 16),
          _AnalyticsListCard(
            title: 'Top émotions dominantes',
            entries: topEmotions,
          ),
          const SizedBox(height: 16),
          _AnalyticsListCard(
            title: 'Direction / réalisateur',
            entries: topDirectors,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsStatCard extends StatelessWidget {
  const _AnalyticsStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsBreakdownCard extends StatelessWidget {
  const _AnalyticsBreakdownCard({
    required this.drafts,
    required this.published,
    required this.total,
  });

  final int drafts;
  final int published;
  final int total;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final draftRatio = drafts / safeTotal;
    final publishedRatio = published / safeTotal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition des statuts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: (draftRatio * 1000).round(),
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                  Expanded(
                    flex: (publishedRatio * 1000).round(),
                    child: Container(color: const Color(0xFF16A34A)),
                  ),
                  if (drafts == 0 && published == 0)
                    const Expanded(child: ColoredBox(color: Color(0xFFE5E7EB))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: const Color(0xFFF59E0B), label: 'Brouillons $drafts'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFF16A34A), label: 'Publiées $published'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsListCard extends StatelessWidget {
  const _AnalyticsListCard({required this.title, required this.entries});

  final String title;
  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              'Aucune donnée disponible.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            for (final entry in entries.take(4)) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if (entry != entries.take(4).last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

List<MapEntry<String, int>> _sortedCountEntries(
  Iterable<String> rawValues, {
  required String emptyLabel,
}) {
  final counts = <String, int>{};
  for (final rawValue in rawValues) {
    final key = rawValue.trim().isEmpty ? emptyLabel : rawValue.trim();
    counts.update(key, (value) => value + 1, ifAbsent: () => 1);
  }

  final entries = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) {
        return byCount;
      }
      return a.key.compareTo(b.key);
    });
  return entries;
}

class AddScenePage extends StatefulWidget {
  const AddScenePage({super.key});

  @override
  State<AddScenePage> createState() => _AddScenePageState();
}

class _AddScenePageState extends State<AddScenePage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final SpeechToText _speechToText = SpeechToText();

  final projectTitleCtrl = TextEditingController();
  final sceneNameCtrl = TextEditingController();
  final sceneNumberCtrl = TextEditingController();
  final shootDateCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final directorCtrl = TextEditingController();
  final targetDurationCtrl = TextEditingController(text: '1 minute maximum');

  final characterNameCtrl = TextEditingController();
  final apparentAgeCtrl = TextEditingController();
  final profileRoleCtrl = TextEditingController();
  final relationshipCtrl = TextEditingController();
  final initialStateCtrl = TextEditingController();
  final characterSummaryCtrl = TextEditingController();

  final previousMomentCtrl = TextEditingController();
  final whereAreWeCtrl = TextEditingController();
  final withWhoCtrl = TextEditingController();
  final whyImportantCtrl = TextEditingController();
  final contextSummaryCtrl = TextEditingController();

  final mainObstacleCtrl = TextEditingController();
  final stakesCtrl = TextEditingController();

  final evolutionStartCtrl = TextEditingController();
  final evolutionMiddleCtrl = TextEditingController();
  final evolutionEndCtrl = TextEditingController();
  final emotionalNuanceCtrl = TextEditingController();

  final actingDirectionCtrl = TextEditingController();
  final referencesCtrl = TextEditingController();

  final dialogueTextCtrl = TextEditingController();
  final emphasizedWordsCtrl = TextEditingController();
  final keyPhraseCtrl = TextEditingController();

  final block1IntentionCtrl = TextEditingController();
  final block1EnergyCtrl = TextEditingController();
  final block1LookCtrl = TextEditingController();
  final block1RhythmCtrl = TextEditingController();

  final block2IntentionCtrl = TextEditingController();
  final block2EnergyCtrl = TextEditingController();
  final block2LookCtrl = TextEditingController();
  final block2RhythmCtrl = TextEditingController();

  final block3IntentionCtrl = TextEditingController();
  final block3EnergyCtrl = TextEditingController();
  final block3LookCtrl = TextEditingController();
  final block3RhythmCtrl = TextEditingController();

  final startPositionCtrl = TextEditingController();
  final plannedMovementCtrl = TextEditingController();
  final expectedGesturesCtrl = TextEditingController();
  final usedObjectsCtrl = TextEditingController();
  final keyActionMomentCtrl = TextEditingController();
  final bodyDirectionCtrl = TextEditingController();

  final gazePointCtrl = TextEditingController();
  final faceDirectionCtrl = TextEditingController();

  final silencesCtrl = TextEditingController();
  final dramaticRiseCtrl = TextEditingController();

  final floorMarkCtrl = TextEditingController();
  final startCueCtrl = TextEditingController();
  final movementCueCtrl = TextEditingController();
  final exactEndCtrl = TextEditingController();
  final idealTextDurationCtrl = TextEditingController();
  final technicalConstraintsCtrl = TextEditingController();

  final spectatorFeelingCtrl = TextEditingController();
  final directorFinalNoteCtrl = TextEditingController();

  String selectedMainObjective = 'convaincre';
  String selectedDominantEmotion = 'détermination';
  String selectedSecondaryEmotion = 'fragilité';
  String selectedIntensity = 'moyen';
  String selectedTextType = 'texte exact à respecter';
  String selectedFramingType = 'plan poitrine';
  String selectedCameraRelation = 'légèrement hors caméra';
  String selectedGlobalTempo = 'progressif';

  final List<String> selectedStyles = ['cinéma', 'intense'];

  final objectiveOptions = const [
    'convaincre',
    'séduire',
    'se défendre',
    'cacher sa peur',
    'récupérer la confiance',
    'impressionner',
    'faire rire',
    'dominer la situation',
    'demander pardon',
    'retenir quelqu’un',
  ];

  final emotionOptions = const [
    'colère',
    'tristesse',
    'peur',
    'joie',
    'détermination',
    'fragilité',
    'tension',
    'stress',
    'admiration',
    'honte',
    'doute',
    'espoir',
  ];

  final intensityOptions = const ['faible', 'moyen', 'fort'];

  final styleOptions = const [
    'très naturel',
    'réaliste',
    'sobre',
    'intense',
    'dramatique',
    'pub / commercial',
    'cinéma',
    'série',
    'réseaux sociaux',
    'humoristique',
    'élégant / premium',
    'nerveux / tendu',
  ];

  final textTypeOptions = const [
    'texte exact à respecter',
    'texte semi-libre',
    'improvisation guidée',
  ];

  final framingOptions = const [
    'gros plan',
    'plan poitrine',
    'plan taille',
    'plan américain',
    'plan large',
  ];

  final cameraRelationOptions = const [
    'face caméra',
    'légèrement hors caméra',
    'scène dialoguée',
    'regard interdit caméra',
  ];

  final tempoOptions = const [
    'lent',
    'posé',
    'fluide',
    'nerveux',
    'progressif',
    'punchy',
  ];

  bool _speechAvailable = false;
  bool _speechInitializing = false;
  bool _isListeningToDialogue = false;
  bool _dialogueReceivedSpeech = false;
  String _dialogueSpeechBaseText = '';
  String? _dialogueSpeechStatus;
  String? _dialogueSpeechError;

  @override
  void dispose() {
    _speechToText.cancel();
    _scrollController.dispose();
    for (final c in [
      projectTitleCtrl,
      sceneNameCtrl,
      sceneNumberCtrl,
      shootDateCtrl,
      locationCtrl,
      directorCtrl,
      targetDurationCtrl,
      characterNameCtrl,
      apparentAgeCtrl,
      profileRoleCtrl,
      relationshipCtrl,
      initialStateCtrl,
      characterSummaryCtrl,
      previousMomentCtrl,
      whereAreWeCtrl,
      withWhoCtrl,
      whyImportantCtrl,
      contextSummaryCtrl,
      mainObstacleCtrl,
      stakesCtrl,
      evolutionStartCtrl,
      evolutionMiddleCtrl,
      evolutionEndCtrl,
      emotionalNuanceCtrl,
      actingDirectionCtrl,
      referencesCtrl,
      dialogueTextCtrl,
      emphasizedWordsCtrl,
      keyPhraseCtrl,
      block1IntentionCtrl,
      block1EnergyCtrl,
      block1LookCtrl,
      block1RhythmCtrl,
      block2IntentionCtrl,
      block2EnergyCtrl,
      block2LookCtrl,
      block2RhythmCtrl,
      block3IntentionCtrl,
      block3EnergyCtrl,
      block3LookCtrl,
      block3RhythmCtrl,
      startPositionCtrl,
      plannedMovementCtrl,
      expectedGesturesCtrl,
      usedObjectsCtrl,
      keyActionMomentCtrl,
      bodyDirectionCtrl,
      gazePointCtrl,
      faceDirectionCtrl,
      silencesCtrl,
      dramaticRiseCtrl,
      floorMarkCtrl,
      startCueCtrl,
      movementCueCtrl,
      exactEndCtrl,
      idealTextDurationCtrl,
      technicalConstraintsCtrl,
      spectatorFeelingCtrl,
      directorFinalNoteCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  SceneFormData _buildData(SceneStatus status) {
    return SceneFormData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      status: status,
      projectTitle: projectTitleCtrl.text.trim(),
      sceneName: sceneNameCtrl.text.trim(),
      sceneNumber: sceneNumberCtrl.text.trim(),
      shootDate: shootDateCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      director: directorCtrl.text.trim(),
      targetDuration: targetDurationCtrl.text.trim(),
      characterName: characterNameCtrl.text.trim(),
      apparentAge: apparentAgeCtrl.text.trim(),
      profileRole: profileRoleCtrl.text.trim(),
      relationship: relationshipCtrl.text.trim(),
      initialState: initialStateCtrl.text.trim(),
      characterSummary: characterSummaryCtrl.text.trim(),
      previousMoment: previousMomentCtrl.text.trim(),
      whereAreWe: whereAreWeCtrl.text.trim(),
      withWho: withWhoCtrl.text.trim(),
      whyImportant: whyImportantCtrl.text.trim(),
      contextSummary: contextSummaryCtrl.text.trim(),
      mainObjective: selectedMainObjective,
      mainObstacle: mainObstacleCtrl.text.trim(),
      stakes: stakesCtrl.text.trim(),
      dominantEmotion: selectedDominantEmotion,
      secondaryEmotion: selectedSecondaryEmotion,
      intensity: selectedIntensity,
      evolutionStart: evolutionStartCtrl.text.trim(),
      evolutionMiddle: evolutionMiddleCtrl.text.trim(),
      evolutionEnd: evolutionEndCtrl.text.trim(),
      emotionalNuance: emotionalNuanceCtrl.text.trim(),
      playStyles: selectedStyles,
      actingDirection: actingDirectionCtrl.text.trim(),
      references: referencesCtrl.text.trim(),
      textType: selectedTextType,
      dialogueText: dialogueTextCtrl.text.trim(),
      emphasizedWords: emphasizedWordsCtrl.text.trim(),
      keyPhrase: keyPhraseCtrl.text.trim(),
      block1Intention: block1IntentionCtrl.text.trim(),
      block1Energy: block1EnergyCtrl.text.trim(),
      block1Look: block1LookCtrl.text.trim(),
      block1Rhythm: block1RhythmCtrl.text.trim(),
      block2Intention: block2IntentionCtrl.text.trim(),
      block2Energy: block2EnergyCtrl.text.trim(),
      block2Look: block2LookCtrl.text.trim(),
      block2Rhythm: block2RhythmCtrl.text.trim(),
      block3Intention: block3IntentionCtrl.text.trim(),
      block3Energy: block3EnergyCtrl.text.trim(),
      block3Look: block3LookCtrl.text.trim(),
      block3Rhythm: block3RhythmCtrl.text.trim(),
      startPosition: startPositionCtrl.text.trim(),
      plannedMovement: plannedMovementCtrl.text.trim(),
      expectedGestures: expectedGesturesCtrl.text.trim(),
      usedObjects: usedObjectsCtrl.text.trim(),
      keyActionMoment: keyActionMomentCtrl.text.trim(),
      bodyDirection: bodyDirectionCtrl.text.trim(),
      framingType: selectedFramingType,
      cameraRelation: selectedCameraRelation,
      gazePoint: gazePointCtrl.text.trim(),
      faceDirection: faceDirectionCtrl.text.trim(),
      globalTempo: selectedGlobalTempo,
      silences: silencesCtrl.text.trim(),
      dramaticRise: dramaticRiseCtrl.text.trim(),
      floorMark: floorMarkCtrl.text.trim(),
      startCue: startCueCtrl.text.trim(),
      movementCue: movementCueCtrl.text.trim(),
      exactEnd: exactEndCtrl.text.trim(),
      idealTextDuration: idealTextDurationCtrl.text.trim(),
      technicalConstraints: technicalConstraintsCtrl.text.trim(),
      spectatorFeeling: spectatorFeelingCtrl.text.trim(),
      directorFinalNote: directorFinalNoteCtrl.text.trim(),
    );
  }

  Future<void> _save(SceneStatus status) async {
    if (status == SceneStatus.published) {
      if (!_formKey.currentState!.validate()) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
        return;
      }
    }

    final data = _buildData(status);
    await SceneDraftRepository.save(data);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == SceneStatus.draft
              ? 'Scène enregistrée en brouillon'
              : 'Scène publiée',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajout scène'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Row(
            children: [
              if (isWide)
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFF1F3FA),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 16),
                      _MenuHintItem('1. Informations générales'),
                      _MenuHintItem('2. Identité du personnage'),
                      _MenuHintItem('3. Contexte immédiat'),
                      _MenuHintItem('4. Objectif de jeu'),
                      _MenuHintItem('5. Direction émotionnelle'),
                      _MenuHintItem('6. Ton et style'),
                      _MenuHintItem('7. Texte'),
                      _MenuHintItem('8. Intentions par bloc'),
                      _MenuHintItem('9. Actions physiques'),
                      _MenuHintItem('10. Regard / caméra'),
                      _MenuHintItem('11. Rythme'),
                      _MenuHintItem('12. Repères techniques'),
                      _MenuHintItem('13. Ressenti spectateur'),
                      _MenuHintItem('14. Note finale'),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                  children: [
                    _section(
                      '1) Informations générales',
                      children: [
                        _requiredField(projectTitleCtrl, 'Titre du projet'),
                        _requiredField(sceneNameCtrl, 'Nom de la scène'),
                        _textField(sceneNumberCtrl, 'Numéro de scène / prise'),
                        _textField(shootDateCtrl, 'Date du tournage'),
                        _textField(locationCtrl, 'Lieu'),
                        _textField(
                          directorCtrl,
                          'Réalisateur / direction d’acteur',
                        ),
                        _textField(targetDurationCtrl, 'Durée visée'),
                      ],
                    ),
                    _section(
                      '2) Identité du personnage',
                      children: [
                        _requiredField(characterNameCtrl, 'Nom du personnage'),
                        _textField(apparentAgeCtrl, 'Âge apparent'),
                        _textField(profileRoleCtrl, 'Profil / rôle'),
                        _textField(
                          relationshipCtrl,
                          'Lien avec les autres personnages',
                        ),
                        _textField(
                          initialStateCtrl,
                          'État au début de la scène',
                        ),
                        _textField(
                          characterSummaryCtrl,
                          'Résumé personnage en 1 phrase',
                          maxLines: 3,
                        ),
                      ],
                    ),
                    _section(
                      '3) Contexte immédiat de la scène',
                      children: [
                        _textField(
                          previousMomentCtrl,
                          'Ce qu’il vient de se passer juste avant',
                          maxLines: 3,
                        ),
                        _textField(whereAreWeCtrl, 'Où nous sommes'),
                        _textField(withWhoCtrl, 'Avec qui'),
                        _textField(
                          whyImportantCtrl,
                          'Pourquoi ce moment est important',
                          maxLines: 3,
                        ),
                        _textField(
                          contextSummaryCtrl,
                          'Résumé du contexte en 2 lignes',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    _section(
                      '4) Objectif de jeu',
                      children: [
                        _dropdown(
                          label: 'Objectif principal du personnage',
                          value: selectedMainObjective,
                          items: objectiveOptions,
                          onChanged: (v) =>
                              setState(() => selectedMainObjective = v!),
                        ),
                        _textField(mainObstacleCtrl, 'Obstacle principal', maxLines: 3),
                        _textField(stakesCtrl, 'Enjeu', maxLines: 3),
                      ],
                    ),
                    _section(
                      '5) Direction émotionnelle',
                      children: [
                        _dropdown(
                          label: 'Émotion dominante',
                          value: selectedDominantEmotion,
                          items: emotionOptions,
                          onChanged: (v) =>
                              setState(() => selectedDominantEmotion = v!),
                        ),
                        _dropdown(
                          label: 'Émotion secondaire',
                          value: selectedSecondaryEmotion,
                          items: emotionOptions,
                          onChanged: (v) =>
                              setState(() => selectedSecondaryEmotion = v!),
                        ),
                        _dropdown(
                          label: 'Niveau d’intensité',
                          value: selectedIntensity,
                          items: intensityOptions,
                          onChanged: (v) => setState(() => selectedIntensity = v!),
                        ),
                        _textField(
                          evolutionStartCtrl,
                          'Évolution émotionnelle — début',
                        ),
                        _textField(
                          evolutionMiddleCtrl,
                          'Évolution émotionnelle — milieu',
                        ),
                        _textField(
                          evolutionEndCtrl,
                          'Évolution émotionnelle — fin',
                        ),
                        _textField(emotionalNuanceCtrl, 'Nuance importante', maxLines: 3),
                      ],
                    ),
                    _section(
                      '6) Ton et style de jeu',
                      children: [
                        _chipSelector(
                          title: 'Styles recherchés',
                          options: styleOptions,
                          selected: selectedStyles,
                          onToggle: (style) {
                            setState(() {
                              if (selectedStyles.contains(style)) {
                                selectedStyles.remove(style);
                              } else {
                                selectedStyles.add(style);
                              }
                            });
                          },
                        ),
                        _textField(actingDirectionCtrl, 'Consigne de jeu', maxLines: 4),
                        _textField(referencesCtrl, 'Références éventuelles', maxLines: 3),
                      ],
                    ),
                    _section(
                      '7) Texte',
                      children: [
                        _dropdown(
                          label: 'Type de texte',
                          value: selectedTextType,
                          items: textTypeOptions,
                          onChanged: (v) => setState(() => selectedTextType = v!),
                        ),
                        _dialogueTextField(),
                        _textField(
                          emphasizedWordsCtrl,
                          'Mots ou phrases à accentuer',
                          maxLines: 3,
                        ),
                        _textField(
                          keyPhraseCtrl,
                          'Mot / phrase clé à ne pas manquer',
                          maxLines: 2,
                        ),
                      ],
                    ),
                    _section(
                      '8) Intentions par bloc',
                      children: [
                        _subBlockTitle('Bloc 1 — 0:00 à 0:20'),
                        _textField(block1IntentionCtrl, 'Intention'),
                        _textField(block1EnergyCtrl, 'Énergie'),
                        _textField(block1LookCtrl, 'Regard'),
                        _textField(block1RhythmCtrl, 'Rythme'),
                        _subBlockTitle('Bloc 2 — 0:20 à 0:40'),
                        _textField(block2IntentionCtrl, 'Intention'),
                        _textField(block2EnergyCtrl, 'Énergie'),
                        _textField(block2LookCtrl, 'Regard'),
                        _textField(block2RhythmCtrl, 'Rythme'),
                        _subBlockTitle('Bloc 3 — 0:40 à 1:00'),
                        _textField(block3IntentionCtrl, 'Intention'),
                        _textField(block3EnergyCtrl, 'Énergie'),
                        _textField(block3LookCtrl, 'Regard'),
                        _textField(block3RhythmCtrl, 'Rythme'),
                      ],
                    ),
                    _section(
                      '9) Actions physiques',
                      children: [
                        _textField(startPositionCtrl, 'Position de départ'),
                        _textField(plannedMovementCtrl, 'Déplacement prévu'),
                        _textField(
                          expectedGesturesCtrl,
                          'Gestes autorisés / attendus',
                        ),
                        _textField(usedObjectsCtrl, 'Objets utilisés'),
                        _textField(
                          keyActionMomentCtrl,
                          'Moment précis d’une action importante',
                          maxLines: 3,
                        ),
                        _textField(bodyDirectionCtrl, 'Consigne corporelle', maxLines: 3),
                      ],
                    ),
                    _section(
                      '10) Regard / caméra',
                      children: [
                        _dropdown(
                          label: 'Type de cadrage',
                          value: selectedFramingType,
                          items: framingOptions,
                          onChanged: (v) => setState(() => selectedFramingType = v!),
                        ),
                        _dropdown(
                          label: 'Rapport caméra',
                          value: selectedCameraRelation,
                          items: cameraRelationOptions,
                          onChanged: (v) => setState(() => selectedCameraRelation = v!),
                        ),
                        _textField(gazePointCtrl, 'Point de regard'),
                        _textField(faceDirectionCtrl, 'Consigne visage', maxLines: 3),
                      ],
                    ),
                    _section(
                      '11) Rythme et respiration',
                      children: [
                        _dropdown(
                          label: 'Tempo global',
                          value: selectedGlobalTempo,
                          items: tempoOptions,
                          onChanged: (v) => setState(() => selectedGlobalTempo = v!),
                        ),
                        _textField(silencesCtrl, 'Silences à garder', maxLines: 3),
                        _textField(dramaticRiseCtrl, 'Montée dramatique', maxLines: 3),
                      ],
                    ),
                    _section(
                      '12) Repères techniques',
                      children: [
                        _textField(floorMarkCtrl, 'Marque au sol / position'),
                        _textField(startCueCtrl, 'Top départ'),
                        _textField(movementCueCtrl, 'Signal de mouvement'),
                        _textField(exactEndCtrl, 'Moment exact de fin'),
                        _textField(idealTextDurationCtrl, 'Durée idéale du texte'),
                        _textField(
                          technicalConstraintsCtrl,
                          'Contraintes son / lumière / cadre',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    _section(
                      '13) Ce que doit ressentir le spectateur',
                      children: [
                        _textField(
                          spectatorFeelingCtrl,
                          'À la fin de la minute, le spectateur doit ressentir...',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    _section(
                      '14) Note finale du réalisateur',
                      children: [
                        _textField(
                          directorFinalNoteCtrl,
                          'Vision globale de la scène',
                          maxLines: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _save(SceneStatus.draft),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Brouillon'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _save(SceneStatus.published),
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text('Publier'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, {required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...children.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: e,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _dialogueTextField() {
    final message = _dialogueSpeechError ?? _dialogueSpeechStatus;
    final messageColor = _dialogueSpeechError != null
        ? Colors.red.shade600
        : const Color(0xFF0F766E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: dialogueTextCtrl,
          maxLines: 8,
          minLines: 8,
          decoration: InputDecoration(
            labelText: 'Dialogue / monologue',
            alignLabelWithHint: true,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 52,
              minHeight: 52,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _speechInitializing
                      ? null
                      : () {
                          if (_isListeningToDialogue) {
                            _stopDialogueListening();
                          } else {
                            _startDialogueListening();
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isListeningToDialogue
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isListeningToDialogue
                            ? const Color(0xFFEF4444)
                            : Colors.grey.shade300,
                      ),
                      boxShadow: _isListeningToDialogue
                          ? [
                              BoxShadow(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _speechInitializing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isListeningToDialogue
                                  ? Icons.stop_rounded
                                  : Icons.mic_none_rounded,
                              size: 18,
                              color: _isListeningToDialogue
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _dialogueSpeechError != null
                    ? Icons.error_outline_rounded
                    : (_isListeningToDialogue
                        ? Icons.graphic_eq_rounded
                        : Icons.check_circle_outline_rounded),
                size: 16,
                color: messageColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: messageColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _startDialogueListening() async {
    if (_speechInitializing || _isListeningToDialogue) {
      return;
    }

    setState(() {
      _speechInitializing = true;
      _dialogueSpeechError = null;
      _dialogueSpeechStatus = 'Préparation du micro…';
    });

    final hasPermission = await _ensureSpeechPermission();
    if (!hasPermission || !mounted) {
      setState(() {
        _speechInitializing = false;
      });
      return;
    }

    if (!_speechAvailable) {
      _speechAvailable = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
    }

    if (!_speechAvailable) {
      if (!mounted) {
        return;
      }
      setState(() {
        _speechInitializing = false;
        _dialogueSpeechStatus = null;
        _dialogueSpeechError =
            'La reconnaissance vocale n’est pas disponible sur cette plateforme.';
      });
      return;
    }

    _dialogueSpeechBaseText = dialogueTextCtrl.text.trimRight();
    _dialogueReceivedSpeech = false;

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _speechInitializing = false;
      _isListeningToDialogue = true;
      _dialogueSpeechError = null;
      _dialogueSpeechStatus = 'Écoute en cours…';
    });
  }

  Future<void> _stopDialogueListening() async {
    await _speechToText.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _isListeningToDialogue = false;
      if (_dialogueSpeechError == null) {
        _dialogueSpeechStatus = _dialogueReceivedSpeech
            ? 'Dictée ajoutée au dialogue.'
            : 'Aucune voix détectée.';
      }
    });
  }

  Future<bool> _ensureSpeechPermission() async {
    if (kIsWeb) {
      return true;
    }

    final status = await Permission.microphone.status;
    if (status == PermissionStatus.granted) {
      return true;
    }

    final requested = await Permission.microphone.request();
    if (requested == PermissionStatus.granted) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    final isPermanent = requested == PermissionStatus.permanentlyDenied ||
        requested == PermissionStatus.restricted;

    setState(() {
      _dialogueSpeechStatus = null;
      _dialogueSpeechError = isPermanent
          ? 'Microphone refusé. Active-le dans les réglages du système.'
          : 'Microphone refusé. Autorise-le pour dicter le dialogue.';
    });
    return false;
  }

  void _onSpeechStatus(String status) {
    if (!mounted) {
      return;
    }

    if (status == 'listening') {
      setState(() {
        _isListeningToDialogue = true;
        _dialogueSpeechStatus = 'Écoute en cours…';
      });
      return;
    }

    if (status == 'notListening') {
      setState(() {
        _isListeningToDialogue = false;
        if (_dialogueSpeechError == null) {
          _dialogueSpeechStatus = _dialogueReceivedSpeech
              ? 'Dictée ajoutée au dialogue.'
              : 'Aucune voix détectée.';
        }
      });
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) {
      return;
    }

    final raw = error.errorMsg.toLowerCase();
    String message;
    if (raw.contains('permission')) {
      message = 'Microphone refusé. Autorise-le pour utiliser la dictée.';
    } else if (raw.contains('notavailable') || raw.contains('not available')) {
      message = 'Speech to text non disponible sur cette plateforme.';
    } else if (raw.contains('no match') || raw.contains('nomatch')) {
      message = 'Aucune voix détectée.';
    } else {
      message = 'Erreur de reconnaissance vocale.';
    }

    setState(() {
      _speechInitializing = false;
      _isListeningToDialogue = false;
      _dialogueSpeechStatus = null;
      _dialogueSpeechError = message;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords.trim();
    if (recognized.isEmpty) {
      return;
    }

    _dialogueReceivedSpeech = true;
    final separator = _dialogueSpeechBaseText.isEmpty
        ? ''
        : (_dialogueSpeechBaseText.endsWith('\n') ||
                _dialogueSpeechBaseText.endsWith(' ')
            ? ''
            : '\n');
    final nextText = '$_dialogueSpeechBaseText$separator$recognized';

    dialogueTextCtrl.value = dialogueTextCtrl.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
      composing: TextRange.empty,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _dialogueSpeechError = null;
      _dialogueSpeechStatus = result.finalResult
          ? 'Dictée ajoutée au dialogue.'
          : 'Écoute en cours…';
    });
  }

  Widget _requiredField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Champ requis';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.star, size: 12, color: Colors.red),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _chipSelector({
    required String title,
    required List<String> options,
    required List<String> selected,
    required void Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onToggle(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _subBlockTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15.5,
        ),
      ),
    );
  }
}

class _MenuHintItem extends StatelessWidget {
  final String title;

  const _MenuHintItem(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SceneLibraryPage extends StatelessWidget {
  const SceneLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = SceneDraftRepository.all().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque scène'),
        backgroundColor: Colors.transparent,
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Aucune scène enregistrée pour le moment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, index) {
                final item = items[index];
                final isDraft = item.status == SceneStatus.draft;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      item.sceneName.isEmpty ? 'Sans titre' : item.sceneName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Projet : ${item.projectTitle.isEmpty ? '-' : item.projectTitle}\n'
                        'Personnage : ${item.characterName.isEmpty ? '-' : item.characterName}\n'
                        'Statut : ${isDraft ? 'Brouillon' : 'Publié'}',
                        style: TextStyle(
                          height: 1.45,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDraft
                            ? const Color(0xFFFFF4DA)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isDraft ? 'Brouillon' : 'Publié',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDraft
                              ? const Color(0xFF9A6B00)
                              : const Color(0xFF166534),
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: items.length,
            ),
    );
  }
}