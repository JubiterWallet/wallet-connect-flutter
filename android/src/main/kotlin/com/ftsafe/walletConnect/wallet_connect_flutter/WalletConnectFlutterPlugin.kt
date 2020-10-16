package com.ftsafe.walletConnect.wallet_connect_flutter

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.zero.walletconnect.walletconnect.Session
import com.zero.walletconnect.walletconnect.WallConnectInfoConfig
import com.zero.walletconnect.walletconnect.WalletConnectCallBack
import com.zero.walletconnect.walletconnect.WalletConnectManager
import com.zero.walletconnect.walletconnect.log.LogCallBack
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** WalletConnectFlutterPlugin */
public class WalletConnectFlutterPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var listen: EventChannel
    private lateinit var mContext: Context
    private lateinit var walletConnectManager: WalletConnectManager

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        mContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        channel.setMethodCallHandler(this);
        listen = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        listen.setStreamHandler(this)
    }


    companion object {

        private const val METHOD_CHANNEL_NAME = "wallet_connect_flutter"
        private const val EVENT_CHANNEL = "wallet_connect_flutter/event"
        const val TAG = "WalletConnectPlugin"

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            WalletConnectFlutterPlugin(registrar)
        }
    }

    constructor(registrar: Registrar) {
        mContext = registrar.context()
        val channel = MethodChannel(registrar.messenger(), METHOD_CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        val listen = EventChannel(registrar.messenger(), EVENT_CHANNEL);
        listen.setStreamHandler(this)
        init()
    }

    constructor()

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.mContext = binding.activity
        init()
    }


    private fun init() {
        walletConnectManager = WalletConnectManager.getInstance();
        walletConnectManager.init(mContext, WallConnectInfoConfig()
                .setClientId(UserManager.getRandomUUID(mContext))
                .setName(CommonInfo.APP_NAME)
                .setUrl(CommonInfo.APP_URL)
                .setIcon(CommonInfo.APP_ICON_URL)
                .setDescription(CommonInfo.APP_DESCRIPTION)
                .setLogCallBack(logCallBack)
                .setWalletConnectCallBack(walletConnectCallBack))
    }

    override fun onMethodCall(@NonNull call: MethodCall,@NonNull result: Result) {
        when (call.method) {
            "connect" -> {
                Log.d(TAG, ">>> connect")
                startConnect(call, result)
            }
            "approveSession" -> {
                Log.d(TAG, ">>> approveSession")
                approveSession(call, result)
            }
            "rejectSession" -> {
                Log.d(TAG, ">>> rejectSession")
                rejectSession(call, result)
            }
            "killSession" -> {
                Log.d(TAG, ">>> killSession")
                killSession(call, result)
            }
            "approveCallRequest" -> {
                Log.d(TAG, ">>> approveCallRequest")
                approveCallRequest(call, result)
            }
            "rejectCallRequest" -> {
                Log.d(TAG, ">>> rejectCallRequest")
                rejectCallRequest(call, result)
            }
            else -> {
            }
        }
    }

    private fun startConnect(call: MethodCall, result: Result) {
        try {
            val uri: String? = call.argument("uri")
            walletConnectManager.startConnect(mContext, uri)
            val rev: HashMap<String, Any> = HashMap()
            rev["error"] = 0
            rev["msg"] = "startConnect success"
            result.success(rev)
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("startConnect error", null, null)
        }
    }

    private fun approveSession(call: MethodCall, result: Result) {
        try {
            val chainID: Int? = call.argument("chainID")
            val addresses: ArrayList<String>? = call.argument("addresses")
            walletConnectManager.approveSession(addresses, chainID!!)
            val rev: HashMap<String, Any> = HashMap()
            rev["error"] = 0
            rev["msg"] = "approveSession success"
            result.success(rev)
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("approveSession error", null, null)
        }
    }


    private fun rejectSession(call: MethodCall, result: Result) {
        try {
            walletConnectManager.rejectSession()
            val rev: HashMap<String, Any> = HashMap()
            rev["error"] = 0
            rev["msg"] = "rejectSession success"
            result.success(rev)
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("rejectSession error", null, null)
        }
    }


    private fun killSession(call: MethodCall, result: Result) {
        try {
            walletConnectManager.stopConnect()
            val rev: HashMap<String, Any> = HashMap()
            rev["error"] = 0
            rev["msg"] = "killSession success"
            result.success(rev)
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("killSession error", null, null)
        }
    }

    private fun approveCallRequest(call: MethodCall, result: Result) {
        try {
            val id: Int? = call.argument("id")
            val resultParams: String? = call.argument("result")
            walletConnectManager.approveRequest(id!!.toLong(), resultParams!!)
            val rev: HashMap<String, Any> = HashMap()
            rev["error"] = 0
            rev["msg"] = "approveCallRequest success"
            result.success(rev)
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("approveCallRequest error", null, null)
        }
    }


    private fun rejectCallRequest(call: MethodCall, result: Result) {
        try {
            val id: Int? = call.argument("id")
            val resultParams: String? = call.argument("message")
            walletConnectManager.rejectRequest(id!!.toLong(), -1, resultParams!!)// todo errorCode
            val rev: HashMap<String, Any> = HashMap()
            rev["error"] = 0
            rev["msg"] = "rejectCallRequest success"
            result.success(rev)
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("rejectCallRequest error", null, null)
        }
    }


    private val logCallBack: LogCallBack = object : LogCallBack {
        override fun e(tag: String, log: String) {
            Log.e(tag, log)
        }

        override fun i(tag: String, log: String) {
            Log.i(tag, log)
        }
    }

    private var listonSink: EventSink? = null

    override fun onListen(arguments: Any?, sink: EventSink) {
        Log.d(TAG, ">>> listonHandler onListen")
        listonSink = sink
    }

    override fun onCancel(o: Any?) {
        Log.d(TAG, ">>> listonHandler onCancel")
        listonSink = null
    }

    private val walletConnectCallBack: WalletConnectCallBack = object : WalletConnectCallBack {
        override fun onSessionRequest(sessionRequest: Session.MethodCall.SessionRequest?) {
            val result: HashMap<String, Any> = HashMap()
            result["eventName"] = "onSessionRequest"

            val params: HashMap<String, Any> = HashMap()
            params["id"] = sessionRequest!!.id
            val adapter = walletConnectManager.moshi.adapter<Session.PeerData>(Session.PeerData::class.java)
            params["data"] = adapter.toJson(sessionRequest.peer)

            result["params"] = params
            ThreadUtil.toMainThread {
                listonSink?.success(result)
            }
        }

        override fun onSessionDisconnect() {
            val result: HashMap<String, Any> = HashMap()
            result["eventName"] = "onSessionDissconnect"
            result["params"] = "sessionDisconnect"
            ThreadUtil.toMainThread {
                listonSink?.success(result)
            }
        }

        override fun onCallRequestPersonalSign(personalSign: Session.MethodCall.PersonalSign?) {
            val result: HashMap<String, Any> = HashMap()
            result["eventName"] = "onCallRequestPersonalSign"
            val params: HashMap<String, Any> = HashMap()
            params["id"] = personalSign!!.id
            params["rawJson"] = "[\"${personalSign.message}\",\"${personalSign.account}\"]"
            result["params"] = params
            ThreadUtil.toMainThread {
                listonSink?.success(result)
            }
        }

        override fun onCallRequestETHSign(signMessage: Session.MethodCall.ETHSign?) {
            val result: HashMap<String, Any> = HashMap()
            result["eventName"] = "onCallRequestEthSign"
            val params: HashMap<String, Any> = HashMap()
            params["id"] = signMessage!!.id
            params["rawJson"] = "[\"${signMessage.address}\",\"${signMessage.message}\"]"
            result["params"] = params
            ThreadUtil.toMainThread {
                listonSink?.success(result)
            }
        }

        override fun onCallRequestETHSignTypedData(signTypedData: Session.MethodCall.ETHSignTypedData?) {
            val result: HashMap<String, Any> = HashMap()
            result["eventName"] = "onCallRequestEthSignTypedData"
            val params: HashMap<String, Any> = HashMap()
            params["id"] = signTypedData!!.id
            params["rawJson"] = signTypedData.message
            result["params"] = params
            ThreadUtil.toMainThread {
                listonSink?.success(result)
            }
        }

        override fun onCallRequestETHSendTransaction(sendTransaction: Session.MethodCall.ETHSendTransaction?) {
            val result: HashMap<String, Any> = HashMap()
            result["eventName"] = "onCallRequestEthSendTransaction"
            val params: HashMap<String, Any> = HashMap()
            params["id"] = sendTransaction!!.id
            val adapter = walletConnectManager.moshi.adapter<Session.MethodCall.ETHSendTransaction>(Session.MethodCall.ETHSendTransaction::class.java)
            params["rawJson"] = adapter.toJson(sendTransaction)
            result["params"] = params
            ThreadUtil.toMainThread {
                listonSink?.success(result)
            }
        }

        override fun onCallRequestETHSignTransaction(signTransaction: Session.MethodCall.ETHSignTransaction?) {
            val result: HashMap<String, Any> = HashMap()
            result["eventName"] = "onCallRequestEthSignTransaction"
            val params: HashMap<String, Any> = HashMap()
            params["id"] = signTransaction!!.id
            val adapter = walletConnectManager.moshi.adapter<Session.MethodCall.ETHSignTransaction>(Session.MethodCall.ETHSignTransaction::class.java)
            params["rawJson"] = adapter.toJson(signTransaction)
            result["params"] = params
            ThreadUtil.toMainThread {
                listonSink?.success(result)
            }
        }

        override fun onCallRequestETHSendRawTransaction(signTransaction: Session.MethodCall.ETHSendRawTransaction?) {
            val result: HashMap<String, Any> = HashMap()
            result["eventName"] = "onCallRequestEthSendRawTransaction"
            val params: HashMap<String, Any> = HashMap()
            params["id"] = signTransaction!!.id
            params["rawJson"] = "[\"${signTransaction.address}\"]"
            result["params"] = params
            ThreadUtil.toMainThread {
                listonSink?.success(result)
            }
        }

        override fun onError(message:String?) {
            val result: HashMap<String, Any> = HashMap()
            result["eventName"] = "onError"
            result["params"] = message!!
            ThreadUtil.toMainThread {
                listonSink?.success(result)
            }
        }

    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        listen.setStreamHandler(null)
    }


    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(p0: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivity() {
    }
}
