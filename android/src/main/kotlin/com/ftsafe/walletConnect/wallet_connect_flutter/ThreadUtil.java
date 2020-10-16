package com.ftsafe.walletConnect.wallet_connect_flutter;

import android.os.Handler;
import android.os.Looper;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * @author fengshuo
 * @date 2019/10/29
 * @time 20:01
 */
public class ThreadUtil {

    /** CPU 个数 */
    private static final int CPU_COUNT = Runtime.getRuntime().availableProcessors();
    /** 2 到 4 个线程，CPU_COUNT -1 避免后台工作饱和 */
    private static final int CORE_POOL_SIZE = Math.max(2, Math.min(CPU_COUNT - 1, 4));
    private static final ExecutorService mThreadPool = Executors.newFixedThreadPool(CORE_POOL_SIZE);
    private static final Handler sMainHandler = new Handler(Looper.getMainLooper());


    public static void subThread(Runnable runnable) {
        mThreadPool.execute(runnable);
    }

    public static void toMainThread(Runnable runnable) {
        sMainHandler.post(runnable);
    }

}
