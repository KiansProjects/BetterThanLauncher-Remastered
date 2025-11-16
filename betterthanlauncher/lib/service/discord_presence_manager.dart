import 'dart:io';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';

class DiscordPresenceManager {
  final String clientId;
  bool _initialized = false;
  late final int _startTime;

  final String prefix = '[DiscordPresenceManager]';

  DiscordPresenceManager({required this.clientId});

  Future<void> init() async {
    print('$prefix Initializing DiscordPresenceManager...');

    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;

    try {
      await FlutterDiscordRPC.initialize(clientId);
      FlutterDiscordRPC.instance.connect();
      _initialized = true;

      _startTime = DateTime.now().millisecondsSinceEpoch;

      await setPresence(details: 'Starting launcher...');
    } catch (e) {
      print('$prefix Failed to initialize: $e');
    }
  }

  Future<void> setPresence({
    String? details,
    String? state,
    String? largeImageKey = 'app_icon',
    String? smallImageKey,
  }) async {
    if (!_initialized) return;

    try {
      FlutterDiscordRPC.instance.setActivity(
        activity: RPCActivity(
          details: details,
          state: state,
          assets: RPCAssets(
            largeText: 'BetterThanLauncher',
            largeImage: largeImageKey,
            smallImage: smallImageKey,
          ),
          timestamps: RPCTimestamps(
            start: _startTime,
          ),
        ),
      );
    } catch (e) {
      print('$prefix Failed to update presence: $e');
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    try {
      FlutterDiscordRPC.instance.disconnect();
      FlutterDiscordRPC.instance.dispose();
    } catch (e) {
      print('$prefix Failed to dispose RPC: $e');
    }
  }
}
