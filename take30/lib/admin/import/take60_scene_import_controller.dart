import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'take60_scene_import_model.dart';
import 'take60_scene_import_parser.dart';
import 'take60_scene_import_template_builder.dart';
import 'take60_scene_import_validator.dart';

typedef Take60SceneImportInjector = Future<void> Function(
  Take60SceneImportDraft draft,
  ImportValidationResult validation,
);

class Take60SceneImportController extends ChangeNotifier {
  Take60SceneImportController({
    Take60SceneImportParser parser = const Take60SceneImportParser(),
    Take60SceneImportValidator validator = const Take60SceneImportValidator(),
    Take60SceneImportTemplateBuilder templateBuilder = const Take60SceneImportTemplateBuilder(),
    Take60SceneImportInjector? injector,
    String Function()? importedByProvider,
  })  : _parser = parser,
        _validator = validator,
        _templateBuilder = templateBuilder,
        _injector = injector,
        _importedByProvider = importedByProvider;

  final Take60SceneImportParser _parser;
  final Take60SceneImportValidator _validator;
  final Take60SceneImportTemplateBuilder _templateBuilder;
  final Take60SceneImportInjector? _injector;
  final String Function()? _importedByProvider;

  String? selectedFileName;
  bool isPickingFile = false;
  bool isParsing = false;
  bool isValidating = false;
  bool isInjecting = false;
  bool draftCreated = false;
  Take60SceneImportDraft? importedDraft;
  ImportValidationResult? validationResult;
  String? statusMessage;
  String? technicalError;

  bool get canPreview => importedDraft != null && validationResult != null;
  bool get canInject => canPreview && (validationResult?.isValid ?? false) && !isInjecting;
  bool get hasWarnings => validationResult?.warnings.isNotEmpty == true;
  bool get hasBlockingErrors => validationResult?.blockingErrors.isNotEmpty == true;

  Future<void> pickAndImportScenario() async {
    _setBusy(picking: true, parsing: false, validating: false);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'csv', 'xlsx'],
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        statusMessage = 'Aucun fichier sélectionné.';
        return;
      }
      final file = result.files.single;
      selectedFileName = file.name;
      final bytes = file.bytes;
      if (bytes == null) {
        _fail('Le fichier n’a pas pu être lu depuis l’appareil.');
        return;
      }
      _debug('Fichier sélectionné: ${file.name} (${bytes.lengthInBytes} octets)');
      await importBytes(bytes: bytes, fileName: file.name);
    } catch (error, stackTrace) {
      _debug('Erreur import fichier: $error\n$stackTrace');
      _fail(_friendlyError(error));
    } finally {
      _setBusy(picking: false, parsing: false, validating: false);
    }
  }

  Future<void> importBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final watch = Stopwatch()..start();
    selectedFileName = fileName;
    draftCreated = false;
    technicalError = null;
    importedDraft = null;
    validationResult = null;
    notifyListeners();

    try {
      _setBusy(picking: false, parsing: true, validating: false);
      final detectedFormat = _extensionOf(fileName).isEmpty ? 'json' : _extensionOf(fileName);
      _debug('Format détecté: $detectedFormat');
      final draft = _parser.parseBytes(
        bytes: bytes,
        fileName: fileName,
        importedBy: _importedByProvider?.call() ?? '',
      );
      _debug('Parsing terminé: ${draft.sceneGeneral.title}');

      _setBusy(picking: false, parsing: false, validating: true);
      final validation = _validator.validate(draft);
      importedDraft = draft;
      validationResult = validation;
      statusMessage = validation.isValid
          ? 'Import prêt à être injecté.'
          : 'Fichier importé avec erreurs à corriger.';
      _debug(
        'Validation import: valid=${validation.isValid}, erreurs=${validation.blockingErrors.length}, warnings=${validation.warnings.length}',
      );
    } catch (error, stackTrace) {
      _debug('Erreur parsing/validation: $error\n$stackTrace');
      _fail(_friendlyError(error));
    } finally {
      watch.stop();
      _debug('Temps parsing import: ${watch.elapsedMilliseconds} ms');
      _setBusy(picking: false, parsing: false, validating: false);
    }
  }

  Future<void> downloadTemplate({String format = 'json'}) async {
    try {
      final normalized = format.toLowerCase() == 'csv' ? 'csv' : 'json';
      final fileName = normalized == 'csv'
          ? 'modele_take60_scenario.csv'
          : 'modele_take60_scenario.json';
      final bytes = normalized == 'csv'
          ? _templateBuilder.buildCsvTemplateBytes()
          : _templateBuilder.buildOfficialJsonTemplateBytes();
      await FilePicker.platform.saveFile(
        dialogTitle: 'Télécharger le modèle Take60',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [normalized],
      );
      statusMessage = normalized == 'csv'
          ? 'Modèle CSV téléchargé.'
          : 'Modèle JSON officiel téléchargé.';
      notifyListeners();
    } catch (error, stackTrace) {
      _debug('Erreur téléchargement modèle: $error\n$stackTrace');
      _fail('Impossible de télécharger le modèle. Réessaie depuis le navigateur admin.');
    }
  }

  Future<void> injectIntoCurrentSceneForm() async {
    final draft = importedDraft;
    final validation = validationResult;
    if (draft == null || validation == null) {
      _fail('Aucun import prêt à injecter.');
      return;
    }
    if (!validation.isValid) {
      _fail('Corrigez les erreurs bloquantes avant de créer le brouillon.');
      return;
    }
    final injector = _injector;
    if (injector == null) {
      _fail('L’injection dans le formulaire n’est pas disponible sur cet écran.');
      return;
    }
    isInjecting = true;
    statusMessage = 'Injection dans le formulaire…';
    notifyListeners();
    try {
      await injector(draft, validation);
      draftCreated = true;
      statusMessage = 'Brouillon créé dans le formulaire. Vérifiez puis enregistrez.';
      _debug('Injection réussie.');
    } catch (error, stackTrace) {
      _debug('Erreur injection: $error\n$stackTrace');
      _fail(_friendlyError(error));
    } finally {
      isInjecting = false;
      notifyListeners();
    }
  }

  void resetImport() {
    selectedFileName = null;
    importedDraft = null;
    validationResult = null;
    statusMessage = null;
    technicalError = null;
    draftCreated = false;
    isPickingFile = false;
    isParsing = false;
    isValidating = false;
    isInjecting = false;
    notifyListeners();
  }

  void _setBusy({
    required bool picking,
    required bool parsing,
    required bool validating,
  }) {
    isPickingFile = picking;
    isParsing = parsing;
    isValidating = validating;
    notifyListeners();
  }

  void _fail(String message) {
    technicalError = message;
    statusMessage = message;
    importedDraft = importedDraft;
    validationResult = validationResult;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is Take60SceneImportException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'Fichier invalide : le contenu JSON/CSV n’est pas lisible.';
    }
    return 'Erreur technique pendant l’import du scénario.';
  }

  String _extensionOf(String fileName) {
    final index = fileName.lastIndexOf('.');
    return index < 0 ? '' : fileName.substring(index + 1).toLowerCase();
  }

  void _debug(String message) {
    if (kDebugMode) {
      debugPrint('[Take60Import] $message');
    }
  }
}
