import 'package:flutter/material.dart';
import 'package:wallet_connect_flutter/wallet_connect_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements IWCHandler {
  String _platformVersion = 'Unknown';
  WalletConnectFlutter conn;
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void initPlatformState() async {
    conn = WalletConnectFlutter(handler: this);
    var res = await conn.connect(
        'wc:bc07300e-b3e5-4e40-896c-6333fb3b5cec@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=ace82a685a0df5dda3c5d8488930420a1a235c7633071bda673e4288a41a1dab');
    if (res.isError()) {
      return;
    }

    print(res);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }

  @override
  void onCallRequestEthSendRawTransaction(String requestInJson) {
    print(requestInJson);
  }

  @override
  void onCallRequestEthSendTransaction(int id, String requestInJson) {
    print(requestInJson);
  }

  @override
  void onCallRequestEthSign(int id, String requestInJson) {
    print(requestInJson);
  }

  @override
  void onCallRequestEthSignTransaction(int id, String requestInJson) {
    print(requestInJson);
  }

  @override
  void onCallRequestEthSignTypedData(int id, String requestInJson) {
    print(requestInJson);
  }

  @override
  void onCallRequestPersonalSign(int id, String requestInJson) {
    print(requestInJson);
  }

  @override
  void onError(String error) {
    print(error);
  }

  @override
  void onSessionDissconnect(String errInJson) {
    print(errInJson);
  }

  @override
  void onSessionRequest(int id, String requestInJson) async {
    await conn.approveSession(
      ['0x448ae09Ee40E4B755c4590eaEE82D1D069bfee91'],
      1,
    );
    print(requestInJson);
  }
}
