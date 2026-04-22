'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "9b9ddcfe14a5ef8986bc56476676db48",
"version.json": "b98ca24f637d04c5d9079ca04abe1170",
"index.html": "a8dca431262162a931ef30565eaa5d8b",
"/": "a8dca431262162a931ef30565eaa5d8b",
"main.dart.js": "54f347ff9f433909d3646dc29c192fe2",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "dae8da7bf0c221dad35d087bc388d7b6",
".git/config": "38881ccff4dc4e249623736f3cd97a15",
".git/objects/59/7f381335f75889953fad47beca59f3fbe4a4fd": "084d98b8fbba3894e3c5eaf7f7e46615",
".git/objects/66/aeaa5799037445c2f4777fc04f0e8ebdbafef4": "fa683bf0dd03592e424390d33a5d5cbc",
".git/objects/3e/dbf43054c180581c9750877314ca542a0601c1": "4440c497e990ead69f265858d1f21706",
".git/objects/68/1249e302927172ea031fa0a36f0f4aa7a11466": "19b3b9476d0ccca685f9c249e238eb80",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/35/0e12cdfe99b63842dd321fb1d3eb41f55c8f45": "67587a838272402730b608794508fec8",
".git/objects/56/31aa45e6aa5e8cb9dc45b44a8791e670f1c214": "31bb9086f55a172a13364a2101584b6b",
".git/objects/93/3c5a7f8cb1627d40f2d5c7bad94ba2b0ffacb3": "dcccd7b6680f2ce8d5979e52f187db2b",
".git/objects/34/90031d493374d0bee8fc76cefd7996cb840c0e": "39f25ab38dd4b550daa6b31b04720c50",
".git/objects/5a/86d56281dff93510170c8d067d7fddd3e0306f": "cfd741ee06b012b7a5f8d426e22f5888",
".git/objects/b5/513908da38aa3bb44f72845d72e984b056b835": "5a3748bd6e51c9a3b53c9ae7a0be93b7",
".git/objects/ac/c94a4bbe255a5994ad9962822389cd5901d32d": "bed0fbbc8c5274c8121c5d2e0eb9787a",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/da/0d5aa44a8c93eda469f7a99ed8feac32d5b19d": "25d25e93b491abda0b2b909e7485f4d1",
".git/objects/da/7f91292168946cab973458bb4a0b7b0517ef93": "7f03acf27f1b23d2df5400f97a39a328",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/bc/52d5a3d7c5edaaa3f1279892f8cf61425e06ca": "a7a1cb1c352d34c5f7169458670a8989",
".git/objects/d8/8128adaad90d2fd7cdabe7b36eaaaed0d3a25b": "3d15963af0d77c1cd40702fb7c18fa93",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/c0/66122866869779f10053544722adf5489b9594": "c9d75fa2afb343c6a5f4088ca11e8e53",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/e3/738e94e46bab2e7f7fc6eae22548692719d78a": "7646e8c5611c3d43ea43d6f6ac19c08d",
".git/objects/e3/3fee8e52058e57cd49d6f1934c4e3e2cdab7dd": "dfc4155c17a1ed94dd19564abc5143e9",
".git/objects/cf/3d4cccb704a755b464c3a1e023d9ad1b2a52da": "c20d0494cea27ba9bd34716a43ebb8e3",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/fe/365083e9365559e628e045b30f23fb7373e47d": "77ae8d03e9aafa78c27b67b8de6ff490",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/objects/c8/ee899709e4790f18a8c853803b0385bc28bb04": "80dfac8f6f9fe0dc66710b021d754568",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/ec/9b9c743a2204d28efde6693fda867630343946": "1c0d9593cf1d4c95ccb21c3b8dd2d8fa",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/7c/ebc6365d768dc833ac1eec61e7e66dbdedfc14": "dbd462320b88f61efce6a901023f70a0",
".git/objects/74/7c0395ba193d3853beb3ac74ee99187c652def": "5afd35010f655d0d20742a261e826723",
".git/objects/1a/072330a807ba9f247b6b51e234d8ac7c7c9ef8": "8936d95ee2ff16f68a5b241773feb651",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/19/5d2c14b416c6ffbdb531a8c644bae5bf385770": "448fcd8404195ad912343ea58884ffe2",
".git/objects/4c/d6f7d32b10472bdf027e5fde02247dc3454e75": "b818f9a2310e96dda8c4060aa6149d86",
".git/objects/26/0942760762a90b6ff6d531b334280a0d23656b": "ad380aa9cce929d41632d2a1e1156b81",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4d/e12622f19ef3b0b3d663202e9d639327fcd276": "a8a4b9377805b1349570d86a47b9627d",
".git/objects/44/cc904c077982427acb8a0c3c8227b9c93c47b5": "7f96c44efb0bd6c473c15190f356de0a",
".git/objects/44/26bcaec34f1fc01bb8931bf19f05ddc96d3701": "9552dcbe600954e2471043c405f1b238",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/6b/04c53ca61a936ca26364b833e7486c1984d561": "e9e5ee1a7553951e4a24fcd7d264a870",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/00/dd88d0704a935f6b68c274192acb4d49937b22": "72012681d2a928c115f5f3df935687b6",
".git/objects/36/4c2f06725aea930b6c969210fd78add0e40732": "ee4faa23da428de432f4565f2b241f77",
".git/objects/96/f4f5fb5933611e3155c1a36d956438f3c67339": "c55fff0c1ec971d08afa43964eea1c95",
".git/objects/98/c1c3d5b6f7b5452964b591fc4a0411ac2b5722": "28a456272ca9936adfc436942634b0ea",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/5e/da9ec96e91ba8e4a418e53af4483766e245d6d": "339f0cfcef1c87a0ca364f5c6a9052ca",
".git/objects/6c/ea55ef490d4e5c42b82fafc643c078a5630f47": "3dcbc2d490852ce4cd85b1f354d52234",
".git/objects/0f/c3283bfb8a08b1b8274f4b39e6568d8e702a41": "80fc3747616eaa504ab4e5051f3e5308",
".git/objects/0a/feaf756605b1317854af362b61befedb7bdc8d": "281b4031604fc310cdc45b58b99fb2ea",
".git/objects/64/c2ec44722aafe215ebcefb154acc3ef133cd84": "0f99e8cff3a8d7c38f38cc3f6b03b36e",
".git/objects/bf/bab9c3bd2c58a29f06a819cec6530a2238fafb": "f64ef22e63962bc9916f265eb3b74027",
".git/objects/d3/85be39f801c7ab080378281ccdbec4b08420b3": "859dceb68ed852a481be4d5dd4801127",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/b6/e1380dafec7f2f922a963e4dc73b97428250c1": "6b43bc34b583e408de0854fde6df2a98",
".git/objects/d5/76255c06baa3dff7367b87b433ebd48d9e0de5": "a581c4313380d72ab4c1370b57143e39",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/db/f8db82740ef28ef003dee6a04b73ed1dd5baae": "3d37bac09784ffc6ecec2e9375232e73",
".git/objects/a8/571df0eab4ee74ff06b4bb86dc8199a14ef407": "2da24910f2edf5dd342edbff44829176",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/279fdbc0302795290a001e023d892318fa9cc3": "6978595a9df1e1ae5f8916ea220a55a8",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/e1/4754b34228c0d34e441e7a920bf31eb0388742": "6a6f434e01d23862d9a138aea46844af",
".git/objects/e1/56c99adfdb37641a21f3b29e958b2648578a52": "a415a690d07cc4d5b5a2571dd3612b13",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/e7/252aedf3d2e53e16bafa19d355e797f8f3bb57": "3f296fcad493322d6ebb74553168b279",
".git/objects/2c/3359d076a37db67b6563305b80e99646830479": "9b795f2006ce11baaeb0a6b7abd7e2ae",
".git/objects/48/1e6c760208cc3d785bd10a4acce7a32f9a6191": "7e8eba070230f7122130dd5f0a1ce301",
".git/objects/24/21d4b65addf92c592f202f8ba959c12f8e401e": "be45a8e40ac68313c48f97721f8ca418",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/8c/c01ac7b522f5bcd9b2ca84c0f2a2d6b3824f38": "20fdbe5d811e93bb132cfb1220d0b4ff",
".git/objects/76/38ab074f46818a560403b26308dc2538f650a6": "52f546b47386a64a28c11d983fa8841e",
".git/objects/49/e1318ba361bade834d3357e6d6f8c53c0f3a97": "86882e76b17b5fdb43a7d1bd9afa9e25",
".git/objects/47/1f7d47f927d43f50215bec8c003d7e517560b3": "7af75f92d612504c7a3d21c1c23765b4",
".git/objects/78/b5789162f0e9e471892408e625ac55cd869b4a": "80371008918799e18960ca0a060a3d57",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/22/7e7874cddcc999c82d6c3466a5a58ec9154da3": "650d9344f6817c05f1ec822ccf1e8e4f",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "2b1c0ac6ecaf8b2d1eac5fbde868d8a5",
".git/logs/refs/heads/main": "82367789199e79d65a6bb47c45022d94",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/main": "cb69c8301419e789884d360203086a7a",
".git/index": "a46969f99dd95073dda9c0ebd22870b2",
".git/COMMIT_EDITMSG": "fa89b177acbe5021645f016af84f4dbe",
"assets/AssetManifest.json": "ad1080fa4a69c52890f3a4ed4c45fdf3",
"assets/NOTICES": "0be5f199818ad2376497b9045c8c6277",
"assets/FontManifest.json": "a09d6b34e4a0cfc511e06bc65d2accf4",
"assets/AssetManifest.bin.json": "abb0a2cf5c9e4a00c797774a244499b2",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "2fc51bf1a256bb9192970c4b00a3dcd6",
"assets/fonts/MaterialIcons-Regular.otf": "159f0101ae47b113fa74141b083aece6",
"assets/assets/images/sq-tl.svg": "de8973360780c73b456159aa1d956c2c",
"assets/assets/images/tl-sharp.svg": "bf58f90902c1119ed9ee100ef8a04822",
"assets/assets/images/L-bl.svg": "c2d3fa15a4cb8b3d904a1c7a1d6d599c",
"assets/assets/images/L-ctl-b.svg": "d98b98bc02a324062a5c4c846eceaa8d",
"assets/assets/images/s-br.svg": "337573cc9fd35811dc3115f63032f97e",
"assets/assets/images/S-trp.svg": "366d5eb2853022df0a4389b2b781de99",
"assets/assets/images/L-br.svg": "9a7a211e1b9d9f93b4e98f59136a400f",
"assets/assets/images/sq-tr.svg": "725059cf90646b184044750ebda6daf4",
"assets/assets/images/sq-bl.svg": "a29e6fafc098fd8f1e24da1a9bc77dcd",
"assets/assets/icons/drawer.svg": "6e1c5993c5c44da02fc3929f20e28682",
"assets/assets/icons/google.svg": "fec98641440db368b9fda1be24c1a134",
"assets/assets/icons/logo-full.svg": "324479a02c7e036337f40994fe61757c",
"assets/assets/icons/google.png": "fec98641440db368b9fda1be24c1a134",
"assets/assets/icons/logo-D.svg": "5676c2fc124b391baa5dbdc1c545a13d",
"assets/assets/fonts/Manrope-Medium.ttf": "aa9897f9fa37c84d7b9d3d05a8a6bc07",
"assets/assets/fonts/Manrope-Regular.ttf": "f8105661cf5923464f0db8290746d2f9",
"assets/assets/fonts/Manrope-Bold.ttf": "69258532ce99ef9abf8220e0276fff04",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
