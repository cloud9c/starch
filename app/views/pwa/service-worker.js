const CACHE_VERSION = 'v1';
const CACHE_NAME = `starch-cache-${CACHE_VERSION}`;

// Add a service worker for processing Web Push notifications:
self.addEventListener("push", async (event) => {
  const { title, options } = await event.data.json()
  event.waitUntil(self.registration.showNotification(title, options))
})

self.addEventListener("notificationclick", function(event) {
  event.notification.close()
  event.waitUntil(
    clients.matchAll({ type: "window" }).then((clientList) => {
      for (let i = 0; i < clientList.length; i++) {
        let client = clientList[i]
        let clientPath = (new URL(client.url)).pathname

        if (clientPath == event.notification.data.path && "focus" in client) {
          return client.focus()
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(event.notification.data.path)
      }
    })
  )
})


// Install event
self.addEventListener('install', event => {
  self.skipWaiting();
});

// Activate event
self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});

// Fetch event - cache documents for offline use
self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  
  // Only cache GET requests
  if (request.method !== 'GET') return;
  
  // Cache document views and related assets
  const isDocument = url.pathname.includes('/documents/');
  const isAsset = url.pathname.match(/\.(css|js|png|jpg|svg|ico)$/);
  
  if (isDocument || isAsset) {
    event.respondWith(
      caches.open(CACHE_NAME).then(cache => {
        return fetch(request)
          .then(response => {
            // Cache the response for future offline use
            cache.put(request, response.clone());
            return response;
          })
          .catch(() => {
            // If offline, try to serve from cache
            return cache.match(request);
          });
      })
    );
  }
});
