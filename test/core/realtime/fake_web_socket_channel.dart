import 'dart:async';

import 'package:stream_channel/stream_channel.dart';

/// Controllable WebSocket-style channel for unit tests.
class FakeWebSocketChannel extends StreamChannelMixin<dynamic> {
  FakeWebSocketChannel()
    : _incoming = StreamController<dynamic>.broadcast(),
      _outgoing = StreamController<dynamic>() {
    _outgoing.stream.listen(outgoingMessages.add);
  }

  final StreamController<dynamic> _incoming;
  final StreamController<dynamic> _outgoing;

  final List<dynamic> outgoingMessages = [];

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  StreamSink<dynamic> get sink => _outgoing.sink;

  /// Emulates a server message to the client.
  void addMessage(dynamic message) {
    _incoming.add(message);
  }

  /// Closes the incoming stream like a server disconnect.
  Future<void> closeIncoming() async {
    await _incoming.close();
  }
}
