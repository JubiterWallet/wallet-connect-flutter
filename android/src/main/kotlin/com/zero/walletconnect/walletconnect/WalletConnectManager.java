package com.zero.walletconnect.walletconnect;

import android.content.Context;
import android.text.TextUtils;

import com.zero.walletconnect.walletconnect.impls.FileWCSessionStore;
import com.zero.walletconnect.walletconnect.impls.MoshiPayloadAdapter;
import com.zero.walletconnect.walletconnect.impls.OkHttpTransport;
import com.zero.walletconnect.walletconnect.impls.WCSession;
import com.squareup.moshi.Moshi;
import com.zero.walletconnect.walletconnect.log.WCLogUtil;

import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.util.ArrayList;

import okhttp3.OkHttpClient;

public class WalletConnectManager {

    private static final String TAG = "WalletConnectManager";
    private static final WalletConnectManager walletConnectManager = new WalletConnectManager();

    private WallConnectInfoConfig wallConnectInfoConfig;


    private Moshi moshi;
    private OkHttpClient client;
    private FileWCSessionStore storage;
    private Session session;

    private Session.PeerMeta peerMeta;
    private Session.PeerData peerData;
    // 某些情况用户之间杀进程，导致websocket断开连接，下次起来需要重新连接然后告知服务端断开连接，否则DApp与server的连接会长时间存在，导致无法使用
    private boolean needStopConnect = false;

    private WalletConnectManager() {
    }

    public static WalletConnectManager getInstance() {
        return walletConnectManager;
    }

    public void init(Context context, final WallConnectInfoConfig wallConnectInfoConfig) {
        if (null == wallConnectInfoConfig) {
            WCLogUtil.e(TAG, "in init wallConnectInfoConfig is empty.");
            return;
        }
        this.wallConnectInfoConfig = wallConnectInfoConfig;
        peerMeta = new Session.PeerMeta(wallConnectInfoConfig.getUrl(),
                wallConnectInfoConfig.getName(),
                wallConnectInfoConfig.getDescription(),
                new ArrayList<String>() {{
                    add(wallConnectInfoConfig.getIcon());
                }});
        peerData = new Session.PeerData(wallConnectInfoConfig.getClientId(), peerMeta);
        WCLogUtil.init(wallConnectInfoConfig.getLogCallBack());

        String latestProtocolUrl = WalletConnectSharedPreference.getLatestWCProtocol(context);
        if (!TextUtils.isEmpty(latestProtocolUrl)) {
            // 标记需要断开连接
            needStopConnect = true;
            startConnect(context, latestProtocolUrl);
        }
    }

    public void initConnectUtil(Context context) {
        if (null == context) {
            return;
        }
        moshi = new Moshi.Builder().build();
        // 创建存储文件
        if (!WCFileUtil.isExist(context.getCacheDir().getAbsolutePath() + "/session_store.json")) {
            WCFileUtil.createNewFile(context.getCacheDir().getAbsolutePath(), "session_store.json");
        }
        storage = new FileWCSessionStore(new File(context.getCacheDir(), "session_store.json"), moshi);
        client = new OkHttpClient.Builder().build();
    }

    public void startConnect(Context context, String protocolUrl) {
        WCLogUtil.i(TAG, "in startConnect protocolUrl:" + protocolUrl);
        try {
            // 如果已经连接过，先kill链接
            stopConnect();
            if (session != null) {
                return;
            }
            // 初始化链接工具
            initConnectUtil(context);
            // 解析链接
            Session.Config config = WalletConnectUtil.parseWalletConnectProtocol(protocolUrl);
            // 创建会话框
            session = new WCSession(config,
                    new MoshiPayloadAdapter(moshi),
                    storage,
                    new OkHttpTransport.Builder(client, moshi),
                    peerMeta,
                    peerData.getId());
            session.init();
//        session.offer();
            session.addCallback(sessionCallBack);
            WalletConnectSharedPreference.setLatestWCProtocol(context, protocolUrl);
        } catch (Exception e) {
            e.printStackTrace();
            // 出现异常，删除本地存储的json文件
            WCFileUtil.createNewFile(context.getCacheDir().getAbsolutePath(), "session_store.json");
        }
    }

    public void stopConnect() {
        if (null == session) {
            return;
        }
        session.kill();
        session.clearCallbacks();
        session = null;
    }

