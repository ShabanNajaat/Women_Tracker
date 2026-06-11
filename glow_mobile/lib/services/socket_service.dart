import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class SocketService extends ChangeNotifier {
  SocketService._privateConstructor();
  static final SocketService instance = SocketService._privateConstructor();

  IO.Socket? _socket;
  final ApiService _api = ApiService();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    await _api.init();
    if (!_api.isAuthenticated) return;

    final token = await _api.getToken();
    if (token == null) return;

    // Use the ApiService base URL but replace http/https with ws/wss if needed, 
    // or just pass the HTTP URL and socket.io client handles it.
    final baseUrl = const String.fromEnvironment('API_BASE_URL',
        defaultValue: 'http://localhost:8081/api');
    
    // We want the domain without the /api suffix for the socket server
    final socketUrl = baseUrl.replaceAll(RegExp(r'/api$'), '');

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.onConnect((_) {
      _isConnected = true;
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
    });

    // We can add message listeners here or in specific screens
    // using SocketService.instance.socket.on('receive_message', ...)

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  IO.Socket? get socket => _socket;
}
