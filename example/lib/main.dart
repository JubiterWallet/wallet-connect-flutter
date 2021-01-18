import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:wallet_connect_flutter/wallet_connect_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements IWCHandler {
  String title = "WalletConnectFlutter";
  String url = "https://public.jubiterwallet.com.cn/walletConnect/";
  WalletConnectFlutter conn;

  //WebViewController _controller;
  InAppWebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void initPlatformState() async {
    conn = WalletConnectFlutter(handler: this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            this.title,
            style: TextStyle(fontSize: 14),
          ),
          backgroundColor: Color(0xFF151A35),
          centerTitle: true,
          elevation: 0,
        ),
        body: Stack(children: <Widget>[
          // WebView(
          //   userAgent:
          //       "Mozilla/5.0 (Linux; Android 4.4.4; SAMSUNG-SM-N900A Build/tt) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/33.0.0.0 Mobile Safari/537.36",
          //   initialUrl: this.url,
          //   //JS执行模式 是否允许JS执行
          //   javascriptMode: JavascriptMode.unrestricted,
          //   onWebViewCreated: (controller) {
          //     _controller = controller;
          //   },
          //   onPageFinished: (url) {
          //     setState(() {
          //       isLoading = false; // 页面加载完成，更新状态
          //     });
          //   },
          //   navigationDelegate: (NavigationRequest request) {
          //     setState(() {
          //       isLoading = true; // 开始访问页面，更新状态
          //     });
          //     if (request.url.startsWith("wc:")) {
          //       connect(request.url);
          //       setState(() {
          //         isLoading = false;
          //       });
          //       return NavigationDecision.prevent;
          //     }
          //
          //     return NavigationDecision.navigate;
          //   },
          // ),
          InAppWebView(
              initialUrl: this.url,
              initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                      debuggingEnabled: true,
                      // userAgent: ,
                      useShouldOverrideUrlLoading: true)),
              onWebViewCreated: (InAppWebViewController controller) {
                _controller = controller;
              },
              onLoadStart: (InAppWebViewController controller, String url) {
                setState(() {
                  isLoading = true; // 开始访问页面，更新状态
                });
              },
              onLoadStop:
                  (InAppWebViewController controller, String url) async {
                setState(() {
                  isLoading = false;
                });
              },
              shouldOverrideUrlLoading: (controller, request) async {
                var url = request.url;
                if (url.startsWith("wc:")) {
                  connect(request.url);
                  return ShouldOverrideUrlLoadingAction.CANCEL;
                }
                return ShouldOverrideUrlLoadingAction.ALLOW;
              }),
          isLoading
              ? Container(
                  color: Color(0xFF151A35),
                  child: Center(
                    child: CircularProgressIndicator(
                        backgroundColor: Color(0xFF151A35)),
                  ),
                )
              : Container(),
        ]),
      ),
    );
  }

  Future<void> connect(String uri) async {
    if (!uri.contains('bridge')) {
      return;
    }
    await conn.killSession();
    var res = await conn.connect(uri);
    if (res.isError()) {
      return;
    }
    print(res);
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
  void onSessionRequest(int id, String requestInJson) async {
    await conn.approveSession(
      ['0x2c70f383699004f9e7eff8d595b354f5785dc10b'],
      1,
    );
    print(requestInJson);
  }

  @override
  void onCallRequestEthSendRawTransaction(int id, String requestInJson) {
    print(requestInJson);
  }

  @override
  void onSessionDisconnect(String errInJson) {
    print(errInJson);
  }
}
