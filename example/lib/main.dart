import 'package:flutter/material.dart';
import 'package:wallet_connect_flutter/wallet_connect_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements IWCHandler {
  String title = "WalletConnectFlutter";
  String url = "https://public.jubiterwallet.com.cn/uniswap";
  WalletConnectFlutter conn;

  WebViewController _controller;
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
          WebView(
            userAgent:
                "Mozilla/5.0 (Linux; Android 4.4.4; SAMSUNG-SM-N900A Build/tt) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/33.0.0.0 Mobile Safari/537.36",
            initialUrl: this.url,
            //JS执行模式 是否允许JS执行
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onPageFinished: (url) {
              setState(() {
                isLoading = false; // 页面加载完成，更新状态
              });
            },
            navigationDelegate: (NavigationRequest request) {
              setState(() {
                isLoading = true; // 开始访问页面，更新状态
              });
              if (request.url.startsWith("wc:")) {
                connect(request.url);
                setState(() {
                  isLoading = false;
                });
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
          ),
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
    var res = await conn.connect(uri);
    if (res.isError()) {
      return;
    }
    print(res);
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
