import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class AudioRtcService {
  ValueListenable<bool> get isMicrophoneMuted;
  ValueListenable<bool> get isAudioOutputMuted;
  ValueListenable<double> get localAudioLevel;
  ValueListenable<String> get connectionStatus;
  Stream<Map<String, double>> get remoteAudioLevels;
  Stream<void> get reconnected;

  Future<void> joinChannel({
    required String roomId,
    required String userId,
    required bool isSpeaker,
    required String appId,
    required String token,
    required int rtcUid,
    required Future<String> Function() refreshToken,
  });
  Future<void> updatePublisherRole(
      {required bool canPublish, required String token});

  Future<void> leaveChannel();
  Future<void> toggleMicrophone(bool mute);
  Future<void> toggleSpeaker(bool mute);
  void dispose();
}

/// Agora RTC implementation.
///
/// Supply AGORA_APP_ID and (for the initial Console-token test only)
/// AGORA_TEMP_TOKEN at build time. Never put an App Certificate or signing
/// secret in the Flutter app. Production room tokens must come from a trusted
/// backend and be generated for the actual channel and user.
class RealAudioRtcService implements AudioRtcService {
  RealAudioRtcService();

  String _token = '';
  Future<String> Function()? _refreshToken;

  final ValueNotifier<bool> _isMicrophoneMuted = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isAudioOutputMuted = ValueNotifier<bool>(false);
  final ValueNotifier<double> _localAudioLevel = ValueNotifier<double>(0);
  final ValueNotifier<String> _connectionStatus =
      ValueNotifier<String>('disconnected');
  final StreamController<Map<String, double>> _remoteAudioLevelsController =
      StreamController<Map<String, double>>.broadcast();
  final StreamController<void> _reconnectedController =
      StreamController<void>.broadcast();

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
  ValueListenable<String> get connectionStatus => _connectionStatus;

  @override
  Stream<Map<String, double>> get remoteAudioLevels =>
      _remoteAudioLevelsController.stream;
  @override
  Stream<void> get reconnected => _reconnectedController.stream;

  Future<void> _ensureEngine(String appId) async {
    if (_engine != null) return;
    if (!RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(appId)) {
      throw StateError(
          'The RTC service returned an invalid App ID. Check Agora server configuration.');
    }

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
    await engine.enableAudio();
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onError: (ErrorCodeType error, String message) {
          debugPrint('Agora RTC error: $error - $message');
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _connectionStatus.value = 'connected';
          debugPrint('Agora joined channel: ${connection.channelId}');
        },
        onConnectionStateChanged: (RtcConnection connection,
            ConnectionStateType state, ConnectionChangedReasonType reason) {
          _connectionStatus.value = switch (state) {
            ConnectionStateType.connectionStateConnected => 'connected',
            ConnectionStateType.connectionStateReconnecting => 'reconnecting',
            ConnectionStateType.connectionStateConnecting => 'connecting',
            _ => 'disconnected',
          };
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Agora remote user joined: $remoteUid');
        },
        onRejoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _reconnectedController.add(null);
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          debugPrint('Agora remote user left: $remoteUid ($reason)');
        },
        onTokenPrivilegeWillExpire:
            (RtcConnection connection, String token) async {
          final refresh = _refreshToken;
          if (refresh == null) return;
          try {
            _token = await refresh();
            await engine.renewToken(_token);
          } catch (error) {
            debugPrint('Could not refresh Agora token: $error');
          }
        },
        onRequestToken: (RtcConnection connection) async {
          final refresh = _refreshToken;
          if (refresh == null) return;
          try {
            _token = await refresh();
            await engine.renewToken(_token);
          } catch (error) {
            debugPrint('Agora requested a token but refresh failed: $error');
          }
        },
        onAudioVolumeIndication: (RtcConnection connection,
            List<AudioVolumeInfo> speakers, int totalVolume, int vad) {
          final levels = <String, double>{};
          for (final speaker in speakers) {
            if (speaker.uid == connection.localUid) {
              _localAudioLevel.value = (speaker.volume ?? 0) / 255.0;
            } else {
              levels['${speaker.uid}'] = (speaker.volume ?? 0) / 255.0;
            }
          }
          _remoteAudioLevelsController.add(levels);
        },
      ),
    );
    await engine.enableAudioVolumeIndication(
        interval: 200, smooth: 3, reportVad: true);
    _engine = engine;
  }

  @override
  Future<void> joinChannel({
    required String roomId,
    required String userId,
    required bool isSpeaker,
    required String appId,
    required String token,
    required int rtcUid,
    required Future<String> Function() refreshToken,
  }) async {
    if (_joined) {
      await leaveChannel();
    }

    if (isSpeaker) {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        throw StateError('Microphone permission is required to speak.');
      }
    }

    _token = token;
    _refreshToken = refreshToken;
    _connectionStatus.value = 'connecting';
    await _ensureEngine(appId);
    final channelName = roomId.trim();
    if (channelName.isEmpty || channelName.length > 64) {
      throw ArgumentError.value(
          roomId, 'roomId', 'Invalid Agora channel name.');
    }

    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: rtcUid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleAudience,
        autoSubscribeAudio: true,
        publishMicrophoneTrack: isSpeaker,
        publishCameraTrack: false,
      ),
    );
    await _engine!.setClientRole(
        role: isSpeaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience);
    await _engine!.updateChannelMediaOptions(
        ChannelMediaOptions(publishMicrophoneTrack: isSpeaker));
    _joined = true;
    _isMicrophoneMuted.value = true;
    await _engine!.muteLocalAudioStream(true);
    _localAudioLevel.value = 0;
  }

  @override
  Future<void> updatePublisherRole(
      {required bool canPublish, required String token}) async {
    if (!_joined || _engine == null) throw StateError('RTC is not connected.');
    if (canPublish) {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        throw StateError('Microphone permission is required to speak.');
      }
    }
    _token = token;
    await _engine!.renewToken(token);
    await _engine!.setClientRole(
        role: canPublish
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience);
    await _engine!.updateChannelMediaOptions(
        ChannelMediaOptions(publishMicrophoneTrack: canPublish));
    await _engine!.muteLocalAudioStream(!canPublish);
  }

  @override
  Future<void> leaveChannel() async {
    if (_engine != null && _joined) {
      await _engine!.leaveChannel();
    }
    _joined = false;
    _connectionStatus.value = 'disconnected';
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
    await _engine!.setEnableSpeakerphone(!mute);
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
    _connectionStatus.dispose();
    unawaited(_remoteAudioLevelsController.close());
    unawaited(_reconnectedController.close());
  }
}
