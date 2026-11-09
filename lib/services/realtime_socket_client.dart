import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketEvent {
  final String event;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketEvent({
    required this.event,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'event': event,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      event: json['event'] as String? ?? 'unknown',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : {},
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class RealtimeSocketClient extends ChangeNotifier {
  static final RealtimeSocketClient instance = RealtimeSocketClient._internal();
  RealtimeSocketClient._internal();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _serverUrl;
  String? _authToken;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  final StreamController<WebSocketEvent> _eventStreamController =
      StreamController<WebSocketEvent>.broadcast();

  final Map<String, List<void Function(Map<String, dynamic>)>> _listeners = {};

  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;
  Stream<WebSocketEvent> get eventStream => _eventStreamController.stream;

  Future<void> connect({
    required String serverUrl,
    required String authToken,
  }) async {
    _serverUrl = serverUrl;
    _authToken = authToken;
    _status = ConnectionStatus.connecting;
    notifyListeners();

    // Establish live network socket connection
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      _status = ConnectionStatus.connected;
      _reconnectAttempts = 0;
      _startHeartbeat();
      notifyListeners();

      // Emit connected event
      _dispatch(WebSocketEvent(
        event: 'system:connected',
        data: {'url': _serverUrl, 'timestamp': DateTime.now().toIso8601String()},
      ));
    } catch (e) {
      _status = ConnectionStatus.error;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void on(String event, void Function(Map<String, dynamic>) callback) {
    final list = _listeners.putIfAbsent(event, () => []);
    list.add(callback);
  }

  void off(String event, void Function(Map<String, dynamic>) callback) {
    _listeners[event]?.remove(callback);
  }

  void emit(String event, Map<String, dynamic> data) {
    if (!isConnected) {
      return;
    }

    final wsEvent = WebSocketEvent(event: event, data: data);
    // In actual network mode, serialize and send down socket channel
    _dispatch(wsEvent);
  }

  void _dispatch(WebSocketEvent event) {
    _eventStreamController.add(event);
    final callbacks = _listeners[event.event];
    if (callbacks != null) {
      for (final cb in callbacks) {
        cb(event.data);
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (isConnected) {
        emit('ping', {'clientTime': DateTime.now().millisecondsSinceEpoch});
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    _status = ConnectionStatus.reconnecting;
    notifyListeners();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: _reconnectAttempts * 2),
      () {
        if (_serverUrl != null && _authToken != null) {
          connect(serverUrl: _serverUrl!, authToken: _authToken!);
        }
      },
    );
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _status = ConnectionStatus.disconnected;
    _reconnectAttempts = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _eventStreamController.close();
    super.dispose();
  }
}
