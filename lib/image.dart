import 'dart:io';
import 'dart:typed_data';
import 'package:moonie/core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final String imagesDirName = p.join(MoonieCore.moonieCoreFolder, 'images');

Future<File> copyImageToImagesDir(String path) async {
  final directory = await getApplicationDocumentsDirectory();
  final imagesDir = Directory(p.join(directory.path, imagesDirName));

  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  final fileName = p.basename(path);
  var newFileName = getUniqueSuffix(imagesDir, fileName);
  final newFilePath = p.join(imagesDir.path, newFileName);

  await File(path).copy(newFilePath);
  return File(newFilePath);
}

Future<File> writeImageToImagesDir(
    String originalFilePath, Uint8List bytes, String? overrideExtension) async {
  final directory = await getApplicationDocumentsDirectory();
  final imagesDir = Directory(p.join(directory.path, imagesDirName));

  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  final fileName = p.basename(originalFilePath);
  var newFileName = getUniqueSuffix(imagesDir, fileName);
  if (overrideExtension != null) {
    newFileName =
        '${p.basenameWithoutExtension(newFileName)}.$overrideExtension';
  }
  final newFilePath = p.join(imagesDir.path, newFileName);

  await File(newFilePath).writeAsBytes(bytes);
  return File(newFilePath);
}

String getUniqueSuffix(Directory imagesDir, String fileName) {
  int i = 1;
  String newFileName = fileName;
  while (File(p.join(imagesDir.path, newFileName)).existsSync()) {
    final nameWithoutExtension = p.basenameWithoutExtension(fileName);
    final extension = p.extension(fileName);
    newFileName = '$nameWithoutExtension-$i$extension';
    i++;
  }
  return newFileName;
}
