import 'dart:async';
import 'package:flutter/services.dart';

class SudMGPPlugin {
  static var shared = SudMGPPlugin();
  static const MethodChannel _methodChannel = MethodChannel('SudMGPPlugin');
  static const EventChannel _eventChannel = EventChannel('SudMGPPluginEvent');
  static StreamSubscription<dynamic>? streamSubscription;

  static void Function(Map map)? onEvent;
  static void registerEventHandler(Function(Map map) eventHandle) async {
    onEvent = eventHandle;
    streamSubscription =
        _eventChannel.receiveBroadcastStream().listen(eventListener);
  }

  static void eventListener(dynamic data) {
    var map = Map.from(data);
    onEvent!(map);
  }

  static Future<Map> getVersion() async {
    return await _methodChannel.invokeMethod("getVersion", {});
  }

  static Future<Map> initSDK(
      String appid, String appkey, bool isTestEnv) async {
    return await _methodChannel.invokeMethod(
        "initSDK", {"appid": appid, "appkey": appkey, "isTestEnv": isTestEnv});
  }

  static Future<Map> getGameList() async {
    return await _methodChannel.invokeMethod("getGameList", {});
  }

  static Future<Map> loadGame(String userid, String roomid, String code,
      int gameid, String language, String viewSize, String gameConfig) async {
    return await _methodChannel.invokeMethod("loadGame", {
      "userid": userid,
      "roomid": roomid,
      "code": code,
      "gameid": gameid,
      "language": language,
      "viewSize": viewSize,
      "gameConfig": gameConfig,
    });
  }

  static Future<Map> updateCode(String code) async {
    return await _methodChannel.invokeMethod("updateCode", {"code":code});
  }

  static Future<Map> destroyGame() async {
    return await _methodChannel.invokeMethod("destroyGame", {});
  }



}
