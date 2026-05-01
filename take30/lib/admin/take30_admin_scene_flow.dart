import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/veo_generation_job.dart';
import '../services/location_region_service.dart';
import '../services/veo_scene_generation_service.dart';
import 'models/ai_generated_video.dart';
import 'services/veo_video_generation_service.dart';
import 'widgets/admin_video_preview.dart';

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

const _kDefaultVeoPrompt =
    'Video cinematique realiste de 15 secondes, format 16:9, ambiance de court-metrage dramatique. '
    'Plan large au debut sur une rue calme en fin d\'apres-midi, lumiere doree, atmosphere legerement tendue. '
    'La camera avance lentement en travelling vers l\'entree d\'un petit batiment, profondeur de champ cinematographique, '
    'rendu realiste, mouvement fluide, couleurs naturelles, style film independant. '
    'La scene se termine sur un cadrage fixe devant la porte, comme si un personnage allait entrer dans le champ. '
    'Aucun texte a l\'image, aucun logo, aucun visage identifiable.';

DateTime _readAdminDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

String _formatAdminDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return DateFormat('dd/MM/yyyy • HH:mm').format(value);
}

class _SceneGeoMetadata {
  const _SceneGeoMetadata({
    required this.countryCode,
    required this.countryName,
    required this.regionCode,
    required this.regionName,
  });

  final String countryCode;
  final String countryName;
  final String regionCode;
  final String regionName;
}

_SceneGeoMetadata _deriveSceneGeoMetadata({
  String? countryCode,
  String? countryName,
  String? regionCode,
  String? regionName,
  String location = '',
  String whereAreWe = '',
}) {
  final explicitCountryCode = (countryCode ?? '').trim();
  final explicitRegionName = (regionName ?? '').trim();
  if (explicitCountryCode.isNotEmpty || explicitRegionName.isNotEmpty) {
    final resolvedCountryCode = explicitCountryCode.isEmpty
        ? 'GLOBAL'
        : _normalizeSceneCountryCode(explicitCountryCode);
    final resolvedCountryName = (countryName ?? '').trim().isEmpty
        ? (resolvedCountryCode == 'FR' ? 'France' : 'Global')
        : countryName!.trim();
    final resolvedRegionName = explicitRegionName.isEmpty
        ? ((regionCode ?? '').trim().toLowerCase() == 'global' ? 'Global' : '')
        : explicitRegionName;
    final resolvedRegionCode = (regionCode ?? '').trim().isEmpty
        ? (resolvedRegionName.isEmpty
            ? 'global'
            : normalizeRegionCode(resolvedCountryCode, resolvedRegionName))
        : _normalizeSceneRegionCode(
            regionCode!,
            resolvedCountryCode,
            resolvedRegionName,
          );
    return _SceneGeoMetadata(
      countryCode: resolvedCountryCode,
      countryName: resolvedCountryName,
      regionCode: resolvedRegionCode,
      regionName: resolvedRegionName.isEmpty ? 'Global' : resolvedRegionName,
    );
  }

  final haystack = '${location.toLowerCase()} ${whereAreWe.toLowerCase()}';
  const frenchRegions = <String, String>{
    'guadeloupe': 'Guadeloupe',
    'martinique': 'Martinique',
    'guyane': 'Guyane',
    'la réunion': 'La Réunion',
    'la reunion': 'La Réunion',
    'mayotte': 'Mayotte',
    'île-de-france': 'Île-de-France',
    'ile-de-france': 'Île-de-France',
    'île de france': 'Île-de-France',
    'ile de france': 'Île-de-France',
    'nouvelle-aquitaine': 'Nouvelle-Aquitaine',
    'occitanie': 'Occitanie',
    'provence-alpes-côte d’azur': 'Provence-Alpes-Côte d’Azur',
    'provence-alpes-cote d’azur': 'Provence-Alpes-Côte d’Azur',
    'provence alpes cote d azur': 'Provence-Alpes-Côte d’Azur',
    'auvergne-rhône-alpes': 'Auvergne-Rhône-Alpes',
    'auvergne-rhone-alpes': 'Auvergne-Rhône-Alpes',
    'bretagne': 'Bretagne',
    'normandie': 'Normandie',
    'hauts-de-france': 'Hauts-de-France',
    'grand est': 'Grand Est',
    'pays de la loire': 'Pays de la Loire',
    'centre-val de loire': 'Centre-Val de Loire',
    'bourgogne-franche-comté': 'Bourgogne-Franche-Comté',
    'bourgogne-franche-comte': 'Bourgogne-Franche-Comté',
    'corse': 'Corse',
  };

  for (final entry in frenchRegions.entries) {
    if (haystack.contains(entry.key)) {
      return _SceneGeoMetadata(
        countryCode: 'FR',
        countryName: 'France',
        regionCode: normalizeRegionCode('FR', entry.value),
        regionName: entry.value,
      );
    }
  }

  return const _SceneGeoMetadata(
    countryCode: 'GLOBAL',
    countryName: 'Global',
    regionCode: 'global',
    regionName: 'Global',
  );
}

String _normalizeSceneCountryCode(String value) {
  switch (value.trim().toUpperCase()) {
    case 'GP':
    case 'MQ':
    case 'GF':
    case 'RE':
    case 'YT':
      return 'FR';
    case '':
      return 'GLOBAL';
    default:
      return value.trim().toUpperCase();
  }
}

