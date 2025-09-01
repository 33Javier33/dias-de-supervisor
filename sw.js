const CACHE_NAME = 'calendario-trabajo-cache-v2'; // Cambié a v2 para forzar la actualización
const urlsToCache = [
  './',
  './index.html',
  './manifest.json'
  // El navegador cacheará los iconos automáticamente cuando los necesite.
];

// Instalar el Service Worker y cachear los archivos principales
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Cache abierto y listo para cachear archivos.');
        return cache.addAll(urlsToCache);
      })
  );
});

// Activar el Service Worker y limpiar cachés viejos
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cache => {
          if (cache !== CACHE_NAME) {
            console.log('Borrando caché antiguo:', cache);
            return caches.delete(cache);
          }
        })
      );
    })
  );
});

// Interceptar peticiones y servir desde el caché si es posible
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Si la respuesta está en el caché, la retornamos.
        if (response) {
          return response;
        }
        // Si no, hacemos la petición a la red.
        return fetch(event.request);
      }
    )
  );
});
