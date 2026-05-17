import 'path_file_bytes_stub.dart'
    if (dart.library.io) 'path_file_bytes_io.dart' as path_bytes;

Future<List<int>> readBytesFromPath(String path) => path_bytes.readBytesFromPath(path);

Future<void> deleteFileAtPath(String path) => path_bytes.deleteFileAtPath(path);