String _normalizeSceneRegionCode(
  String raw,
  String countryCode,
  String regionName,
) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return regionName.isEmpty ? 'global' : normalizeRegionCode(countryCode, regionName);
  }
  if (trimmed.toLowerCase() == 'global') {
    return 'global';
  }
  if (trimmed.contains('_')) {
    return trimmed.toLowerCase();
  }
  return normalizeRegionCode(countryCode, regionName.isEmpty ? trimmed : regionName);
}

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
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final List<SceneFormData> _items = [];

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('scenes');

  static Future<void> save(SceneFormData data) async {
    _upsertLocal(data);
    await _collection.doc(data.id).set(data.toFirestore(), SetOptions(merge: true));
  }

  static Stream<List<SceneFormData>> watchAll() {
    return _collection.where('adminWorkflow', isEqualTo: true).snapshots().map((s) {
      final items = s.docs
          .map((doc) => SceneFormData.fromFirestore(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _items
        ..clear()
        ..addAll(items);
      return List.unmodifiable(items);
    });
  }

  static void _upsertLocal(SceneFormData data) {
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

  static List<SceneFormData> pendingPublication() => _items
      .where((e) => e.status == SceneStatus.pendingPublication)
      .toList();

  static List<SceneFormData> published() =>
      _items.where((e) => e.status == SceneStatus.published).toList();
}

enum SceneStatus { draft, pendingPublication, published }

SceneStatus _sceneStatusFromString(String? value) {
  switch (value) {
    case 'draft':
      return SceneStatus.draft;
    case 'pending_publication':
      return SceneStatus.pendingPublication;
    case 'published':
      return SceneStatus.published;
    default:
      return SceneStatus.draft;
  }
}

extension SceneStatusX on SceneStatus {
  String get value => switch (this) {
        SceneStatus.draft => 'draft',
        SceneStatus.pendingPublication => 'pending_publication',
        SceneStatus.published => 'published',
      };

  String get label => switch (this) {
        SceneStatus.draft => 'Brouillon',
        SceneStatus.pendingPublication => 'En attente de publication',
        SceneStatus.published => 'Publié',
      };
}

List<Map<String, dynamic>> _decodeMarkersJson(String raw) {
  if (raw.trim().isEmpty) return const [];
  try {
    final decoded = json.decode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
  } catch (_) {
    // Si l'admin a saisi du JSON invalide, on ignore — la timeline par défaut
    // sera générée côté lecture.
  }
  return const [];
}

String _encodeMarkersList(dynamic raw) {
  if (raw is! List) return '[]';
  try {
    return const JsonEncoder.withIndent('  ').convert(raw);
  } catch (_) {
    return '[]';
  }
}

class SceneFormData {
  final String id;
  final SceneStatus status;
  final String category;
  final String genre;
  final String recommendedLevel;

  final String projectTitle;
  final String sceneName;
  final String sceneNumber;
  final String shootDate;
  final String location;
  final String countryCode;
  final String countryName;
  final String regionCode;
  final String regionName;
  final String director;
  final String targetDuration;

  final String characterName;
  final String apparentAge;
  final String characterGender;
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
  final String requestedVideoFormat;

  final List<String> testedPrompts;
  final AiGeneratedVideo? aiIntroVideo;
  final String veoPrompt;
  final String veoStatus;
  final String? veoOperationId;
  final String? veoError;
  final String visualTransitionPoint;
  final String emotionalTransitionPoint;
  final String firstActorAction;
  final String firstExpectedEmotion;
  final String lastAiFrameDescription;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? publishedAt;
  final String createdBy;
  final String markersJson;

  const SceneFormData({
    required this.id,
    required this.status,
    required this.category,
    required this.genre,
    required this.recommendedLevel,
    required this.projectTitle,
    required this.sceneName,
    required this.sceneNumber,
    required this.shootDate,
    required this.location,
    this.countryCode = 'GLOBAL',
    this.countryName = 'Global',
    this.regionCode = 'global',
    this.regionName = 'Global',
    required this.director,
    required this.targetDuration,
    required this.characterName,
    required this.apparentAge,
    required this.characterGender,
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
    required this.requestedVideoFormat,
    required this.testedPrompts,
    required this.aiIntroVideo,
    this.veoPrompt = '',
    this.veoStatus = 'none',
    this.veoOperationId,
    this.veoError,
    required this.visualTransitionPoint,
    required this.emotionalTransitionPoint,
    required this.firstActorAction,
    required this.firstExpectedEmotion,
    required this.lastAiFrameDescription,
    required this.createdAt,
    required this.updatedAt,
    required this.submittedAt,
    required this.publishedAt,
    required this.createdBy,
    this.markersJson = '[]',
  });

  String get displayTitle => sceneName.isEmpty ? projectTitle : sceneName;

  String get thumbnailUrl => aiIntroVideo?.thumbnailUrl ?? '';

  int get aiDurationSeconds => aiIntroVideo?.durationSeconds ?? 15;

  bool get hasValidatedAiVideo => aiIntroVideo?.isValidated ?? false;

  SceneFormData copyWith({
    SceneStatus? status,
    AiGeneratedVideo? aiIntroVideo,
    List<String>? testedPrompts,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? publishedAt,
    String? veoPrompt,
    String? veoStatus,
    String? veoOperationId,
    String? veoError,
  }) {
    return SceneFormData(
      id: id,
      status: status ?? this.status,
      category: category,
      genre: genre,
      recommendedLevel: recommendedLevel,
      projectTitle: projectTitle,
      sceneName: sceneName,
      sceneNumber: sceneNumber,
      shootDate: shootDate,
      location: location,
      countryCode: countryCode,
      countryName: countryName,
      regionCode: regionCode,
      regionName: regionName,
      director: director,
      targetDuration: targetDuration,
      characterName: characterName,
      apparentAge: apparentAge,
      characterGender: characterGender,
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
      requestedVideoFormat: requestedVideoFormat,
      testedPrompts: testedPrompts ?? this.testedPrompts,
      aiIntroVideo: aiIntroVideo ?? this.aiIntroVideo,
      veoPrompt: veoPrompt ?? this.veoPrompt,
      veoStatus: veoStatus ?? this.veoStatus,
      veoOperationId: veoOperationId ?? this.veoOperationId,
      veoError: veoError ?? this.veoError,
      visualTransitionPoint: visualTransitionPoint,
      emotionalTransitionPoint: emotionalTransitionPoint,
      firstActorAction: firstActorAction,
      firstExpectedEmotion: firstExpectedEmotion,
      lastAiFrameDescription: lastAiFrameDescription,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      createdBy: createdBy,
      markersJson: markersJson,
    );
  }

  SceneFormData withPublicationStatus(SceneStatus nextStatus) {
    final now = DateTime.now();
    return copyWith(
      status: nextStatus,
      updatedAt: now,
      submittedAt: nextStatus == SceneStatus.pendingPublication ||
              nextStatus == SceneStatus.published
          ? (submittedAt ?? now)
          : null,
      publishedAt:
          nextStatus == SceneStatus.published ? (publishedAt ?? now) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    final nowAuthor = createdBy.isEmpty ? 'admin_take30' : createdBy;
    return {
      'id': id,
      'title': displayTitle,
      'description': contextSummary,
      'category': category,
      'genre': genre,
      'level': recommendedLevel,
      'difficulty': recommendedLevel,
      'status': status.value,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': aiIntroVideo?.videoUrl,
      'durationSeconds': aiDurationSeconds,
      'dialogueText': dialogueText,
      'createdBy': nowAuthor,
      'veoPrompt': veoPrompt.isEmpty ? (aiIntroVideo?.prompt ?? '') : veoPrompt,
      'veoStatus': veoStatus,
      'veoOperationId': veoOperationId,
      'veoError': veoError,
      'authorId': nowAuthor,
      'authorDenorm': {
        'id': nowAuthor,
        'username': nowAuthor,
        'avatarUrl': '',
        'isVerified': false,
      },
      'likesCount': 0,
      'commentsCount': 0,
      'sharesCount': 0,
      'viewsCount': 0,
      'tags': [category, genre, recommendedLevel]
          .where((value) => value.trim().isNotEmpty)
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'adminWorkflow': true,
      'markers': _decodeMarkersJson(markersJson),
      'projectTitle': projectTitle,
      'sceneName': sceneName,
      'sceneNumber': sceneNumber,
      'shootDate': shootDate,
      'location': location,
      'countryCode': countryCode,
      'countryName': countryName,
      'regionCode': regionCode,
      'regionName': regionName,
      'director': director,
      'targetDuration': targetDuration,
      'dominantEmotion': dominantEmotion,
      'secondaryEmotion': secondaryEmotion,
      'intensity': intensity,
      'textType': textType,
      'playStyles': playStyles,
      'testedPrompts': testedPrompts,
      'actorSheet': {
        'characterName': characterName,
        'apparentAge': apparentAge,
        'characterGender': characterGender,
        'roleType': profileRole,
        'mainEmotion': dominantEmotion,
        'characterIntention': mainObjective,
        'dramaticContext': contextSummary,
        'sceneObjective': stakes.isEmpty ? mainObstacle : stakes,
        'expectedTone': playStyles.join(' • '),
        'difficultyLevel': recommendedLevel,
        'actingConstraints': technicalConstraints,
        'stagingInstructions': [actingDirection, bodyDirection]
            .where((value) => value.trim().isNotEmpty)
            .join('\n'),
        'actingTextOrInstructions': dialogueText,
        'expectedActorVideoDuration': targetDuration,
        'recommendedFraming': framingType,
        'requestedVideoFormat': requestedVideoFormat,
        'props': usedObjects,
        'suggestedSet': location.isEmpty ? whereAreWe : location,
        'adminNotes': directorFinalNote,
        'relationship': relationship,
        'initialState': initialState,
        'characterSummary': characterSummary,
        'emphasizedWords': emphasizedWords,
        'keyPhrase': keyPhrase,
      },
      'aiIntroVideo': aiIntroVideo == null
          ? null
          : {
              'provider': aiIntroVideo!.provider,
              'prompt': aiIntroVideo!.prompt,
              'videoUrl': aiIntroVideo!.videoUrl,
              'thumbnailUrl': aiIntroVideo!.thumbnailUrl,
              'durationSeconds': aiIntroVideo!.durationSeconds,
              'aspectRatio': aiIntroVideo!.aspectRatio,
              'status': aiIntroVideo!.status.value,
              'generatedAt': Timestamp.fromDate(aiIntroVideo!.generatedAt),
              'updatedAt': Timestamp.fromDate(aiIntroVideo!.updatedAt),
            },
      'raccord': {
        'visualTransitionPoint': visualTransitionPoint,
        'emotionalTransitionPoint': emotionalTransitionPoint,
        'firstActorAction': firstActorAction,
        'firstExpectedEmotion': firstExpectedEmotion,
        'lastAiFrameDescription': lastAiFrameDescription,
      },
      'publication': {
        'createdBy': nowAuthor,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'submittedAt': submittedAt == null ? null : Timestamp.fromDate(submittedAt!),
        'publishedAt': publishedAt == null ? null : Timestamp.fromDate(publishedAt!),
      },
    };
  }

  factory SceneFormData.fromFirestore(String id, Map<String, dynamic> data) {
    final actorSheet = data['actorSheet'] as Map<String, dynamic>? ?? const {};
    final aiIntroVideo = data['aiIntroVideo'] as Map<String, dynamic>?;
    final raccord = data['raccord'] as Map<String, dynamic>? ?? const {};
    final publication = data['publication'] as Map<String, dynamic>? ?? const {};
    final geo = _deriveSceneGeoMetadata(
      countryCode: data['countryCode'] as String?,
      countryName: data['countryName'] as String?,
      regionCode: data['regionCode'] as String?,
      regionName: data['regionName'] as String?,
      location: data['location'] as String? ?? '',
      whereAreWe: data['whereAreWe'] as String? ?? '',
    );

    return SceneFormData(
      id: id,
      status: _sceneStatusFromString(data['status'] as String?),
      category: data['category'] as String? ?? '',
      genre: data['genre'] as String? ?? '',
      recommendedLevel: data['level'] as String? ?? 'intermediaire',
      projectTitle: data['projectTitle'] as String? ?? '',
      sceneName: data['sceneName'] as String? ?? data['title'] as String? ?? '',
      sceneNumber: data['sceneNumber'] as String? ?? '',
      shootDate: data['shootDate'] as String? ?? '',
      location: data['location'] as String? ?? '',
      countryCode: geo.countryCode,
      countryName: geo.countryName,
      regionCode: geo.regionCode,
      regionName: geo.regionName,
      director: data['director'] as String? ?? '',
      targetDuration: data['targetDuration'] as String? ?? '',
      characterName: actorSheet['characterName'] as String? ?? '',
      apparentAge: actorSheet['apparentAge'] as String? ?? '',
      characterGender: actorSheet['characterGender'] as String? ?? '',
      profileRole: actorSheet['roleType'] as String? ?? '',
      relationship: actorSheet['relationship'] as String? ?? '',
      initialState: actorSheet['initialState'] as String? ?? '',
      characterSummary: actorSheet['characterSummary'] as String? ?? '',
      previousMoment: data['previousMoment'] as String? ?? '',
      whereAreWe: data['whereAreWe'] as String? ?? '',
      withWho: data['withWho'] as String? ?? '',
      whyImportant: data['whyImportant'] as String? ?? '',
      contextSummary: actorSheet['dramaticContext'] as String? ?? '',
      mainObjective: actorSheet['characterIntention'] as String? ?? '',
      mainObstacle: data['mainObstacle'] as String? ?? '',
      stakes: actorSheet['sceneObjective'] as String? ?? '',
      dominantEmotion: actorSheet['mainEmotion'] as String? ?? '',
      secondaryEmotion: data['secondaryEmotion'] as String? ?? '',
      intensity: data['intensity'] as String? ?? '',
      evolutionStart: data['evolutionStart'] as String? ?? '',
      evolutionMiddle: data['evolutionMiddle'] as String? ?? '',
      evolutionEnd: data['evolutionEnd'] as String? ?? '',
      emotionalNuance: data['emotionalNuance'] as String? ?? '',
      playStyles: (data['playStyles'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      actingDirection: actorSheet['stagingInstructions'] as String? ?? '',
      references: data['references'] as String? ?? '',
      textType: data['textType'] as String? ?? '',
      dialogueText: actorSheet['actingTextOrInstructions'] as String? ?? '',
      emphasizedWords: actorSheet['emphasizedWords'] as String? ?? '',
      keyPhrase: actorSheet['keyPhrase'] as String? ?? '',
      block1Intention: data['block1Intention'] as String? ?? '',
      block1Energy: data['block1Energy'] as String? ?? '',
      block1Look: data['block1Look'] as String? ?? '',
      block1Rhythm: data['block1Rhythm'] as String? ?? '',
      block2Intention: data['block2Intention'] as String? ?? '',
      block2Energy: data['block2Energy'] as String? ?? '',
      block2Look: data['block2Look'] as String? ?? '',
      block2Rhythm: data['block2Rhythm'] as String? ?? '',
      block3Intention: data['block3Intention'] as String? ?? '',
      block3Energy: data['block3Energy'] as String? ?? '',
      block3Look: data['block3Look'] as String? ?? '',
      block3Rhythm: data['block3Rhythm'] as String? ?? '',
      startPosition: data['startPosition'] as String? ?? '',
      plannedMovement: data['plannedMovement'] as String? ?? '',
      expectedGestures: data['expectedGestures'] as String? ?? '',
      usedObjects: actorSheet['props'] as String? ?? '',
      keyActionMoment: data['keyActionMoment'] as String? ?? '',
      bodyDirection: data['bodyDirection'] as String? ?? '',
      framingType: actorSheet['recommendedFraming'] as String? ?? '',
      cameraRelation: data['cameraRelation'] as String? ?? '',
      gazePoint: data['gazePoint'] as String? ?? '',
      faceDirection: data['faceDirection'] as String? ?? '',
      globalTempo: data['globalTempo'] as String? ?? '',
      silences: data['silences'] as String? ?? '',
      dramaticRise: data['dramaticRise'] as String? ?? '',
      floorMark: data['floorMark'] as String? ?? '',
      startCue: data['startCue'] as String? ?? '',
      movementCue: data['movementCue'] as String? ?? '',
      exactEnd: data['exactEnd'] as String? ?? '',
      idealTextDuration:
          data['idealTextDuration'] as String? ?? data['durationSeconds']?.toString() ?? '',
      technicalConstraints: actorSheet['actingConstraints'] as String? ?? '',
      spectatorFeeling: data['spectatorFeeling'] as String? ?? '',
      directorFinalNote: actorSheet['adminNotes'] as String? ?? '',
      requestedVideoFormat:
          actorSheet['requestedVideoFormat'] as String? ?? '16:9',
      testedPrompts: (data['testedPrompts'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      aiIntroVideo: aiIntroVideo == null
          ? null
          : AiGeneratedVideo(
              provider: aiIntroVideo['provider'] as String? ?? 'veo3',
              prompt: aiIntroVideo['prompt'] as String? ?? '',
              videoUrl: aiIntroVideo['videoUrl'] as String? ?? '',
              thumbnailUrl: aiIntroVideo['thumbnailUrl'] as String?,
              durationSeconds:
                  (aiIntroVideo['durationSeconds'] as num?)?.toInt() ?? 15,
              aspectRatio: aiIntroVideo['aspectRatio'] as String? ?? '16:9',
              status: aiIntroVideoStatusFromString(
                aiIntroVideo['status'] as String?,
              ),
              generatedAt: _readAdminDate(aiIntroVideo['generatedAt']),
              updatedAt: _readAdminDate(aiIntroVideo['updatedAt']),
            ),
      veoPrompt: data['veoPrompt'] as String? ?? aiIntroVideo?['prompt'] as String? ?? '',
      veoStatus: data['veoStatus'] as String? ?? (aiIntroVideo == null ? 'none' : 'completed'),
      veoOperationId: data['veoOperationId'] as String?,
      veoError: data['veoError'] as String?,
      visualTransitionPoint:
          raccord['visualTransitionPoint'] as String? ?? '',
      emotionalTransitionPoint:
          raccord['emotionalTransitionPoint'] as String? ?? '',
      firstActorAction: raccord['firstActorAction'] as String? ?? '',
      firstExpectedEmotion:
          raccord['firstExpectedEmotion'] as String? ?? '',
      lastAiFrameDescription:
          raccord['lastAiFrameDescription'] as String? ?? '',
      createdAt: _readAdminDate(publication['createdAt'] ?? data['createdAt']),
      updatedAt: _readAdminDate(publication['updatedAt'] ?? data['updatedAt']),
      submittedAt: publication['submittedAt'] == null
          ? null
          : _readAdminDate(publication['submittedAt']),
      publishedAt: publication['publishedAt'] == null
          ? null
          : _readAdminDate(publication['publishedAt']),
      createdBy: publication['createdBy'] as String? ?? 'admin_take30',
      markersJson: _encodeMarkersList(data['markers']),
    );
  }

  /// Fiche réalisateur préremplie pour la scène test « Interrogatoire police ».
  /// Utilisée par le bouton admin « Charger scène test » de [AddScenePage].
  static SceneFormData testPoliceInterrogation() {
    final now = DateTime.now();
    return SceneFormData(
      id: 'scene_test_interrogatoire_police_001',
      status: SceneStatus.draft,
      category: 'Policier',
      genre: 'Drame / Thriller',
      recommendedLevel: 'intermédiaire',
      projectTitle: 'Salle d’interrogatoire',
      sceneName: 'La vérité fissure',
      sceneNumber: 'SC-INT-03',
      shootDate: '2026-04-30',
      location: 'Salle d’interrogatoire — commissariat',
      director: 'Direction interne Take60',
      targetDuration: '60 secondes',
      characterName: 'Malik Renaud',
      apparentAge: '32 ans',
      characterGender: 'Homme',
      profileRole: 'Suspect',
      relationship: 'Interrogé par un officier hors champ',
      initialState: 'Fermé, sur la défensive',
      characterSummary:
          'Homme calme en apparence mais sous pression intérieure intense.',
      previousMoment: 'Il vient d’être confronté à une preuve accablante.',
      whereAreWe: 'Salle d’interrogatoire froide, lumière blanche.',
      withWho: 'Un policier hors champ.',
      whyImportant: 'Moment où il peut craquer.',
      contextSummary: 'La pression monte. Il doit tenir ou céder.',
      mainObjective: 'cacher la vérité',
      mainObstacle:
          'Pression psychologique et preuves présentées par l’enquêteur.',
      stakes: 'Éviter l’inculpation et garder le contrôle.',
      dominantEmotion: 'stress',
      secondaryEmotion: 'colère contenue',
      intensity: 'progressif',
      evolutionStart: 'Calme contrôlé.',
      evolutionMiddle: 'Nervosité visible.',
      evolutionEnd: 'Fissure émotionnelle.',
      emotionalNuance:
          'Ne jamais exploser complètement. Tout doit rester contenu.',
      playStyles: const ['réaliste', 'cinéma', 'intense', 'minimaliste'],
      actingDirection:
          'Moins tu en fais, plus c’est fort. Les yeux parlent plus que les mots.',
      references:
          'Interrogatoires de films policiers réalistes, tension psychologique, jeu sobre.',
      textType: 'dialogue',
      dialogueText:
          'Vous n’avez rien contre moi… rien de solide.\n\nVous bluffez.',
      emphasizedWords: 'rien, solide, bluffez',
      keyPhrase: 'Vous bluffez.',
      block1Intention: 'Résister',
      block1Energy: 'Faible',
      block1Look: 'Fixe',
      block1Rhythm: 'Lent',
      block2Intention: 'Défier',
      block2Energy: 'Montante',
      block2Look: 'Instable',
      block2Rhythm: 'Irrégulier',
      block3Intention: 'Douter',
      block3Energy: 'Fragile',
      block3Look: 'Fuite',
      block3Rhythm: 'Cassé',
      startPosition: 'Assis, mains sur la table.',
      plannedMovement:
          'Léger mouvement du corps vers l’avant puis retrait.',
      expectedGestures:
          'Doigts qui tapent, micro-tensions dans les mains.',
      usedObjects: 'Table, chaise.',
      keyActionMoment:
          'Pause silencieuse avant la phrase : Vous bluffez.',
      bodyDirection:
          'Tension dans la mâchoire, épaules légèrement bloquées.',
      framingType: 'plan rapproché',
      cameraRelation: 'face caméra',
      gazePoint: 'Objectif caméra, comme si le policier était en face.',
      faceDirection:
          'Micro-expressions, regard dur au début puis regard fuyant à la fin.',
      globalTempo: 'lent puis instable',
      silences:
          'Garder des silences avant et après les phrases importantes.',
      dramaticRise:
          'La montée dramatique doit être intérieure, sans cri.',
      floorMark: 'Position fixe assise.',
      startCue: 'Regard caméra, respiration lente.',
      movementCue:
          'Respiration visible avant la deuxième réplique.',
      exactEnd: 'Finir sur un regard fuyant, sans ajouter de texte.',
      idealTextDuration: '20 secondes environ.',
      technicalConstraints:
          'Ambiance silencieuse, lumière froide, cadre stable, aucun bruit parasite.',
      spectatorFeeling:
          'Le spectateur doit ressentir un malaise et se demander s’il cache réellement quelque chose.',
      directorFinalNote:
          'La scène repose sur le non-dit. Chaque silence doit peser plus que les mots.',
      requestedVideoFormat: '16:9',
      testedPrompts: const [],
      aiIntroVideo: null,
      veoPrompt:
          'Vidéo cinématique réaliste, salle d’interrogatoire sombre. Lumière froide au-dessus d’une table métallique. Un homme est assis, légèrement en tension. Caméra en plan fixe avec léger zoom progressif. Atmosphère lourde, silence pesant. Style film policier réaliste. Aucun texte, aucun visage identifiable. La scène se termine sur un regard intense vers la caméra.',
      veoStatus: 'none',
      veoOperationId: null,
      veoError: null,
      visualTransitionPoint: '',
      emotionalTransitionPoint: '',
      firstActorAction: '',
      firstExpectedEmotion: '',
      lastAiFrameDescription: '',
      createdAt: now,
      updatedAt: now,
      submittedAt: null,
      publishedAt: null,
      createdBy: 'admin',
      markersJson: _kPoliceInterrogationMarkersJson,
    );
  }
}

const String _kPoliceInterrogationMarkersJson = '''
[
  {
    "id": "police_intro",
    "order": 0,
    "type": "user_intro",
    "durationSeconds": 15,
    "label": "Observation silencieuse",
    "cameraPlan": "Plan rapproché",
    "character": "Malik",
    "dialogue": "",
    "cueText": "Regarde l’enquêteur, analyse, respire lentement. Ne parle pas."
  },
  {
    "id": "police_dialogue",
    "order": 1,
    "type": "user_dialogue",
    "durationSeconds": 25,
    "label": "Réplique principale",
    "cameraPlan": "Face caméra",
    "character": "Malik",
    "dialogue": "Vous n’avez rien contre moi… rien de solide.",
    "cueText": "Reste calme, mais laisse apparaître une tension dans le regard."
  },
  {
    "id": "police_emotion",
    "order": 2,
    "type": "user_emotion",
    "durationSeconds": 20,
    "label": "Fissure finale",
    "cameraPlan": "Plan fixe rapproché",
    "character": "Malik",
    "dialogue": "Vous bluffez.",
    "cueText": "Laisse apparaître le doute. Le regard fuit légèrement à la fin."
  }
]
''';

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
      body: StreamBuilder<List<SceneFormData>>(
        stream: SceneDraftRepository.watchAll(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? SceneDraftRepository.all();
          final drafts = items.where((item) => item.status == SceneStatus.draft).length;
          final pending = items
              .where((item) => item.status == SceneStatus.pendingPublication)
              .length;
          final published = items
              .where((item) => item.status == SceneStatus.published)
              .length;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _AdminTile(
                  title: 'Ajout scène',
                  subtitle: 'Créer la scène, la fiche acteur et la video IA',
                  icon: Icons.add_box_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C4DFF), Color(0xFF8D74FF)],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AddScenePage(enableAdminTools: true),
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
                  subtitle:
                      '$drafts brouillon(s) • $pending en attente • $published publiee(s)',
                  icon: Icons.video_library_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
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
          );
        },
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              child: Icon(icon, color: Colors.white),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsFullPage extends StatelessWidget {
  const AnalyticsFullPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics full'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<SceneFormData>>(
        stream: SceneDraftRepository.watchAll(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? SceneDraftRepository.all();
          final drafts = items.where((item) => item.status == SceneStatus.draft).toList();
          final pending = items
              .where((item) => item.status == SceneStatus.pendingPublication)
              .toList();
          final published = items
              .where((item) => item.status == SceneStatus.published)
              .toList();
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
            emptyLabel: 'Non definie',
          );
          final topDirectors = _sortedCountEntries(
            items.map((item) => item.director),
            emptyLabel: 'Non renseigne',
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _AnalyticsStatCard(
                      label: 'Scenes',
                      value: items.length.toString(),
                      color: const Color(0xFF6C4DFF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticsStatCard(
                      label: 'Brouillons',
                      value: drafts.length.toString(),
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticsStatCard(
                      label: 'En attente',
                      value: pending.length.toString(),
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticsStatCard(
                      label: 'Publiees',
                      value: published.length.toString(),
                      color: const Color(0xFF0F766E),
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
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticsStatCard(
                      label: 'Personnages',
                      value: uniqueCharacters.toString(),
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _AnalyticsBreakdownCard(
                title: 'Statuts',
                items: [
                  ('Brouillon', drafts.length, const Color(0xFFF97316)),
                  ('En attente', pending.length, const Color(0xFF1D4ED8)),
                  ('Publiee', published.length, const Color(0xFF0F766E)),
                ],
              ),
              const SizedBox(height: 16),
              _AnalyticsListCard(
                title: 'Top projets',
                entries: topProjects,
              ),
              const SizedBox(height: 16),
              _AnalyticsListCard(
                title: 'Emotions dominantes',
                entries: topEmotions,
              ),
              const SizedBox(height: 16),
              _AnalyticsListCard(
                title: 'Direction / realisation',
                entries: topDirectors,
              ),
            ],
          );
        },
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
    required this.title,
    required this.items,
  });

  final String title;
  final List<(String, int, Color)> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (runningTotal, item) => runningTotal + item.$2);
    final safeTotal = total == 0 ? 1 : total;

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
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (items.every((item) => item.$2 == 0))
                    const Expanded(child: ColoredBox(color: Color(0xFFE5E7EB))),
                  ...items.where((item) => item.$2 > 0).map(
                        (item) => Expanded(
                          flex: ((item.$2 / safeTotal) * 1000).round(),
                          child: Container(color: item.$3),
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: items
                .map(
                  (item) => _LegendDot(
                    color: item.$3,
                    label: '${item.$1} ${item.$2}',
                  ),
                )
                .toList(),
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
  const AddScenePage({
    super.key,
    this.initialData,
    this.veoVideoGenerationService,
    this.veoSceneGenerationService,
    this.enableAdminTools = false,
  });

  final SceneFormData? initialData;
  final VeoVideoGenerationService? veoVideoGenerationService;
  final VeoSceneGenerationService? veoSceneGenerationService;
  final bool enableAdminTools;

  @override
  State<AddScenePage> createState() => _AddScenePageState();
}

class _AddScenePageState extends State<AddScenePage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final SpeechToText _speechToText = SpeechToText();
  late final VeoVideoGenerationService _veoVideoGenerationService;
  late final VeoSceneGenerationService _veoSceneGenerationService;
  late final bool _useCallableVeoFlow;
  final _step15SectionKey = GlobalKey();
  final _step16SectionKey = GlobalKey();

  late final String _sceneDraftId;
  late final DateTime _sceneCreatedAt;

  final categoryCtrl = TextEditingController(text: 'Audition');
  final genreCtrl = TextEditingController(text: 'Drame');

  final projectTitleCtrl = TextEditingController();
  final sceneNameCtrl = TextEditingController();
  final sceneNumberCtrl = TextEditingController();
  final shootDateCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final directorCtrl = TextEditingController();
  final targetDurationCtrl = TextEditingController(text: '1 minute maximum');

  final characterNameCtrl = TextEditingController();
  final apparentAgeCtrl = TextEditingController();
  final characterGenderCtrl = TextEditingController();
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
  final requestedVideoFormatCtrl = TextEditingController(text: '16:9');
  final veoPromptCtrl = TextEditingController(text: _kDefaultVeoPrompt);
  final visualTransitionPointCtrl = TextEditingController();
  final emotionalTransitionPointCtrl = TextEditingController();
  final firstActorActionCtrl = TextEditingController();
  final firstExpectedEmotionCtrl = TextEditingController();
  final lastAiFrameDescriptionCtrl = TextEditingController();
  final markersJsonCtrl = TextEditingController(text: '[]');

  String selectedMainObjective = 'convaincre';
  String selectedDominantEmotion = 'détermination';
  String selectedSecondaryEmotion = 'fragilité';
  String selectedIntensity = 'moyen';
  String selectedTextType = 'texte exact à respecter';
  String selectedFramingType = 'plan poitrine';
  String selectedCameraRelation = 'légèrement hors caméra';
  String selectedGlobalTempo = 'progressif';
  String selectedRecommendedLevel = 'intermédiaire';

  final List<String> selectedStyles = ['cinéma', 'intense'];

  final objectiveOptions = const [
    'convaincre',
    'séduire',
    'se défendre',
    'cacher sa peur',
    'cacher la vérité',
    'récupérer la confiance',
    'impressionner',
    'faire rire',
    'dominer la situation',
    'demander pardon',
    'retenir quelqu’un',
  ];

  final emotionOptions = const [
    'colère',
    'colère contenue',
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

  final intensityOptions = const ['faible', 'moyen', 'fort', 'progressif'];

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
    'minimaliste',
  ];

  final textTypeOptions = const [
    'texte exact à respecter',
    'texte semi-libre',
    'improvisation guidée',
    'dialogue',
  ];

  final framingOptions = const [
    'gros plan',
    'plan rapproché',
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
    'lent puis instable',
    'posé',
    'fluide',
    'nerveux',
    'progressif',
    'punchy',
  ];

  final recommendedLevelOptions = const [
    'débutant',
    'intermédiaire',
    'confirmé',
    'avancé',
  ];

  bool _speechAvailable = false;
  bool _speechInitializing = false;
  bool _isListeningToDialogue = false;
  bool _dialogueReceivedSpeech = false;
  String _dialogueSpeechBaseText = '';
  String? _dialogueSpeechStatus;
  String? _dialogueSpeechError;
  bool _isGeneratingPreview = false;
  bool _isVeoPromptLocked = false;
  String _veoStatusValue = 'none';
  String? _veoOperationId;
  String? _veoGenerationStatus;
  String? _veoGenerationError;
  AiGeneratedVideo? _generatedPreviewVideo;
  AiGeneratedVideo? _validatedPreviewVideo;
  List<String> _testedPrompts = [];
  SceneStatus _selectedPublicationTarget = SceneStatus.draft;

  bool get _canShowAdminTestTools => widget.enableAdminTools;

  @override
  void initState() {
    super.initState();
    _veoVideoGenerationService = widget.veoVideoGenerationService ??
      VeoVideoGenerationServiceFactory.createDefault();
    _veoSceneGenerationService =
        widget.veoSceneGenerationService ?? VeoSceneGenerationService();
    _useCallableVeoFlow = widget.veoVideoGenerationService == null;
    _sceneDraftId =
        widget.initialData?.id ?? 'scene_${DateTime.now().millisecondsSinceEpoch}';
    _sceneCreatedAt = widget.initialData?.createdAt ?? DateTime.now();
    if (widget.initialData != null) {
      _hydrateFromDraft(widget.initialData!);
    }
  }

  void _hydrateFromDraft(SceneFormData data) {
    categoryCtrl.text = data.category;
    genreCtrl.text = data.genre;
    projectTitleCtrl.text = data.projectTitle;
    sceneNameCtrl.text = data.sceneName;
    sceneNumberCtrl.text = data.sceneNumber;
    shootDateCtrl.text = data.shootDate;
    locationCtrl.text = data.location;
    directorCtrl.text = data.director;
    targetDurationCtrl.text = data.targetDuration;
    characterNameCtrl.text = data.characterName;
    apparentAgeCtrl.text = data.apparentAge;
    characterGenderCtrl.text = data.characterGender;
    profileRoleCtrl.text = data.profileRole;
    relationshipCtrl.text = data.relationship;
    initialStateCtrl.text = data.initialState;
    characterSummaryCtrl.text = data.characterSummary;
    previousMomentCtrl.text = data.previousMoment;
    whereAreWeCtrl.text = data.whereAreWe;
    withWhoCtrl.text = data.withWho;
    whyImportantCtrl.text = data.whyImportant;
    contextSummaryCtrl.text = data.contextSummary;
    mainObstacleCtrl.text = data.mainObstacle;
    stakesCtrl.text = data.stakes;
    evolutionStartCtrl.text = data.evolutionStart;
    evolutionMiddleCtrl.text = data.evolutionMiddle;
    evolutionEndCtrl.text = data.evolutionEnd;
    emotionalNuanceCtrl.text = data.emotionalNuance;
    actingDirectionCtrl.text = data.actingDirection;
    referencesCtrl.text = data.references;
    dialogueTextCtrl.text = data.dialogueText;
    emphasizedWordsCtrl.text = data.emphasizedWords;
    keyPhraseCtrl.text = data.keyPhrase;
    block1IntentionCtrl.text = data.block1Intention;
    block1EnergyCtrl.text = data.block1Energy;
    block1LookCtrl.text = data.block1Look;
    block1RhythmCtrl.text = data.block1Rhythm;
    block2IntentionCtrl.text = data.block2Intention;
    block2EnergyCtrl.text = data.block2Energy;
    block2LookCtrl.text = data.block2Look;
    block2RhythmCtrl.text = data.block2Rhythm;
    block3IntentionCtrl.text = data.block3Intention;
    block3EnergyCtrl.text = data.block3Energy;
    block3LookCtrl.text = data.block3Look;
    block3RhythmCtrl.text = data.block3Rhythm;
    startPositionCtrl.text = data.startPosition;
    plannedMovementCtrl.text = data.plannedMovement;
    expectedGesturesCtrl.text = data.expectedGestures;
    usedObjectsCtrl.text = data.usedObjects;
    keyActionMomentCtrl.text = data.keyActionMoment;
    bodyDirectionCtrl.text = data.bodyDirection;
    gazePointCtrl.text = data.gazePoint;
    faceDirectionCtrl.text = data.faceDirection;
    silencesCtrl.text = data.silences;
    dramaticRiseCtrl.text = data.dramaticRise;
    floorMarkCtrl.text = data.floorMark;
    startCueCtrl.text = data.startCue;
    movementCueCtrl.text = data.movementCue;
    exactEndCtrl.text = data.exactEnd;
    idealTextDurationCtrl.text = data.idealTextDuration;
    technicalConstraintsCtrl.text = data.technicalConstraints;
    spectatorFeelingCtrl.text = data.spectatorFeeling;
    directorFinalNoteCtrl.text = data.directorFinalNote;
    requestedVideoFormatCtrl.text = data.requestedVideoFormat;
    veoPromptCtrl.text = data.veoPrompt.isNotEmpty
      ? data.veoPrompt
      : (data.aiIntroVideo?.prompt ?? _kDefaultVeoPrompt);
    visualTransitionPointCtrl.text = data.visualTransitionPoint;
    emotionalTransitionPointCtrl.text = data.emotionalTransitionPoint;
    firstActorActionCtrl.text = data.firstActorAction;
    firstExpectedEmotionCtrl.text = data.firstExpectedEmotion;
    lastAiFrameDescriptionCtrl.text = data.lastAiFrameDescription;
    markersJsonCtrl.text =
        data.markersJson.trim().isEmpty ? '[]' : data.markersJson;

    selectedMainObjective = data.mainObjective.isEmpty ? selectedMainObjective : data.mainObjective;
    selectedDominantEmotion = data.dominantEmotion.isEmpty
        ? selectedDominantEmotion
        : data.dominantEmotion;
    selectedSecondaryEmotion = data.secondaryEmotion.isEmpty
        ? selectedSecondaryEmotion
        : data.secondaryEmotion;
    selectedIntensity = data.intensity.isEmpty ? selectedIntensity : data.intensity;
    selectedTextType = data.textType.isEmpty ? selectedTextType : data.textType;
    selectedFramingType =
        data.framingType.isEmpty ? selectedFramingType : data.framingType;
    selectedCameraRelation = data.cameraRelation.isEmpty
        ? selectedCameraRelation
        : data.cameraRelation;
    selectedGlobalTempo =
        data.globalTempo.isEmpty ? selectedGlobalTempo : data.globalTempo;
    selectedRecommendedLevel = data.recommendedLevel.isEmpty
        ? selectedRecommendedLevel
        : data.recommendedLevel;
    selectedStyles
      ..clear()
      ..addAll(data.playStyles);
    _testedPrompts = List<String>.from(data.testedPrompts);
    _generatedPreviewVideo = data.aiIntroVideo;
    _validatedPreviewVideo = data.aiIntroVideo?.isValidated == true
        ? data.aiIntroVideo
        : null;
    _isVeoPromptLocked = data.aiIntroVideo != null;
    _veoStatusValue = data.veoStatus;
    _veoOperationId = data.veoOperationId;
    _veoGenerationError = data.veoError;
    _selectedPublicationTarget = data.status;
  }

  void _loadPoliceInterrogationTestScene() {
    setState(() {
      _hydrateFromDraft(SceneFormData.testPoliceInterrogation());
      _selectedPublicationTarget = SceneStatus.draft;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Scène test interrogatoire police chargée.'),
          duration: Duration(seconds: 3),
        ),
      );
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _scrollController.dispose();
    for (final c in [
      categoryCtrl,
      genreCtrl,
      projectTitleCtrl,
      sceneNameCtrl,
      sceneNumberCtrl,
      shootDateCtrl,
      locationCtrl,
      directorCtrl,
      targetDurationCtrl,
      characterNameCtrl,
      apparentAgeCtrl,
      characterGenderCtrl,
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
      requestedVideoFormatCtrl,
      veoPromptCtrl,
      visualTransitionPointCtrl,
      emotionalTransitionPointCtrl,
      firstActorActionCtrl,
      firstExpectedEmotionCtrl,
      lastAiFrameDescriptionCtrl,
      markersJsonCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  SceneFormData _composeData(SceneStatus status, {DateTime? updatedAt}) {
    final now = updatedAt ?? DateTime.now();
    final currentVideo = (_validatedPreviewVideo ?? _generatedPreviewVideo)
        ?.copyWith(
          status: _validatedPreviewVideo != null
              ? AiIntroVideoStatus.validated
              : (_generatedPreviewVideo?.status ?? AiIntroVideoStatus.generated),
          prompt: veoPromptCtrl.text.trim(),
          updatedAt: now,
        );
    final geo = _deriveSceneGeoMetadata(
      countryCode: widget.initialData?.countryCode,
      countryName: widget.initialData?.countryName,
      regionCode: widget.initialData?.regionCode,
      regionName: widget.initialData?.regionName,
      location: locationCtrl.text.trim(),
      whereAreWe: whereAreWeCtrl.text.trim(),
    );

    return SceneFormData(
      id: _sceneDraftId,
      status: status,
      category: categoryCtrl.text.trim(),
      genre: genreCtrl.text.trim(),
      recommendedLevel: selectedRecommendedLevel,
      projectTitle: projectTitleCtrl.text.trim(),
      sceneName: sceneNameCtrl.text.trim(),
      sceneNumber: sceneNumberCtrl.text.trim(),
      shootDate: shootDateCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      countryCode: geo.countryCode,
      countryName: geo.countryName,
      regionCode: geo.regionCode,
      regionName: geo.regionName,
      director: directorCtrl.text.trim(),
      targetDuration: targetDurationCtrl.text.trim(),
      characterName: characterNameCtrl.text.trim(),
      apparentAge: apparentAgeCtrl.text.trim(),
      characterGender: characterGenderCtrl.text.trim(),
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
      requestedVideoFormat: requestedVideoFormatCtrl.text.trim(),
      testedPrompts: _testedPrompts,
      aiIntroVideo: currentVideo,
      visualTransitionPoint: visualTransitionPointCtrl.text.trim(),
      emotionalTransitionPoint: emotionalTransitionPointCtrl.text.trim(),
      firstActorAction: firstActorActionCtrl.text.trim(),
      firstExpectedEmotion: firstExpectedEmotionCtrl.text.trim(),
      lastAiFrameDescription: lastAiFrameDescriptionCtrl.text.trim(),
      createdAt: _sceneCreatedAt,
      updatedAt: now,
      submittedAt: status == SceneStatus.pendingPublication ||
              status == SceneStatus.published
          ? (widget.initialData?.submittedAt ?? now)
          : null,
      publishedAt:
          status == SceneStatus.published ? (widget.initialData?.publishedAt ?? now) : null,
      createdBy: _currentCreatorId(),
      veoPrompt: veoPromptCtrl.text.trim(),
      veoStatus: _normalizedVeoStatusValue(),
      veoOperationId: _veoOperationId,
      veoError: _veoGenerationError,
      markersJson: markersJsonCtrl.text.trim().isEmpty
          ? '[]'
          : markersJsonCtrl.text.trim(),
    );
  }

  SceneFormData _buildData(SceneStatus status) => _composeData(status);

  SceneFormData _currentPreviewData() =>
      _composeData(_selectedPublicationTarget, updatedAt: DateTime.now());

  bool _hasActorSheet() {
    return characterNameCtrl.text.trim().isNotEmpty &&
        dialogueTextCtrl.text.trim().isNotEmpty;
  }

  void _showAdminMessage(String message, {Color? backgroundColor}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String _currentCreatorId() {
    try {
      return fa.FirebaseAuth.instance.currentUser?.uid ??
          adminAccessController.value.identifier ??
          'admin_take30';
    } catch (_) {
      return adminAccessController.value.identifier ?? 'admin_take30';
    }
  }

  String _normalizedVeoStatusValue() {
    if (_veoStatusValue != 'none') {
      return _veoStatusValue;
    }
    if (_validatedPreviewVideo != null || _generatedPreviewVideo != null) {
      return 'completed';
    }
    return 'none';
  }

  String _statusMessageFor(VeoGenerationStatus status) {
    switch (status) {
      case VeoGenerationStatus.none:
        return 'Statut VEO: none';
      case VeoGenerationStatus.queued:
        return 'Statut VEO: queued';
      case VeoGenerationStatus.generating:
        return 'Statut VEO: generating';
      case VeoGenerationStatus.completed:
        return 'Statut VEO: completed';
      case VeoGenerationStatus.failed:
        return 'Statut VEO: failed';
    }
  }

  AiGeneratedVideo _buildAiVideoFromJob(VeoGenerationJob job, String prompt) {
    final generatedAt = job.updatedAt ?? DateTime.now();
    return AiGeneratedVideo(
      provider: 'veo3',
      prompt: job.prompt.isEmpty ? prompt : job.prompt,
      videoUrl: job.videoUrl ?? '',
      thumbnailUrl: job.thumbnailUrl,
      durationSeconds: job.durationSeconds,
      aspectRatio: job.aspectRatio,
      status: AiIntroVideoStatus.generated,
      generatedAt: generatedAt,
      updatedAt: generatedAt,
    );
  }

  Future<void> _pollCallablePreviewGeneration(String prompt) async {
    for (var attempt = 0; attempt < 12; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));

      final job = await _veoSceneGenerationService.checkVeoSceneGeneration(
        sceneId: _sceneDraftId,
      );

      if (!mounted) {
        return;
      }

      if (job.isCompleted && (job.videoUrl?.isNotEmpty ?? false)) {
        setState(() {
          _generatedPreviewVideo = _buildAiVideoFromJob(job, prompt);
          _validatedPreviewVideo = null;
          _isGeneratingPreview = false;
          _veoStatusValue = job.status.value;
          _veoOperationId = job.operationId ?? _veoOperationId;
          _veoGenerationError = null;
          _veoGenerationStatus =
              'Preview générée. Vérifie le raccord final puis valide la vidéo.';
        });
        return;
      }

      if (job.isFailed) {
        setState(() {
          _isGeneratingPreview = false;
          _isVeoPromptLocked = false;
          _veoStatusValue = job.status.value;
          _veoGenerationStatus = null;
          _veoGenerationError = job.errorMessage ??
              'La génération VEO a échoué côté backend.';
        });
        return;
      }

      setState(() {
        _veoStatusValue = job.status.value;
        _veoOperationId = job.operationId ?? _veoOperationId;
        _veoGenerationStatus = _statusMessageFor(job.status);
      });
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isGeneratingPreview = false;
      _isVeoPromptLocked = false;
      _veoStatusValue = 'failed';
      _veoGenerationStatus = null;
      _veoGenerationError =
          'La génération VEO prend plus de temps que prévu. Réessaie ou vérifie le backend.';
    });
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  Future<void> _persistScene(
    SceneStatus status, {
    required bool requireValidatedVideo,
  }) async {
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
      return;
    }

    if (!_hasActorSheet()) {
      _showAdminMessage(
        'La fiche acteur doit au minimum contenir un personnage et un texte.',
        backgroundColor: const Color(0xFFB91C1C),
      );
      return;
    }

    if (requireValidatedVideo && _validatedPreviewVideo == null) {
      _showAdminMessage(
        'Une video IA validee est requise avant de generer la scene.',
        backgroundColor: const Color(0xFFB91C1C),
      );
      await _scrollToSection(_step15SectionKey);
      return;
    }

    final data = _buildData(status);
    await SceneDraftRepository.save(data);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedPublicationTarget = status;
    });

    _showAdminMessage(
      switch (status) {
        SceneStatus.draft => 'Scene enregistree en brouillon.',
        SceneStatus.pendingPublication =>
          'Scene envoyee en attente de publication.',
        SceneStatus.published => 'Scene publiee dans la bibliotheque.',
      },
      backgroundColor: const Color(0xFF0F766E),
    );
  }

  Future<void> _saveDraft() {
    return _persistScene(SceneStatus.draft, requireValidatedVideo: false);
  }

  Future<void> _generateScene() {
    return _persistScene(
      _selectedPublicationTarget,
      requireValidatedVideo: true,
    );
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
                      _MenuHintItem('15. Vidéo IA d’introduction'),
                      _MenuHintItem('16. Preview détail'),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                  children: [
                    if (_canShowAdminTestTools) ...[
                      Card(
                        color: const Color(0xFFFFF7DC),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE8C56A)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.science_outlined,
                                  color: Color(0xFF8A6A00)),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Outil admin : préremplir le formulaire avec '
                                  'la fiche test « Interrogatoire police » '
                                  '(scène 60 s, 3 plans).',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF5A4500),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _loadPoliceInterrogationTestScene,
                                icon: const Icon(Icons.download),
                                label: const Text(
                                  'Charger scène test — Interrogatoire police',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _section(
                      '1) Informations générales',
                      children: [
                        _requiredField(projectTitleCtrl, 'Titre du projet'),
                        _requiredField(sceneNameCtrl, 'Nom de la scène'),
                        _requiredField(categoryCtrl, 'Catégorie'),
                        _requiredField(genreCtrl, 'Genre'),
                        _dropdown(
                          label: 'Niveau recommandé',
                          value: selectedRecommendedLevel,
                          items: recommendedLevelOptions,
                          onChanged: (value) =>
                              setState(() => selectedRecommendedLevel = value!),
                        ),
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
                        _textField(characterGenderCtrl, 'Genre du personnage'),
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
                    _section(
                      '15) Vidéo IA d’introduction',
                      sectionKey: _step15SectionKey,
                      children: [
                        const Text(
                          'Rédigez ici le prompt qui servira à générer une vidéo cinématique d’environ 15 secondes. Cette vidéo doit préparer l’ambiance émotionnelle de la scène sans voler la place de l’acteur. Elle doit idéalement se terminer sur un cadrage permettant un raccord naturel avec la scène jouée.',
                          style: TextStyle(height: 1.5, color: Color(0xFF4B5563)),
                        ),
                        TextFormField(
                          controller: veoPromptCtrl,
                          enabled: !_isGeneratingPreview && !_isVeoPromptLocked,
                          maxLines: 8,
                          minLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Prompt VEO3',
                            alignLabelWithHint: true,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Exemple de prompt',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(_kDefaultVeoPrompt),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aide prompt VEO3',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text('• Durée recommandée : environ 15 secondes.'),
                              Text('• Format recommandé : 16:9.'),
                              Text('• Décrire le décor, l’ambiance, la lumière, le mouvement de caméra et le raccord final.'),
                              Text('• Éviter les visages identifiables.'),
                              Text('• Éviter le texte à l’image.'),
                              Text('• Éviter les logos.'),
                              Text('• La vidéo IA doit servir d’introduction émotionnelle.'),
                            ],
                          ),
                        ),
                        if (_veoStatusValue != 'none' || _veoOperationId != null)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  'Statut: ${veoGenerationStatusFromString(_veoStatusValue).label}',
                                ),
                              ),
                              if (_veoOperationId != null)
                                Chip(label: Text('Opération: $_veoOperationId')),
                            ],
                          ),
                        if (_testedPrompts.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _testedPrompts
                                .map(
                                  (prompt) => ActionChip(
                                    label: Text(
                                      prompt.length > 42
                                          ? '${prompt.substring(0, 42)}…'
                                          : prompt,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        veoPromptCtrl.text = prompt;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        if (_veoGenerationError != null || _veoGenerationStatus != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _veoGenerationError != null
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _veoGenerationError != null
                                      ? Icons.error_outline_rounded
                                      : Icons.auto_awesome_rounded,
                                  color: _veoGenerationError != null
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF0F766E),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _veoGenerationError ?? _veoGenerationStatus!,
                                    style: TextStyle(
                                      color: _veoGenerationError != null
                                          ? const Color(0xFF991B1B)
                                          : const Color(0xFF065F46),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        FilledButton.icon(
                          onPressed: _isGeneratingPreview ? null : _generatePreviewVideo,
                          icon: _isGeneratingPreview
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(
                            _isGeneratingPreview
                                ? 'Génération de la preview vidéo en cours…'
                                : 'Valider et générer la preview',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        if (_generatedPreviewVideo != null) ...[
                          AdminVideoPreview(
                            videoUrl: _generatedPreviewVideo!.videoUrl,
                            thumbnailUrl: _generatedPreviewVideo!.thumbnailUrl,
                            caption:
                                'Vidéo IA d’introduction — destinée à créer l’ambiance de la scène.',
                          ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _correctVeoPrompt,
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Corriger le prompt'),
                              ),
                              FilledButton.icon(
                                onPressed: _validatedPreviewVideo != null
                                    ? null
                                    : _validateGeneratedVideo,
                                icon: Icon(
                                  _validatedPreviewVideo != null
                                      ? Icons.check_circle_rounded
                                      : Icons.verified_rounded,
                                ),
                                label: Text(
                                  _validatedPreviewVideo != null
                                      ? 'Vidéo validée'
                                      : 'Valider cette vidéo',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    _section(
                      '15bis) Montage automatique dialogué (timeline Take60)',
                      children: [
                        const Text(
                          'Définis les marqueurs de la timeline guidée: alternance de plans IA et de plans utilisateur. Pour chaque plan, choisis le type, la durée, la réplique imposée et le cadrage caméra. La durée totale ne doit pas dépasser 60 secondes.',
                          style: TextStyle(height: 1.5, color: Color(0xFF4B5563)),
                        ),
                        _GuidedTimelineEditor(controller: markersJsonCtrl),
                      ],
                    ),
                    _section(
                      '16) Prévisualisation de la page détail de scène',
                      sectionKey: _step16SectionKey,
                      children: [
                        const Text(
                          'L’admin voit ici exactement comment la scène apparaîtra avant publication. La vidéo IA reste toujours une introduction émotionnelle, distincte de la prestation de l’acteur.',
                          style: TextStyle(height: 1.5, color: Color(0xFF4B5563)),
                        ),
                        _SceneDetailPreview(scene: _currentPreviewData()),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              icon: const Icon(Icons.tune_rounded),
                              label: const Text('Modifier les informations'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                _correctVeoPrompt();
                                await _scrollToSection(_step15SectionKey);
                              },
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('Modifier le prompt VEO3'),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  _isGeneratingPreview ? null : _generatePreviewVideo,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Régénérer la vidéo'),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: SceneStatus.values
                              .map(
                                (status) => ChoiceChip(
                                  label: Text(status.label),
                                  selected: _selectedPublicationTarget == status,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedPublicationTarget = status;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _saveDraft,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Enregistrer en brouillon'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                setState(() {
                                  _selectedPublicationTarget =
                                      SceneStatus.pendingPublication;
                                });
                                _generateScene();
                              },
                              icon: const Icon(Icons.schedule_send_rounded),
                              label: const Text('Envoyer en attente de publication'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                setState(() {
                                  _selectedPublicationTarget = SceneStatus.published;
                                });
                                _generateScene();
                              },
                              icon: const Icon(Icons.publish_rounded),
                              label: const Text('Publier'),
                            ),
                          ],
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
                  onPressed: _saveDraft,
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
                  onPressed: _generateScene,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Générer la scène'),
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

  Widget _section(
    String title, {
    Key? sectionKey,
    required List<Widget> children,
  }) {
    return Card(
      key: sectionKey,
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

  Future<void> _generatePreviewVideo() async {
    final prompt = veoPromptCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _veoGenerationError = 'Le prompt VEO3 est obligatoire.';
        _veoGenerationStatus = null;
        _veoStatusValue = 'failed';
      });
      return;
    }

    setState(() {
      _veoGenerationError = null;
      _veoGenerationStatus = 'Statut VEO: queued';
      _isGeneratingPreview = true;
      _isVeoPromptLocked = true;
      _veoStatusValue = 'queued';
      _veoOperationId = null;
      if (!_testedPrompts.contains(prompt)) {
        _testedPrompts = [..._testedPrompts, prompt];
      }
    });

    try {
      if (_useCallableVeoFlow) {
        final job = await _veoSceneGenerationService.requestVeoScenePreview(
          sceneId: _sceneDraftId,
          prompt: prompt,
          durationSeconds: 15,
          aspectRatio: requestedVideoFormatCtrl.text.trim().isEmpty
              ? '16:9'
              : requestedVideoFormatCtrl.text.trim(),
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _veoStatusValue = job.status.value;
          _veoOperationId = job.operationId;
          _veoGenerationStatus = _statusMessageFor(job.status);
        });

        if (job.isCompleted && (job.videoUrl?.isNotEmpty ?? false)) {
          setState(() {
            _generatedPreviewVideo = _buildAiVideoFromJob(job, prompt);
            _validatedPreviewVideo = null;
            _isGeneratingPreview = false;
            _veoStatusValue = job.status.value;
            _veoGenerationStatus =
                'Preview générée. Vérifie le raccord final puis valide la vidéo.';
          });
          return;
        }

        await _pollCallablePreviewGeneration(prompt);
        return;
      }

      final generated = await _veoVideoGenerationService.generateSceneIntroVideo(
        sceneDraftId: _sceneDraftId,
        prompt: prompt,
        durationSeconds: 15,
        aspectRatio: requestedVideoFormatCtrl.text.trim().isEmpty
            ? '16:9'
            : requestedVideoFormatCtrl.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _generatedPreviewVideo = generated;
        _validatedPreviewVideo = null;
        _isGeneratingPreview = false;
        _veoStatusValue = 'completed';
        _veoOperationId = null;
        _veoGenerationStatus =
            'Preview générée. Vérifie le raccord final puis valide la vidéo.';
      });
    } on VeoSceneGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isGeneratingPreview = false;
        _isVeoPromptLocked = false;
        _veoStatusValue = 'failed';
        _veoGenerationStatus = null;
        _veoGenerationError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isGeneratingPreview = false;
        _isVeoPromptLocked = false;
        _veoStatusValue = 'failed';
        _veoGenerationStatus = null;
        _veoGenerationError =
            'Impossible de générer la preview pour le moment. Réessaie.';
      });
    }
  }

  void _correctVeoPrompt() {
    setState(() {
      _isVeoPromptLocked = false;
      _validatedPreviewVideo = null;
      _veoGenerationError = null;
      _veoStatusValue = _generatedPreviewVideo == null ? 'none' : _veoStatusValue;
      _veoGenerationStatus =
          'Prompt réactivé. Corrige le texte puis relance une génération.';
    });
  }

  Future<void> _validateGeneratedVideo() async {
    final preview = _generatedPreviewVideo;
    if (preview == null) {
      return;
    }

    final now = DateTime.now();
    setState(() {
      _validatedPreviewVideo = preview.copyWith(
        prompt: veoPromptCtrl.text.trim(),
        status: AiIntroVideoStatus.validated,
        updatedAt: now,
      );
      _isVeoPromptLocked = true;
      _veoGenerationError = null;
      _veoGenerationStatus =
          'Vidéo IA validée. Tu peux finaliser la prévisualisation détaillée.';
    });

    await _scrollToSection(_step16SectionKey);
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bibliothèque de scènes'),
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Brouillon'),
              Tab(text: 'En attente de publication'),
              Tab(text: 'Publiée'),
            ],
          ),
        ),
        body: StreamBuilder<List<SceneFormData>>(
          stream: SceneDraftRepository.watchAll(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? SceneDraftRepository.all();
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune scène enregistrée pour le moment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              );
            }

            return TabBarView(
              children: [
                _SceneLibraryList(
                  items: items,
                  status: SceneStatus.draft,
                ),
                _SceneLibraryList(
                  items: items,
                  status: SceneStatus.pendingPublication,
                ),
                _SceneLibraryList(
                  items: items,
                  status: SceneStatus.published,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SceneLibraryList extends StatelessWidget {
  const _SceneLibraryList({
    required this.items,
    required this.status,
  });

  final List<SceneFormData> items;
  final SceneStatus status;

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((item) => item.status == status).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Aucune scène dans ${status.label.toLowerCase()}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) => _SceneLibraryCard(scene: filtered[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemCount: filtered.length,
    );
  }
}

class _SceneLibraryCard extends StatelessWidget {
  const _SceneLibraryCard({required this.scene});

  final SceneFormData scene;

  Color get _statusBackground => switch (scene.status) {
        SceneStatus.draft => const Color(0xFFFFF4DA),
        SceneStatus.pendingPublication => const Color(0xFFDBEAFE),
        SceneStatus.published => const Color(0xFFDCFCE7),
      };

  Color get _statusForeground => switch (scene.status) {
        SceneStatus.draft => const Color(0xFF9A6B00),
        SceneStatus.pendingPublication => const Color(0xFF1D4ED8),
        SceneStatus.published => const Color(0xFF166534),
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 156,
                    height: 92,
                    child: scene.thumbnailUrl.isEmpty
                        ? Container(
                            color: const Color(0xFFE5E7EB),
                            child: const Icon(
                              Icons.movie_creation_outlined,
                              color: Color(0xFF6B7280),
                              size: 30,
                            ),
                          )
                        : Image.network(
                            scene.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scene.displayTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${scene.genre.isEmpty ? '-' : scene.genre} • ${scene.recommendedLevel.isEmpty ? '-' : scene.recommendedLevel}',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Durée IA : ${scene.aiDurationSeconds}s • Créée le ${_formatAdminDate(scene.createdAt)}',
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    scene.status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _statusForeground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SceneAdminDetailPage(scene: scene),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Voir détail'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddScenePage(
                          initialData: scene,
                          enableAdminTools: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
                if (scene.status != SceneStatus.published)
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await SceneDraftRepository.save(
                        scene.withPublicationStatus(SceneStatus.published),
                      );
                    },
                    icon: const Icon(Icons.publish_rounded),
                    label: const Text('Publier'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SceneAdminDetailPage extends StatelessWidget {
  const SceneAdminDetailPage({
    super.key,
    required this.scene,
  });

  final SceneFormData scene;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(scene.displayTitle),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SceneDetailPreview(scene: scene),
        ],
      ),
    );
  }
}

class _SceneDetailPreview extends StatelessWidget {
  const _SceneDetailPreview({required this.scene});

  final SceneFormData scene;

  String get _effectiveVeoPrompt {
    final prompt = scene.veoPrompt.trim();
    if (prompt.isNotEmpty) {
      return prompt;
    }
    return scene.aiIntroVideo?.prompt.trim() ?? '';
  }

  List<_PreviewTimelineMarker>? _parsePreviewTimelineMarkers() {
    final raw = scene.markersJson.trim();
    if (raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) {
        return null;
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => _PreviewTimelineMarker.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Widget _buildPreviewVeoPromptSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prompt VEO3',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _PreviewFieldCard(
              label: 'Prompt vidéo générative',
              value: _effectiveVeoPrompt.isEmpty
                  ? 'Aucun prompt VEO3 renseigné.'
                  : _effectiveVeoPrompt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTimelineSection() {
    final markers = _parsePreviewTimelineMarkers();
    if (markers == null || markers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timeline guidée',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 14),
              _PreviewFieldCard(
                label: 'Timeline',
                value: 'Timeline indisponible ou JSON invalide.',
              ),
            ],
          ),
        ),
      );
    }

    final totalSeconds = markers.fold<int>(
      0,
      (total, marker) => total + marker.durationSeconds,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline guidée — $totalSeconds secondes',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              '${markers.length} plan(s) séquencés',
              style: const TextStyle(
                height: 1.5,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Column(
              children: [
                for (var index = 0; index < markers.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPreviewTimelineCard(index + 1, markers[index]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTimelineCard(int index, _PreviewTimelineMarker marker) {
    final fields = <MapEntry<String, String>>[
      MapEntry('Type', marker.type),
      MapEntry('Durée', '${marker.durationSeconds} s'),
      MapEntry('Caméra', marker.cameraPlan),
      MapEntry('Personnage', marker.character),
      MapEntry('Dialogue', marker.dialogue),
      MapEntry('Indication', marker.cueText),
      MapEntry('Vidéo IA', marker.videoUrl),
    ].where((entry) => entry.value.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan $index — ${marker.label.isEmpty ? 'Sans titre' : marker.label}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: fields
                .map(
                  (entry) => SizedBox(
                    width: 250,
                    child: _PreviewFieldCard(
                      label: entry.key,
                      value: entry.value,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actorFields = <MapEntry<String, String>>[
      MapEntry('Nom du personnage', scene.characterName),
      MapEntry('Âge apparent', scene.apparentAge),
      MapEntry('Genre du personnage', scene.characterGender),
      MapEntry('Type de rôle', scene.profileRole),
      MapEntry('Émotion principale à jouer', scene.dominantEmotion),
      MapEntry('Intention du personnage', scene.mainObjective),
      MapEntry('Contexte dramatique', scene.contextSummary),
      MapEntry(
        'Objectif de la scène',
        scene.stakes.isEmpty ? scene.mainObstacle : scene.stakes,
      ),
      MapEntry('Ton de jeu attendu', scene.playStyles.join(' • ')),
      MapEntry('Niveau de difficulté', scene.recommendedLevel),
      MapEntry('Contraintes de jeu', scene.technicalConstraints),
      MapEntry(
        'Indications de mise en scène',
        [scene.actingDirection, scene.bodyDirection]
            .where((value) => value.trim().isNotEmpty)
            .join('\n'),
      ),
      MapEntry('Texte ou consigne de jeu', scene.dialogueText),
      MapEntry(
        'Durée attendue de la prestation acteur',
        scene.targetDuration,
      ),
      MapEntry('Type de cadrage recommandé', scene.framingType),
      MapEntry('Format vidéo demandé', scene.requestedVideoFormat),
      MapEntry('Accessoires éventuels', scene.usedObjects),
      MapEntry(
        'Décor conseillé',
        scene.location.isEmpty ? scene.whereAreWe : scene.location,
      ),
      MapEntry('Notes complémentaires de l’admin', scene.directorFinalNote),
    ].where((entry) => entry.value.trim().isNotEmpty).toList();

    final raccordFields = <MapEntry<String, String>>[
      MapEntry('Point de raccord visuel', scene.visualTransitionPoint),
      MapEntry('Point de raccord émotionnel', scene.emotionalTransitionPoint),
      MapEntry('Première action attendue de l’acteur', scene.firstActorAction),
      MapEntry('Première émotion attendue', scene.firstExpectedEmotion),
      MapEntry('Dernière image de la vidéo IA', scene.lastAiFrameDescription),
    ].where((entry) => entry.value.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.displayTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _PreviewPill(label: 'Catégorie', value: scene.category),
                    _PreviewPill(label: 'Genre', value: scene.genre),
                    _PreviewPill(label: 'Niveau', value: scene.recommendedLevel),
                    _PreviewPill(label: 'Audition', value: scene.targetDuration),
                    _PreviewPill(label: 'Statut', value: scene.status.label),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPreviewVeoPromptSection(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vidéo IA d’introduction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (scene.aiIntroVideo != null)
                  AdminVideoPreview(
                    videoUrl: scene.aiIntroVideo!.videoUrl,
                    thumbnailUrl: scene.aiIntroVideo!.thumbnailUrl,
                    caption:
                        'Vidéo IA d’introduction — destinée à créer l’ambiance de la scène.',
                  )
                else
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucune vidéo IA validée pour l’instant',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Vidéo IA d’introduction — destinée à créer l’ambiance de la scène.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ce que l’acteur doit jouer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: actorFields
                      .map(
                        (entry) => SizedBox(
                          width: 260,
                          child: _PreviewFieldCard(
                            label: entry.key,
                            value: entry.value,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Intention de raccord',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'La vidéo IA sert d’introduction émotionnelle. L’acteur doit poursuivre naturellement l’ambiance installée par cette vidéo, sans chercher à la reproduire exactement.',
                  style: TextStyle(height: 1.5, color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: raccordFields
                      .map(
                        (entry) => SizedBox(
                          width: 260,
                          child: _PreviewFieldCard(
                            label: entry.key,
                            value: entry.value,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPreviewTimelineSection(),
      ],
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label : ${value.isEmpty ? '-' : value}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PreviewFieldCard extends StatelessWidget {
  const _PreviewFieldCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewTimelineMarker {
  const _PreviewTimelineMarker({
    required this.type,
    required this.durationSeconds,
    required this.label,
    required this.cameraPlan,
    required this.character,
    required this.dialogue,
    required this.cueText,
    required this.videoUrl,
  });

  final String type;
  final int durationSeconds;
  final String label;
  final String cameraPlan;
  final String character;
  final String dialogue;
  final String cueText;
  final String videoUrl;

  factory _PreviewTimelineMarker.fromJson(Map<String, dynamic> json) {
    return _PreviewTimelineMarker(
      type: '${json['type'] ?? ''}',
      durationSeconds: _previewToInt(json['durationSeconds']),
      label: '${json['label'] ?? ''}',
      cameraPlan: '${json['cameraPlan'] ?? ''}',
      character: '${json['character'] ?? ''}',
      dialogue: '${json['dialogue'] ?? ''}',
      cueText: '${json['cueText'] ?? ''}',
      videoUrl: '${json['videoUrl'] ?? ''}',
    );
  }
}

int _previewToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

// ─────────────────────────────────────────────────────────────────────────
// _GuidedTimelineEditor
// Visual editor for Take60 guided scene markers. Each row exposes the
// type of plan (AI/user, role…), duration, dialogue, camera framing.
// Total duration is enforced ≤ 60s with a visible counter and alert.
// State is mirrored back into [controller.text] as a JSON list, so the
// existing persistence pipeline (toFirestore → markers field) keeps
// working unchanged.
// ─────────────────────────────────────────────────────────────────────────
class _GuidedTimelineEditor extends StatefulWidget {
  const _GuidedTimelineEditor({required this.controller});

  final TextEditingController controller;

  @override
  State<_GuidedTimelineEditor> createState() => _GuidedTimelineEditorState();
}

class _GuidedTimelineEditorState extends State<_GuidedTimelineEditor> {
  static const _markerTypes = <String, String>{
    'intro_cinema': 'Intro cinéma (IA)',
    'ai_dialogue': 'Réplique IA',
    'ai_reply': 'Réponse IA',
    'ai_reaction': 'Réaction IA',
    'reaction_shot': 'Plan réaction',
    'transition': 'Transition',
    'ai_outro': 'Conclusion IA',
    'final_shot': 'Plan final IA',
    'user_intro': 'Intro utilisateur',
    'user_dialogue': 'Réplique utilisateur',
    'user_reply': 'Réponse utilisateur',
    'user_emotion': 'Émotion utilisateur',
    'user_silent_action': 'Action silencieuse utilisateur',
    'close_up': 'Plan rapproché (utilisateur)',
    'medium_shot': 'Plan moyen (utilisateur)',
    'over_shoulder': 'Sur-épaule (utilisateur)',
  };

  static const _userTypes = {
    'user_intro',
    'user_dialogue',
    'user_reply',
    'user_emotion',
    'user_silent_action',
    'close_up',
    'medium_shot',
    'over_shoulder',
  };

  late List<Map<String, dynamic>> _markers;

  @override
  void initState() {
    super.initState();
    _markers = _decodeMarkersJson(widget.controller.text)
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    _resequence();
  }

  void _resequence() {
    for (var i = 0; i < _markers.length; i++) {
      _markers[i]['order'] = i;
      if ((_markers[i]['id'] as String?)?.trim().isEmpty ?? true) {
        _markers[i]['id'] = 'm_${DateTime.now().millisecondsSinceEpoch}_$i';
      }
    }
  }

  void _commit() {
    _resequence();
    widget.controller.text =
        const JsonEncoder.withIndent('  ').convert(_markers);
  }

  int get _totalDuration => _markers.fold<int>(
        0,
        (acc, m) => acc + ((m['durationSeconds'] as num?)?.toInt() ?? 0),
      );

  void _addMarker({String type = 'ai_dialogue'}) {
    setState(() {
      _markers.add({
        'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
        'type': type,
        'order': _markers.length,
        'durationSeconds': 8,
        'label': _markerTypes[type] ?? type,
        'dialogue': '',
        'cameraPlan': '',
        'character': '',
        'cueText': '',
      });
      _commit();
    });
  }

  void _remove(int index) {
    setState(() {
      _markers.removeAt(index);
      _commit();
    });
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _markers.length) return;
    setState(() {
      final tmp = _markers[index];
      _markers[index] = _markers[target];
      _markers[target] = tmp;
      _commit();
    });
  }

  void _update(int index, String key, dynamic value) {
    setState(() {
      _markers[index][key] = value;
      _commit();
    });
  }

  void _insertTemplate60s() {
    setState(() {
      _markers
        ..clear()
        ..addAll([
          {
            'id': 'ai_intro',
            'type': 'intro_cinema',
            'durationSeconds': 8,
            'label': 'Intro cinéma',
            'dialogue': '',
            'cameraPlan': 'Plan large',
            'character': '',
          },
          {
            'id': 'user_1',
            'type': 'user_dialogue',
            'durationSeconds': 10,
            'label': 'Plan utilisateur 1',
            'dialogue': 'Première réplique',
            'cameraPlan': 'Plan rapproché',
            'character': 'Personnage principal',
            'cueText': 'Joue avec calme.',
          },
          {
            'id': 'ai_react',
            'type': 'ai_reaction',
            'durationSeconds': 10,
            'label': 'Réaction IA',
            'dialogue': '',
            'cameraPlan': 'Champ contre-champ',
          },
          {
            'id': 'user_2',
            'type': 'user_dialogue',
            'durationSeconds': 12,
            'label': 'Plan utilisateur 2',
            'dialogue': 'Réplique tournante',
            'cameraPlan': 'Plan moyen',
            'character': 'Personnage principal',
            'cueText': 'Monte en intensité.',
          },
          {
            'id': 'user_3',
            'type': 'user_reply',
            'durationSeconds': 12,
            'label': 'Plan utilisateur final',
            'dialogue': 'Conclusion forte',
            'cameraPlan': 'Gros plan visage',
            'character': 'Personnage principal',
            'cueText': 'Finis en regardant l\'objectif.',
          },
          {
            'id': 'ai_outro',
            'type': 'ai_outro',
            'durationSeconds': 8,
            'label': 'Plan IA de clôture',
            'dialogue': '',
            'cameraPlan': 'Plan large',
          },
        ]);
      _commit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalDuration;
    final tooLong = total > 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_markers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'Aucun plan défini. Ajoute un premier plan ou insère un modèle 60 s.',
              style: TextStyle(color: Color(0xFF4B5563)),
            ),
          )
        else
          for (var i = 0; i < _markers.length; i++)
            _MarkerRow(
              key: ValueKey(_markers[i]['id'] ?? i),
              index: i,
              total: _markers.length,
              marker: _markers[i],
              types: _markerTypes,
              userTypes: _userTypes,
              onChange: (key, value) => _update(i, key, value),
              onMoveUp: i == 0 ? null : () => _move(i, -1),
              onMoveDown:
                  i == _markers.length - 1 ? null : () => _move(i, 1),
              onDelete: () => _remove(i),
            ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Durée totale: $total/60 s',
              style: TextStyle(
                color: tooLong
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF1F2937),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${_markers.length} plan(s)',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            if (tooLong)
              const Text(
                'Réduis les durées pour rentrer dans 60 s.',
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
            FilledButton.icon(
              onPressed: () => _addMarker(type: 'ai_dialogue'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter un plan IA'),
            ),
            FilledButton.icon(
              onPressed: () => _addMarker(type: 'user_dialogue'),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Ajouter un plan utilisateur'),
            ),
            OutlinedButton.icon(
              onPressed: _insertTemplate60s,
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Insérer un modèle 60 s'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({
    super.key,
    required this.index,
    required this.total,
    required this.marker,
    required this.types,
    required this.userTypes,
    required this.onChange,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final int index;
  final int total;
  final Map<String, dynamic> marker;
  final Map<String, String> types;
  final Set<String> userTypes;
  final void Function(String key, dynamic value) onChange;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = (marker['type'] as String?) ?? 'ai_dialogue';
    final isUser = userTypes.contains(type);
    final duration = (marker['durationSeconds'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFFFF7E6) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUser ? const Color(0xFFFCD34D) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isUser
                    ? const Color(0xFFFFB800)
                    : const Color(0xFF2563EB),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isUser ? 'Plan utilisateur' : 'Plan IA',
                style: TextStyle(
                  color: isUser
                      ? const Color(0xFF92400E)
                      : const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Monter',
                onPressed: onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              IconButton(
                tooltip: 'Descendre',
                onPressed: onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: types.containsKey(type) ? type : 'ai_dialogue',
                  decoration: const InputDecoration(
                    labelText: 'Type de plan',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final entry in types.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onChange('type', value);
                  },
                ),
              ),
              SizedBox(
                width: 130,
                child: TextFormField(
                  initialValue: duration.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durée (s)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value.trim()) ?? 0;
                    onChange('durationSeconds', parsed.clamp(0, 60));
                  },
                ),
              ),
              SizedBox(
                width: 240,
                child: TextFormField(
                  initialValue: (marker['label'] as String?) ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Libellé du plan',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => onChange('label', value),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextFormField(
                  initialValue: (marker['cameraPlan'] as String?) ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Plan caméra',
                    hintText: 'Plan rapproché, large…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => onChange('cameraPlan', value),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextFormField(
                  initialValue: (marker['character'] as String?) ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Personnage',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => onChange('character', value),
                ),
              ),
              SizedBox(
                width: 480,
                child: TextFormField(
                  initialValue: (marker['dialogue'] as String?) ?? '',
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Texte imposé / réplique',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => onChange('dialogue', value),
                ),
              ),
              if (isUser)
                SizedBox(
                  width: 480,
                  child: TextFormField(
                    initialValue: (marker['cueText'] as String?) ?? '',
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Consigne de jeu',
                      hintText: 'Ex: monte en intensité, regarde l\'objectif…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => onChange('cueText', value),
                  ),
                ),
              if (!isUser)
                SizedBox(
                  width: 480,
                  child: TextFormField(
                    initialValue: (marker['videoUrl'] as String?) ?? '',
                    decoration: const InputDecoration(
                      labelText: 'URL vidéo IA (VO3 / Veo)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => onChange('videoUrl', value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
