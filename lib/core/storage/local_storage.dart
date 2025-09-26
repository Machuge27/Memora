import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LocalStorage {
  static const _uuid = Uuid();
  
  static Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/memora');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir.path;
  }
  
  static Future<String> saveImage(Uint8List imageBytes) async {
    final appDir = await getAppDirectory();
    final fileName = '${_uuid.v4()}.jpg';
    final file = File('$appDir/$fileName');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }
  
  static Future<bool> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}