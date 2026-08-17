package com.example.dailyapp;

import android.app.Activity;
import android.os.Bundle;
import android.view.KeyEvent;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/**
 * APK 壳：只做一件事——把远程"每日页面"装进 WebView。
 * 所有会每天变化的内容都在远端（GitHub Pages 上的 index.html），
 * 本机绝不打包任何每日数据，因此 APK 装一次就永远最新。
 */
public class MainActivity extends Activity {

    private WebView webView;

    // 你的 GitHub Pages 地址（每日页面托管在这里）
    private static final String REMOTE_URL =
            "https://wangcyuyan.github.io/daily-apk/index.html";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        webView = findViewById(R.id.webview);
        WebSettings ws = webView.getSettings();

        // 远端页面要用 JS 去 fetch data.json，所以必须开 JavaScript
        ws.setJavaScriptEnabled(true);
        ws.setDomStorageEnabled(true);
        // 关键：禁用 WebView 缓存，保证每次拿到的是当天内容，不读旧副本
        ws.setCacheMode(WebSettings.LOAD_NO_CACHE);

        // 在 WebView 内部打开页面，而不是跳到系统浏览器
        webView.setWebViewClient(new WebViewClient());

        loadLatest();
    }

    /**
     * 加载最新内容：URL 末尾追加时间戳(?t=...)做"缓存破坏"，
     * 即使 CDN/系统有缓存，也能强制拿到最新一版。
     */
    private void loadLatest() {
        String url = REMOTE_URL + "?t=" + System.currentTimeMillis();
        webView.loadUrl(url);
    }

    /**
     * 回到前台也刷新一次——用户切走再切回，依然看到当天最新。
     */
    @Override
    protected void onResume() {
        super.onResume();
        loadLatest();
    }

    /**
     * 物理返回键：先在 WebView 历史里后退，避免一键直接退出 App。
     */
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK && webView.canGoBack()) {
            webView.goBack();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }
}
