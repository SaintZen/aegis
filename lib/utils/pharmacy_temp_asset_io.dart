import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> copyBundledAssetToTemp(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final dir = await getTemporaryDirectory();
  final base = assetPath.split('/').last;
  final file = File('${dir.path}/pharm_$base');
  await file.writeAsBytes(data.buffer.asUint8List());
  return file.path;
}
