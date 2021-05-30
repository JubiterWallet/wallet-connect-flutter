import 'dart:async';

import 'package:flutter/services.dart';

enum WalletConnectPluginError {
  none,
  allreadyConnected,
  uriError,
  connectedError,
  approveError,
  rejectError,
}

abstract class IWCHandler {
  void onSessionRequest(int? id, String? requestInJson);
  void onSessionDisconnect(String? errInJson);
  //以下不同请求类型具体签名方式见 https://docs.walletconnect.org/json-rpc-api-methods/ethereum
  void onCallRequestPersonalSign(int? id, String? requestInJson);
  void onCallRequestEthSign(int? id, String? requestInJson);
  void onCallRequestEthSignTypedData(int? id, String? requestInJson);
  void onCallRequestEthSendTransaction(int? id, String? requestInJson);
  void onCallRequestEthSignTransaction(int? id, String? requestInJson);
  void onCallRequestEthSendRawTransaction(int? id, String? requestInJson);
  void onError(String? error);
}

class WalletConnectFlutter {
  static const MethodChannel _channel =
      const MethodChannel('wallet_connect_flutter');
  static const EventChannel _eventChannel =
      const EventChannel('wallet_connect_flutter/event');
  String? uri;
  final IWCHandler? handler;
  WalletConnectFlutter({this.handler}) {
    liston();
  }

  liston() async {
    await for (Map event in _eventChannel.receiveBroadcastStream()) {
      var params = event['params'];
      switch (event['eventName']) {
        case 'onSessionRequest':
          handler!.onSessionRequest(params['id'], params['data']);
          break;
        case 'onSessionDissconnect':
          handler!.onSessionDisconnect(params);
          break;
        case 'onCallRequestPersonalSign':
          handler!.onCallRequestPersonalSign(params['id'], params['rawJson']);

          break;
        case 'onCallRequestEthSign':
          handler!.onCallRequestEthSign(params['id'], params['rawJson']);

          break;
        case 'onCallRequestEthSignTypedData':
          handler!
              .onCallRequestEthSignTypedData(params['id'], params['rawJson']);

          break;
        case 'onCallRequestEthSendTransaction':
          handler!
              .onCallRequestEthSendTransaction(params['id'], params['rawJson']);

          break;
        case 'onCallRequestEthSignTransaction':
          handler!
              .onCallRequestEthSignTransaction(params['id'], params['rawJson']);
          break;
        case 'onCallRequestEthSendRawTransaction':
          handler!.onCallRequestEthSendRawTransaction(
              params['id'], params['rawJson']);
          break;
        case 'onError':
          handler!.onError(params);
          break;
        default:
      }
    }
  }

  Future<WalletConnectResponse> connect(String uri) async {
    this.uri = uri;
    Map res = await _channel.invokeMethod('connect', {"uri": uri});
    return WalletConnectResponse.fromJson(res);
  }

  Future<WalletConnectResponse> approveSession(
      List<String> addresses, int chainID) async {
    this.uri = uri;
    Map res = await _channel.invokeMethod('approveSession', {
      "addresses": addresses,
      "chainID": chainID,
    });
    return WalletConnectResponse.fromJson(res);
  }

  Future<WalletConnectResponse> rejectSession() async {
    Map res = await _channel.invokeMethod('rejectSession', {});
    return WalletConnectResponse.fromJson(res);
  }

  Future<WalletConnectResponse> killSession() async {
    Map res = await _channel.invokeMethod('killSession', {});
    return WalletConnectResponse.fromJson(res);
  }

  Future<WalletConnectResponse> approveCallRequest(
      int id, String result) async {
    Map res = await _channel.invokeMethod('approveCallRequest', {
      'id': id,
      'result': result,
    });
    return WalletConnectResponse.fromJson(res);
  }

  Future<WalletConnectResponse> rejectCallRequest(
      int id, String message) async {
    Map res = await _channel.invokeMethod('rejectCallRequest', {
      'id': id,
      'message': message,
    });
    return WalletConnectResponse.fromJson(res);
  }
}

class WalletConnectResponse {
  WalletConnectPluginError? error;
  dynamic data;
  String? msg;
  WalletConnectResponse();

  isError() {
    return error != WalletConnectPluginError.none;
  }

  factory WalletConnectResponse.fromJson(Map json) {
    return WalletConnectResponse()
      ..error = WalletConnectPluginError.values[json['error'] ?? 0]
      ..data = json['data'] ?? {}
      ..msg = json['msg'] ?? '';
  }

  @override
  String toString() {
    return '''
      data:$data,
      msg:$msg,
      error:$error,
    ''';
  }
}
