package com.zegocloud.uikit.flutter.live_streaming

import androidx.annotation.NonNull
import android.content.Context
import android.app.Activity
import android.os.Looper
import android.os.Handler;
import android.view.View

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformViewFactory

import tech.sud.mgp.core.SudMGP
import tech.sud.mgp.core.ISudFSMMG;
import tech.sud.mgp.core.ISudFSMStateHandle;
import tech.sud.mgp.core.ISudFSTAPP;
import tech.sud.mgp.core.ISudListenerInitSDK;
import tech.sud.mgp.core.ISudListenerGetMGList;
 

class SudMGPPlugin: FlutterPlugin, MethodCallHandler ,ActivityAware, EventChannel.StreamHandler, PlatformView, PlatformViewFactory(StandardMessageCodec.INSTANCE){

    private var uiHandler: Handler? = null
    private lateinit var context : Context
    private lateinit var activity : Activity
    private lateinit var methodChannel : MethodChannel
    private lateinit var eventChannel : EventChannel
    private var eventSink: EventChannel.EventSink?= null

    private var _gameApp: ISudFSTAPP?=null // game interface
    private lateinit var _gameView: View

    private var _viewSize : String? =null
    private var _gameConfig : String? =null

    init {
        if (uiHandler == null) {
            uiHandler = Handler(Looper.getMainLooper())
        }
    }
    // FlutterPlugin
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "SudMGPPlugin")
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger,"SudMGPPluginEvent")

        flutterPluginBinding.getPlatformViewRegistry().registerViewFactory("SudMGPPluginView", this);

        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this);
      }
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    // ActivityAware
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity;
    }
    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}

    // EventChannel.StreamHandler Interface
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }
    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // method channel
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when(call.method) {
            "getVersion" -> { getVersion(call, result)}
            "initSDK" -> { initSDK(call, result)}
            "loadGame" -> { loadGame(call, result)}
            "destroyGame" -> { destroyGame(call, result)}
            "getGameList" -> { getGameList(call, result)}
            "updateCode" -> { updateCode(call, result)}
            
            else -> { result.notImplemented() }
        }
    }


    fun getVersion(call: MethodCall, result: MethodChannel.Result) {
        var version = SudMGP.getVersion();
        result.success(mapOf("errorCode" to 0, "version" to version))
    }

    fun initSDK(call: MethodCall, result: MethodChannel.Result) {
        val appid: String? = call.argument<String>("appid")
        val appkey: String? = call.argument<String>("appkey")
        var isTestEnv: Boolean? = call.argument<Boolean>("isTestEnv")


        SudMGP.initSDK(context, appid, appkey, isTestEnv?:false, object:ISudListenerInitSDK {
            override fun onSuccess(){
                result.success(mapOf("errorCode" to 0, "message" to "success"))
            }

            override fun onFailure(errorCode: Int, message: String) {
                result.success(mapOf("errorCode" to errorCode, "message" to message))
            }
            
        })
    }
    fun getGameList(call: MethodCall, result: MethodChannel.Result) {
        SudMGP.getMGList(object:ISudListenerGetMGList  {
            override fun onSuccess(dataJson: String?) {
                result.success(mapOf("errorCode" to 0, "message" to "success","dataJson" to dataJson))
            }
            override fun onFailure(errorCode: Int, message: String) {
                result.success(mapOf("errorCode" to errorCode, "message" to message))
            }
        })
    }

    fun destroyGame(call: MethodCall, result: MethodChannel.Result) {
        if(_gameApp!=null) {
            SudMGP.destroyMG(_gameApp)
        }
        result.success(mapOf("errorCode" to 0, "message" to "success"))
    }

    fun updateCode(call: MethodCall, result: MethodChannel.Result) {
        val code: String? = call.argument<String>("code")
        _gameApp?.updateCode(code?:"", null);
        result.success(mapOf("errorCode" to 0, "message" to "success"))
    }

    fun loadGame(call: MethodCall, result: MethodChannel.Result) {
        val userid: String? = call.argument<String>("userid")
        val roomid: String? = call.argument<String>("roomid")
        val code: String? = call.argument<String>("code")
        var gameid: Long?= call.argument<Long>("gameid")
        val language: String? = call.argument<String>("language")
        _viewSize = call.argument<String>("viewSize")
        _gameConfig = call.argument<String>("gameConfig")

        _gameApp = SudMGP.loadMG(activity, userid, roomid, code, gameid?:0, language, object:ISudFSMMG {
            override fun onGameLog(dataJson: String?) {
                uiHandler?.post(Runnable { eventSink?.success(mapOf("method" to "onGameLog","dataJson" to dataJson)) })
            }

            override fun onGameLoadingProgress(p0: Int, p1: Int, p2: Int) {
            }

            override fun onGameStarted() {
                uiHandler?.post(Runnable { eventSink?.success(mapOf("method" to "onGameStarted")) })
            }
            override fun onGameDestroyed() {
                uiHandler?.post(Runnable { eventSink?.success(mapOf("method" to "onGameDestroyed")) })
            }
            override fun onExpireCode(handle: ISudFSMStateHandle?, dataJson: String?) {
                uiHandler?.post(Runnable { eventSink?.success(mapOf("method" to "onExpireCode","dataJson" to dataJson)) })
                handle?.success("{}");
            }
            override fun onGetGameViewInfo(handle: ISudFSMStateHandle?, dataJson: String?) {
                handle?.success(_viewSize);
            }
            override fun onGetGameCfg(handle: ISudFSMStateHandle?, dataJson: String?) {
                handle?.success(_gameConfig);
            }
            override fun onGameStateChange(handle: ISudFSMStateHandle?, state: String, dataJson: String) {
                uiHandler?.post(Runnable { eventSink?.success(mapOf("method" to "onGameStateChange","dataJson" to dataJson,"state" to state)) })
                handle?.success("{}");
            }
            override fun onPlayerStateChange(handle: ISudFSMStateHandle?,userId: String,state: String,dataJson: String) {
                uiHandler?.post(Runnable { eventSink?.success(mapOf("method" to "onPlayerStateChange","dataJson" to dataJson,"userId" to userId,"state" to state)) })
                handle?.success("{}");
            }
         })

        _gameView = _gameApp!!.getGameView();

        result.success(mapOf("errorCode" to 0, "message" to "success"))
    }


    // PlatformViewFactory
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return this
    }
    // PlatformView
    override fun getView(): View {
        return _gameView
    }
    override fun dispose() {}
}