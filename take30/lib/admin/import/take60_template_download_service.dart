import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'template_downloader/take60_template_downloader.dart';

class Take60TemplateDownloadService {
  const Take60TemplateDownloadService({
    Take60TemplateDownloader downloader = const Take60TemplateDownloader(),
  }) : _downloader = downloader;

  static const String excelTemplateAsset =
      'assets/admin/scene_import/templates/modele_formulaire_scenario_take60.xlsx';
  static const String jsonTemplateAsset =
      'assets/admin/scene_import/templates/modele_scenario_take60.json';

  static const String _legacyExcelTemplateAsset =
      'lib/admin/scene_import/templates/modele_formulaire_scenario_take60.xlsx';

  static const String _excelFileName = 'modele_formulaire_scenario_take60.xlsx';
  static const String _jsonFileName = 'modele_scenario_take60.json';
  static const String _excelMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const String _jsonMimeType = 'application/json';

  final Take60TemplateDownloader _downloader;

  Future<void> downloadExcelTemplate(BuildContext context) async {
    await _downloadTemplate(
      context: context,
      assetPath: excelTemplateAsset,
      fallbackAssetPaths: const <String>[_legacyExcelTemplateAsset],
      fileName: _excelFileName,
      mimeType: _excelMimeType,
      successMessage: 'Formulaire Excel téléchargé.',
      validateBytes: _looksLikeXlsx,
    );
  }

  Future<void> downloadJsonTemplate(BuildContext context) async {
    await _downloadTemplate(
      context: context,
      assetPath: jsonTemplateAsset,
      fileName: _jsonFileName,
      mimeType: _jsonMimeType,
      successMessage: 'Modèle JSON téléchargé.',
    );
  }

  Future<void> _downloadTemplate({
    required BuildContext context,
    required String assetPath,
    required String fileName,
    required String mimeType,
    required String successMessage,
    List<String> fallbackAssetPaths = const <String>[],
    bool Function(Uint8List bytes)? validateBytes,
  }) async {
    try {
      final bytes = await _loadFirstValidAssetBytes(
        assetPath,
        fallbackAssetPaths: fallbackAssetPaths,
        validateBytes: validateBytes,
      );
      await _downloader.downloadBytes(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      if (context.mounted) {
        _showMessage(context, successMessage, backgroundColor: const Color(0xFF0F766E));
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(
          context,
          'Impossible de télécharger le formulaire. Vérifie que le fichier est bien présent dans assets/admin/scene_import/templates/ et déclaré dans pubspec.yaml.',
          backgroundColor: const Color(0xFFB91C1C),
        );
      }
    }
  }

  Future<Uint8List> _loadFirstValidAssetBytes(
    String assetPath, {
    required List<String> fallbackAssetPaths,
    bool Function(Uint8List bytes)? validateBytes,
  }) async {
    Object? lastError;
    for (final candidate in <String>[assetPath, ...fallbackAssetPaths]) {
      try {
        final bytes = await _loadAssetBytes(candidate);
        if (validateBytes == null || validateBytes(bytes)) {
          return bytes;
        }
        lastError = StateError('Asset $candidate invalide.');
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('Aucun asset modèle disponible.');
  }

  Future<Uint8List> _loadAssetBytes(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static bool _looksLikeXlsx(Uint8List bytes) {
    return bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
  }

  void _showMessage(
    BuildContext context,
    String message, {
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
  }
}
