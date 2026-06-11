import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<List<int>> readBytesFromPath(String path) async {
  final response = await http.get(Uri.parse(path));
  return response.bodyBytes;
}

Future<void> deleteFileAtPath(String path) async {}
