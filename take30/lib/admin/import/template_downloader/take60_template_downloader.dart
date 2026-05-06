import 'dart:typed_data';

import 'take60_template_downloader_stub.dart'
    if (dart.library.html) 'take60_template_downloader_web.dart'
    if (dart.library.io) 'take60_template_downloader_io.dart' as platform;

class Take60TemplateDownloader {
  const Take60TemplateDownloader();

  Future<void> downloadBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    return platform.downloadTemplateBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}