    public void approveSession(ArrayList<String> ethAddresses, int mainChainId) {
        if (null == session) {
            return;
        }
        session.approve(ethAddresses, mainChainId);
    }

    public void updateSession(ArrayList<String> ethAddresses, int mainChainId) {
        if (null == session) {
            return;
        }
        session.update(ethAddresses, mainChainId);
    }

    public void rejectSession() {
        if (null == session) {
            return;
        }
        session.reject();
    }

    public void approveRequest(long id, Object obj) {
        if (null == session) {
            return;
        }
        session.approveRequest(id, obj);
    }

    public void rejectRequest(long id, long errorCode, String errorMsg) {
        if (null == session) {
            return;
        }
        session.rejectRequest(id, errorCode, errorMsg);
    }

    private void sessionApproved() {
        WCLogUtil.i(TAG, "in sessionApproved.");
    }

    private void sessionClosed() {
        WCLogUtil.i(TAG, "in sessionClosed.");
        wallConnectInfoConfig.getWalletConnectCallBack().onSessionDisconnect();
    }

    private void sessionConnected() {
        WCLogUtil.i(TAG, "in sessionConnected.");
        if (needStopConnect) {
            needStopConnect = false;
            stopConnect();
        }
    }

    public Moshi getMoshi() {
        return moshi;
    }

    private Session.Callback sessionCallBack = new Session.Callback() {
        @Override
        public void onStatus(@NotNull Session.Status status) {
            WCLogUtil.i(TAG, "in sessionCallBack status:" + status);
            if (status == Session.Status.Approved.INSTANCE) {
                WCLogUtil.i(TAG, "in sessionCallBack Session.Status.Approved.INSTANCE");
                sessionApproved();
            } else if (status == Session.Status.Closed.INSTANCE) {
                WCLogUtil.i(TAG, "in sessionCallBack Session.Status.Closed.INSTANCE");
                sessionClosed();
            } else if (status == Session.Status.Connected.INSTANCE) {
                WCLogUtil.i(TAG, "in sessionCallBack Session.Status.Connected.INSTANCE");
                sessionConnected();
            } else if (status instanceof Session.Status.Error) {
                //todo
                wallConnectInfoConfig.getWalletConnectCallBack().onError(((Session.Status.Error) status).getThrowable().getLocalizedMessage());
            } else {
                WCLogUtil.i(TAG, "in sessionCallBack Session.Status else:" + status);
            }
        }

        @Override
        public void onMethodCall(@NotNull Session.MethodCall call) {
            WCLogUtil.i(TAG, "in sessionCallBack onMethodCall:" + call.toString());
            try {
                if (call instanceof Session.MethodCall.SessionRequest) {
                    wallConnectInfoConfig.getWalletConnectCallBack().onSessionRequest((Session.MethodCall.SessionRequest) call);
                } else if (call instanceof Session.MethodCall.PersonalSign) {
                    wallConnectInfoConfig.getWalletConnectCallBack().onCallRequestPersonalSign((Session.MethodCall.PersonalSign) call);
                } else if (call instanceof Session.MethodCall.ETHSign) {
                    wallConnectInfoConfig.getWalletConnectCallBack().onCallRequestETHSign((Session.MethodCall.ETHSign) call);
                } else if (call instanceof Session.MethodCall.ETHSignTypedData) {
                    wallConnectInfoConfig.getWalletConnectCallBack().onCallRequestETHSignTypedData((Session.MethodCall.ETHSignTypedData) call);
                } else if (call instanceof Session.MethodCall.ETHSendTransaction) {
                    wallConnectInfoConfig.getWalletConnectCallBack().onCallRequestETHSendTransaction((Session.MethodCall.ETHSendTransaction) call);
                } else if (call instanceof Session.MethodCall.ETHSignTransaction) {
                    wallConnectInfoConfig.getWalletConnectCallBack().onCallRequestETHSignTransaction((Session.MethodCall.ETHSignTransaction) call);
                } else if (call instanceof Session.MethodCall.ETHSendRawTransaction) {
                    wallConnectInfoConfig.getWalletConnectCallBack().onCallRequestETHSendRawTransaction((Session.MethodCall.ETHSendRawTransaction) call);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    };

}
