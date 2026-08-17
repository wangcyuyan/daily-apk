// 最小离线缓存：index.html / 图标走缓存优先；data.json 永远联网优先（保证每天最新）
const CACHE = 'daily-apk-v1';

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(['index.html', 'icon-192.png', 'icon-512.png'])));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))));
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  if (url.pathname.endsWith('data.json')) {
    // 数据：网络优先，失败再用缓存（保证每天刷新，断网也不崩）
    e.respondWith(fetch(e.request).then((res) => {
      const copy = res.clone();
      caches.open(CACHE).then((c) => c.put(e.request, copy));
      return res;
    }).catch(() => caches.match(e.request)));
  } else {
    // 页面与图标：缓存优先
    e.respondWith(caches.match(e.request).then((r) => r || fetch(e.request)));
  }
});
