package com.ftsafe.walletConnect.wallet_connect_flutter;

import android.content.Context;
import android.content.SharedPreferences;

public class SharedPreferenceManager {

    private static final String SAVED_UUID = "savedUuid";

    public static String getSavedUUID(Context context) {
        SharedPreferences configSP = SharedPreferenceFactory.getConfigSP(context);
        return get(configSP, SAVED_UUID, "");
    }

    public static void setSavedUUID(Context context,String savedUUID) {
        SharedPreferences configSP = SharedPreferenceFactory.getConfigSP(context);
        SharedPreferences.Editor editor = configSP.edit();
        put(SAVED_UUID, savedUUID, editor);
    }

    private static void put(String key, String value, SharedPreferences.Editor editor) {
        editor.putString(key, value);
        editor.apply();
    }


    private static String get(SharedPreferences preferences, String key, String defaultValue) {
        return preferences.getString(key, defaultValue);
    }

}
