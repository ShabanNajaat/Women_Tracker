import 'dart:io';

Future<List<int>> readBytesFromPath(String path) => File(path).readAsBytes();

Future<void> deleteFileAtPath(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
