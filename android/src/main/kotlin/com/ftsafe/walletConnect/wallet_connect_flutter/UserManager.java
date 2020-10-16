package com.ftsafe.walletConnect.wallet_connect_flutter;

import android.content.Context;
import android.text.TextUtils;

import java.util.UUID;

public class UserManager {
    public static String getRandomUUID(Context context) {
        String savedUUID = SharedPreferenceManager.getSavedUUID(context);
        if (TextUtils.isEmpty(savedUUID)) {
            // 创建UUID
            savedUUID = UUID.randomUUID().toString();
            SharedPreferenceManager.setSavedUUID(context,savedUUID);
        }
        return savedUUID;
    }
}
