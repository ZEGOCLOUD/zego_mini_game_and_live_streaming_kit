// Flutter imports:
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:live_streaming/constants.dart';

// Package imports:
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

// Project imports:
import 'common.dart';
import 'game_plugin.dart';
import 'game_utils.dart';

const String MG_NAME_LOGIN_AUTH_URL = 'Your auth url';
const String MG_APPID = 'Your mini game app id';
const String MG_APPKEY = 'Your mini game app key';
const bool MG_APP_IS_TEST_ENV = true;

class LivePage extends StatefulWidget {
  final String liveID;
  final bool isHost;

  const LivePage({
    Key? key,
    required this.liveID,
    this.isHost = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => LivePageState();
}

class LivePageState extends State<LivePage> {
  ZegoUIKitPrebuiltLiveStreamingController? liveController;

  String _authcode = '';
  Widget? _gameView;
  final GlobalKey _gameViewKey = GlobalKey();
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();


  @override
  void initState() {
    super.initState();
    liveController = ZegoUIKitPrebuiltLiveStreamingController();
    SudMGPPlugin.registerEventHandler(onGameEvent);
    getCode();
    initGameSDK();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      loadGame();
    });
  }

  @override
  void dispose() {
    super.dispose();
    liveController = null;
  }

  void getCode() {
    getRequest(MG_NAME_LOGIN_AUTH_URL, '/api/get_code', {
      'uid': localUserID
    }).then((rsp) => setState(() {
      if (rsp['ret_code'] == 0) {
        _authcode = rsp['data']['code'];
      }
    }));
  }

  void initGameSDK() {
    SudMGPPlugin.initSDK(MG_APPID, MG_APPKEY, MG_APP_IS_TEST_ENV);
  }

  void loadGame() {
    if (TargetPlatform.android ==
        defaultTargetPlatform) {
      loadAndroidGame();
    } else if (TargetPlatform.iOS ==
        defaultTargetPlatform) {
      loadIOSGame();
    }
  }

  void loadIOSGame() {
    _gameView = getPlatformView('SudMGPPluginView', (int viewid)
    {
      print("Start Load Game");
      SudMGPPlugin.loadGame(
          localUserID,
          widget.liveID,
          _authcode,
          1468180338417074177,
          "default",
          getGameViewSize(),
          getGameConfig())
          .then((ret) {
        setState(() => {});
      });
    });
  }

  void loadAndroidGame() {
    SudMGPPlugin.loadGame(
        localUserID,
        widget.liveID,
        _authcode,
        1468180338417074177,
        "default",
        getGameViewSize(),
        getGameConfig())
        .then((ret) { setState(() => _gameView = getPlatformView(
          'SudMGPPluginView',
              (int viewid) => {}));
        });
  }

  void onGameEvent(Map map) {
    String method = map['method'];
    switch (method) {
      case 'onGameStarted':
        setState(() {
        });
        break;
      case 'onGameDestroyed':
        break;
      case 'onGameStateChange':
        break;
      case 'onGetGameCfg':
        break;
      case 'onPlayerStateChange':
        break;
      case 'onExpireCode':
        break;
      default:
    }
  }

  String getGameViewSize() {
    final screenWidth = MediaQuery.of(context).size.width * widgetsBinding.window.devicePixelRatio;
    final screenHeight = MediaQuery.of(context).size.height * widgetsBinding.window.devicePixelRatio * 0.5;

    return json.encode({
      "view_size": {"width": screenWidth, "height": screenHeight},
      "view_game_rect": {"left": 0, "top": 0, "right": 0, "bottom": 0}
    });
  }

  String getGameConfig() {
    return json.encode({});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltLiveStreaming(
        appID: your zegocloud app id /*input your AppID*/,
        appSign: 'your zegocloud app sign' /*input your AppSign*/,
        userID: localUserID,
        userName: 'user_$localUserID',
        liveID: widget.liveID,
        controller: liveController,
        config: (widget.isHost
            ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
            : ZegoUIKitPrebuiltLiveStreamingConfig.audience())
          ..avatarBuilder = customAvatarBuilder
        ..foreground = Positioned(bottom:10, right:10, child: ElevatedButton(
          child: Text('Play Game'),
          onPressed: () {
            loadGame();
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: _gameView,
                  ),
                );
              },
            ).whenComplete(() {

            });
          },
        )),
      ),
    );
  }
}
