package com.zero.walletconnect.walletconnect;

import com.zero.walletconnect.walletconnect.Session;

public interface WalletConnectCallBack {
    void onSessionRequest(Session.MethodCall.SessionRequest sessionRequest);
    void onSessionDisconnect();
    void onCallRequestPersonalSign(Session.MethodCall.PersonalSign personalSign);
    void onCallRequestETHSign(Session.MethodCall.ETHSign signMessage);
    void onCallRequestETHSignTypedData(Session.MethodCall.ETHSignTypedData signTypedData);
    void onCallRequestETHSendTransaction(Session.MethodCall.ETHSendTransaction sendTransaction);
    void onCallRequestETHSignTransaction(Session.MethodCall.ETHSignTransaction signTransaction);
    void onCallRequestETHSendRawTransaction(Session.MethodCall.ETHSendRawTransaction signTransaction);
    void onError(String message);
}
