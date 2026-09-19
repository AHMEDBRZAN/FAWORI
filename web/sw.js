/* 📴 Service Worker خاص بفاوري — فتح بدون نت حتى بعد الإغلاق الكامل */
const CACHE = 'fawori-offline-v1';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      .then((cache) => cache.addAll(['./', './index.html', './manifest.json']))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // ✅ فتح التطبيق (navigation): من الكاش فوراً + تحديث بالخلفية إذا فيه نت
  if (request.mode === 'navigate') {
    event.respondWith(
      caches.match('./index.html').then((cached) => {
        const network = fetch(request)
          .then((response) => {
            caches.open(CACHE).then((c) => c.put('./index.html', response.clone()));
            return response;
          })
          .catch(() => null);
        if (cached) {
          network; // تحديث بالخلفية فقط
          return cached;
        }
        return network.then((r) => r || Response.error());
      })
    );
    return;
  }

  // ✅ باقي الملفات (JS/صور/خطوط): كاش أولاً + حفظ كل جديد + تحديث بالخلفية
  event.respondWith(
    caches.open(CACHE).then((cache) =>
      cache.match(request).then((cached) => {
        if (cached) {
          fetch(request)
            .then((response) => cache.put(request, response))
            .catch(() => {});
          return cached;
        }
        return fetch(request).then((response) => {
          cache.put(request, response.clone());
          return response;
        });
      })
    )
  );
});
