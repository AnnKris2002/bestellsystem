const CACHE = 'bestellsystem-v4';
const ASSETS = [
  'index.html', 'manifest.json',
  'Logo_PGmitKranOhneNamen.png', 'IconNordmed.png', 'LogoNordmedNeu.png',
  'PraxisstempelSchlaefke.png', 'PraxisstempelHingst.png',
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS).catch(() => {})));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET' || req.url.includes('supabase.co')) return;

  const isHTML = req.mode === 'navigate' ||
    (req.headers.get('accept') || '').includes('text/html');

  if (isHTML) {
    // Network-first: die Seite kommt immer frisch vom Server, Cache nur als Offline-Reserve.
    // So braucht es nach einem Deploy keinen Hard-Reset mehr.
    e.respondWith(
      fetch(req)
        .then(res => {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put('index.html', clone));
          return res;
        })
        .catch(() => caches.match('index.html'))
    );
    return;
  }

  // Bilder / statische Assets: cache-first
  e.respondWith(
    caches.match(req).then(r => r || fetch(req).then(res => {
      if (res && res.status === 200) {
        const clone = res.clone();
        caches.open(CACHE).then(c => c.put(req, clone));
      }
      return res;
    }))
  );
});
