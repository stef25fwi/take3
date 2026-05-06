import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> downloadTemplateBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final extension = fileName.split('.').last.toLowerCase();
  await FilePicker.platform.saveFile(
    dialogTitle: 'Télécharger le formulaire Take60',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: <String>[extension],
    bytes: bytes,
  );
}
