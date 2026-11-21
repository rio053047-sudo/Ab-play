import 'dart:async';
import 'package:flutter/foundation.dart';

abstract class AudioRtcService {
  ValueListenable<bool> get isMicrophoneMuted;
  ValueListenable<bool> get isAudioOutputMuted;
  ValueListenable<double> get localAudioLevel;
  Stream<Map<String, double>> get remoteAudioLevels;

  Future<void> joinChannel({
    required String roomId,
    required String userId,
    required bool isSpeaker,
  });

  Future<void> leaveChannel();
  Future<void> toggleMicrophone(bool mute);
  Future<void> toggleSpeaker(bool mute);
  void dispose();
}

import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Agora RTC implementation.
///
/// Supply AGORA_APP_ID and (for the initial Console-token test only)
/// AGORA_TEMP_TOKEN at build time. Never put an App Certificate or signing
/// secret in the Flutter app. Production room tokens must come from a trusted
/// backend and be generated for the actual channel and user.
class RealAudioRtcService implements AudioRtcService {
  RealAudioRtcService({
    String? appId,
    String? token,
  })  : _appId = appId ??
            const String.fromEnvironment('AGORA_APP_ID'),
        _token = token ??
            const String.fromEnvironment('AGORA_TEMP_TOKEN');

  final String _appId;
  final String _token;

  final ValueNotifier<bool> _isMicrophoneMuted = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isAudioOutputMuted = ValueNotifier<bool>(false);
  final ValueNotifier<double> _localAudioLevel = ValueNotifier<double>(0);
  final StreamController<Map<String, double>> _remoteAudioLevelsController =
      StreamController<Map<String, double>>.broadcast();

  RtcEngine? _engine;
  bool _joined = false;
  bool _disposed = false;

  @override
  ValueListenable<bool> get isMicrophoneMuted => _isMicrophoneMuted;

  @override
  ValueListenable<bool> get isAudioOutputMuted => _isAudioOutputMuted;

  @override
  ValueListenable<double> get localAudioLevel => _localAudioLevel;

  @override
  Stream<Map<String, double>> get remoteAudioLevels =>
      _remoteAudioLevelsController.stream;

  Future<void> _ensureEngine() async {
    if (_engine != null) return;
    if (_appId.isEmpty) {
      throw StateError(
        'Agora App ID is missing. Build with --dart-define=AGORA_APP_ID=YOUR_APP_ID.',
      );
    }
    if (_token.isEmpty) {
      throw StateError(
        'Agora token is missing. For the initial test, provide a temporary '
        'token for this exact channel. Production tokens must come from a '
        'trusted backend.',
      );
    }

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    await engine.enableAudio();
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onError: (ErrorCodeType error, String message) {
          debugPrint('Agora RTC error: $error - $message');
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('Agora joined channel: ${connection.channelId}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Agora remote user joined: $remoteUid');
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          debugPrint('Agora remote user left: $remoteUid ($reason)');
        },
      ),
    );
    _engine = engine;
  }

  @override
  Future<void> joinChannel({
    required String roomId,
    required String userId,
    required bool isSpeaker,
  }) async {
    if (_joined) {
      await leaveChannel();
    }

    final permission = await Permission.microphone.request();
    if (isSpeaker && !permission.isGranted) {
      throw StateError('Microphone permission is required to speak.');
    }

    await _ensureEngine();
    final channelName = roomId.trim();
    if (channelName.isEmpty || channelName.length > 64) {
      throw ArgumentError.value(roomId, 'roomId', 'Invalid Agora channel name.');
    }

    await _engine!.joinChannel(
      token: _token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        publishCameraTrack: false,
      ),
    );
    _joined = true;
    _isMicrophoneMuted.value = !isSpeaker;
    await _engine!.muteLocalAudioStream(!isSpeaker);
    _localAudioLevel.value = 0;
  }

  @override
  Future<void> leaveChannel() async {
    if (_engine != null && _joined) {
      await _engine!.leaveChannel();
    }
    _joined = false;
    _isMicrophoneMuted.value = true;
    _localAudioLevel.value = 0;
  }

  @override
  Future<void> toggleMicrophone(bool mute) async {
    if (!_joined || _engine == null) {
      throw StateError('Join a Voice Room before changing the microphone.');
    }
    if (!mute) {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        throw StateError('Microphone permission was denied.');
      }
    }
    await _engine!.muteLocalAudioStream(mute);
    _isMicrophoneMuted.value = mute;
    if (mute) _localAudioLevel.value = 0;
  }

  @override
  Future<void> toggleSpeaker(bool mute) async {
    if (!_joined || _engine == null) {
      throw StateError('Join a Voice Room before changing speaker audio.');
    }
    await _engine!.muteAllRemoteAudioStreams(mute);
    _isAudioOutputMuted.value = mute;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      unawaited(engine.leaveChannel());
      unawaited(engine.release());
    }
    _isMicrophoneMuted.dispose();
    _isAudioOutputMuted.dispose();
    _localAudioLevel.dispose();
    unawaited(_remoteAudioLevelsController.close());
  }
}
