
const CACHE_NAME = 'calendario-trabajo-cache-v1';
const urlsToCache = [
  '/',
  '/index.html',
  // Puedes añadir aquí rutas a tus íconos si los tienes en una carpeta
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png'
];

// Evento de instalación: se abre el caché y se guardan los archivos principales
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Cache abierto');
        return cache.addAll(urlsToCache);
      })
  );
});

// Evento fetch: responde desde el caché si es posible, si no, va a la red
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Si encontramos una respuesta en el caché, la devolvemos
        if (response) {
          return response;
        }
        // Si no, hacemos la petición a la red
        return fetch(event.request);
      }
    )
  );
});