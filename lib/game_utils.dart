import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const String MG_NAME_LOGIN_AUTH_URL = 'Your Host';
const String MG_APPID = '1648629929548042241';
const String MG_APPKEY = '43IVUAi2qUHAxOyaMtHglKjsQCqExbnO';
const bool MG_APP_IS_TEST_ENV = true;

class GameInfo {
  int mg_id;
  String name;
  String desc = '';
  String thumbnail80x80 = '';
  late String thumbnail332x332;
  late String thumbnail192x192;
  late String thumbnail128x128;
  late String bigLoadingPic;
  late int minCount;
  late int maxCount;

  GameInfo(this.mg_id, this.name);

  GameInfo.fromJson(Map<String, dynamic> json)
      : desc = json['desc']['default'],
        minCount = json['game_mode_list'][0]['count'][0],
        maxCount = json['game_mode_list'][0]['count'][1],
        thumbnail332x332 = json['thumbnail332x332']['default'],
        thumbnail192x192 = json['thumbnail192x192']['default'],
        thumbnail128x128 = json['thumbnail128x128']['default'],
        thumbnail80x80 = json['thumbnail80x80']['default'],
        bigLoadingPic = json['big_loading_pic']['default'],
        name = json['name']['default'],
        mg_id = json['mg_id'];
}

List<GameInfo> parseGameList(dynamic data) {
  List<Map<String, dynamic>> gameList = List.from(data);
  List<GameInfo> ret = [];
  for (var item in gameList) {
    ret.add(GameInfo.fromJson(item));
  }
  // gameid : game name
  return ret;
}

Widget? getPlatformView(String viewType, Function(int viewID) onViewCreated) {
  if (TargetPlatform.iOS == defaultTargetPlatform) {
    return UiKitView(
        key: UniqueKey(),
        viewType: viewType,
        onPlatformViewCreated: (int viewID) {
          onViewCreated(viewID);
        });
  } else if (TargetPlatform.android == defaultTargetPlatform) {
    return AndroidView(
        key: UniqueKey(),
        viewType: viewType,
        onPlatformViewCreated: (int viewID) {
          onViewCreated(viewID);
        });
  }
  return null;
}

Future<Map<String, dynamic>> getRequest(String url, String api, Map<String, dynamic> jsonMap) async {
  HttpClient httpClient = HttpClient();
  var uri = Uri.http(url, api, jsonMap);
  HttpClientRequest request = await httpClient.getUrl(Uri.parse(uri.toString()));
  request.headers.set('content-type', 'application/json');
  HttpClientResponse response = await request.close();
  String reply = await response.transform(utf8.decoder).join();
  httpClient.close();
  Map<String, dynamic> map = json.decode(reply);
  return map;
}