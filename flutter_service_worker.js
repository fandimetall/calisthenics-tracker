'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "3b82d652446610d85b256fbada2beeae",
".git/config": "8d1f64056e3a1f923483e39720493293",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "27f11d4f8fa7863cb072cfd4b353c7be",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "3dabce650c5eada62057b53170bc2ccc",
".git/logs/refs/heads/gh-pages": "3dabce650c5eada62057b53170bc2ccc",
".git/logs/refs/remotes/origin/gh-pages": "cfd2dd65f4a11fb8e3782ef7712507ca",
".git/objects/00/96ea277ab846bab3d2d1fe7eeac45cda7eaf75": "ea9c410c0deea68b25c735028ebabf7b",
".git/objects/03/2fe904174b32b7135766696dd37e9a95c1b4fd": "80ba3eb567ab1b2327a13096a62dd17e",
".git/objects/04/3e20586603654966a6a4cd896e05839fc026bd": "b148509455a0edb2c2faff9bda5ce47f",
".git/objects/08/d2c825e2ab44a2a7f23ede2bfc1f558460eec8": "12bff7f4554424407c8487d878ed4a16",
".git/objects/0f/c54ba0a873ccb5b3fc4263e9b5f7977ea4b73a": "2c779b72a2d85bd2b673fac7b13f4bce",
".git/objects/10/0f603cd3b2f07c0e839b6a2bef383f15e4dab3": "e23621ee2d126b1521423f27f7737ebe",
".git/objects/15/94461e4dd711a7a96f6d60823d74f11adef4a4": "ce670845fa8d02860a383ee4f4ffb251",
".git/objects/1b/891536e47ae3b48dea481332f7509c8b62dd31": "0b7d3332d9f915c5fa15f694f29e5d28",
".git/objects/1e/d5f9b7c63b70583afa5d9b07a2c64772374128": "5ad99be220bfa630619b0294a0007d54",
".git/objects/22/e4b9f3258b3251b97465237f4052951f0f7cc1": "e02d51b997003c485137b4cee6527005",
".git/objects/27/b72bbcb1a7b91fb044d2e9d0d6d69db37506f6": "a24cdb422be1ce70af712d93b9f4d123",
".git/objects/29/3f7ddaf5f1bf613e592f43aedb55ae1dc331b1": "c4b027cd68977902dfc0185a2296fc6d",
".git/objects/2c/c1be8e7ed5dabd02f30efbfd3d9d841b4e5e8c": "1a522d2f84449e9c4970687ee0e36013",
".git/objects/2d/c1645658ba91099b8efd892d75dc6239866647": "13c5a3fb58bb12e5b67d829f8445bb78",
".git/objects/31/7cb165dd58dcaad5f0b15dc48fed2ca2db1d26": "68964c601334113da494102250ff4070",
".git/objects/33/31d9290f04df89cea3fb794306a371fcca1cd9": "e54527b2478950463abbc6b22442144e",
".git/objects/34/bdc7eab3a850185e76c7189c9912dff79f7066": "b54d0d886742e75f4dff2a358fbb40d7",
".git/objects/35/96d08a5b8c249a9ff1eb36682aee2a23e61bac": "e931dda039902c600d4ba7d954ff090f",
".git/objects/3a/8bea8d7df0521aaa5a494e6dbf6822b9427c60": "27934cffd8d71ff9981636cdac2b453d",
".git/objects/3c/6318e1c3144f8926f790b7c9889992e9e65f34": "6e7879ab3181914a6ca5d1117911aaf6",
".git/objects/3d/201d00d2829a1319350721bf1fff758b789dae": "3db61d7f1a829f4897a58517d6004be9",
".git/objects/3e/dba3ac2803a093cda80b94c175a5345360a276": "3b18f423b049e3cf45274fb82f447aef",
".git/objects/40/1184f2840fcfb39ffde5f2f82fe5957c37d6fa": "1ea653b99fd29cd15fcc068857a1dbb2",
".git/objects/42/66607cb77838a6c8f70530f2f65f3193e2df98": "8587c0183d3d0390d5cf5a6af6f6e1cd",
".git/objects/44/d98967bddb7ef2562920f3715e233e0977820f": "28ae732d1a81276f69940a6b11510595",
".git/objects/46/059861e7a4218b387bde250179033de6b4e51a": "f8a06bce8dc5e855b9f36accdaaa3ac7",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/47/3a9252d7ce1d80746861b996d360d07626528d": "04d4eda96e7823e487ccbc6d9b2764cf",
".git/objects/47/95fa14a80e1ff13e50596f5d8a2b99ba36cdcb": "fd2d40013a9cce1e834fcd82d78f8891",
".git/objects/47/ce613e9964f4509f93212c4e2381137ceb7141": "3d4bbc7697e6a86a32886cb1e5bace0d",
".git/objects/48/64caff8ec57b3afad1e149107d931a0dc816ba": "738800b6a204684cb335e1b67f601281",
".git/objects/49/33734bdb48faa599a0b590126782ed001b96b9": "45813047420a2d128ca7a829f35d473d",
".git/objects/49/d4c64497bbd8e93666188658ac02588e5d9f62": "5f32a2b54ecf8329b26d80b9a43ebd0e",
".git/objects/4a/63a18d998d3e30dee8dbad0eb58735696f289a": "ed7aa5aa04041cf0721b5f157d0b9c17",
".git/objects/4c/6628ee303a854bdcf1cec277acd96d5b0a6a64": "0b61f9efa08f848b46f0febb426c7c71",
".git/objects/4e/a8d2d50fcdd67aa04e7c78261bc4322d32a0a2": "3775c3726f2651ad09f75f2cfa3d26ff",
".git/objects/4f/02e9875cb698379e68a23ba5d25625e0e2e4bc": "254bc336602c9480c293f5f1c64bb4c7",
".git/objects/4f/36f4670337d52305354fc88c9c17b2f58fdaef": "b5aed0a07689bc9956dc690787b86b52",
".git/objects/4f/6a1201dda971e1fb802716a540ecf838e520d0": "e1429de373ced223074b5570afe710d5",
".git/objects/53/6a7930b10e673bc49b9e5baeef0cac7ec733f0": "489887694a3f54781f0dbd2282eab794",
".git/objects/55/59c4877d901a3f6c85dae50fbcc9ba0bcbbef4": "07118c88424b7ae7b6a8f683c815c531",
".git/objects/57/7946daf6467a3f0a883583abfb8f1e57c86b54": "846aff8094feabe0db132052fd10f62a",
".git/objects/57/859bf32a002965a1dc8909fcd0ffa0b8f02d45": "105667920714ea1722f76a137c882c3a",
".git/objects/57/891590d6c6ffb587f89d11d607d28f5e2a4b1c": "4f4fd39b546428d8650549a2fa33aa39",
".git/objects/5c/482e99ef8c82acb4d6afd5607ce6f20cc16a12": "1c3d0c8a0f82b4c28214d694092cf12f",
".git/objects/5f/bf1f5ee49ba64ffa8e24e19c0231e22add1631": "f19d414bb2afb15ab9eb762fd11311d6",
".git/objects/60/169d58012f85a435b9b68be42da8e09d71ad39": "ea459273eb13e3d8aae0b79247b95ffe",
".git/objects/64/5116c20530a7bd227658a3c51e004a3f0aefab": "f10b5403684ce7848d8165b3d1d5bbbe",
".git/objects/64/e340805a3485f9e47927b709cfbdfcbaa7f3f0": "7d79174becb940f763bd34da17d1e40a",
".git/objects/67/6b53b4c580d3777bbfcbc966e5296e7db7a3ed": "a1f60e0f8b05f2e71a51f66c44e78d2a",
".git/objects/68/ebc94af873c4dab9e4011adf78c82ec484ad06": "fcd3f3fe4efa0ef58641f57043512f26",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6e/299e83ad8f82826203c4c85678691be1abb12d": "71bb6d8a557100f80653c56c21dc5974",
".git/objects/72/dff3b6fa72017b3fa8e5f948ebcd9e9c15b5be": "cbbe5c35ce52ea43b3a8143e0fd0f5ca",
".git/objects/73/879de3048473e29989d1d404df1ad289b2985a": "d5b0f459c60e86cf2e17ce87899b6350",
".git/objects/7d/10ced6a04f662500ee6969e67ed131e6826d3a": "843182ec9c4100e95b93d3dc99ddc31e",
".git/objects/7f/101accdf2ee828061fd010be9c8ee895d13f4a": "f603b22a27e11f8a977ff3b88a9f448c",
".git/objects/7f/ffbaddcab4f9fd3daa75b77c0d748940bd073d": "ae60f758f1201fbcfcc221f2ecc90ed1",
".git/objects/87/3f39b3b6a7e0f441bdfeaa113163461a161a2b": "ba1e7284fcdff6f8f3d32fffae34ebf1",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/51a9b155d31c44b148d7e287fc2872e0cafd42": "9f785032380d7569e69b3d17172f64e8",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/91/1d22364e31f7f0493a82a338c8d21cbeac16ae": "2f946cbe112a3122b7bf206b5d372854",
".git/objects/91/4a40ccb508c126fa995820d01ea15c69bb95f7": "8963a99a625c47f6cd41ba314ebd2488",
".git/objects/92/60aa190da59e5542f00dcff71a7b622a25ae7b": "a5fa496f03a6233e76f1edc0533da841",
".git/objects/93/9c1a49aa3eaca7b767c7fb954354bf29ff8a70": "ba8614cb70a4cd1de94633e736b03fb1",
".git/objects/93/be7fd9b9dcdd8564dafd7040a0c8c8f68d4080": "b27ff257c793a735fc818ff37f392ff9",
".git/objects/9e/0910407283d57c34dc4a1b188e5f59e7ef2e16": "2f2c5adc1a3dc4284c0607567a438b87",
".git/objects/9e/4f979584588bee0ff2f06bdafec2ade799ec6e": "8645dbb9cd446e8c703d375af37adc48",
".git/objects/9e/6ba92d6ab6efbba9a25852808a1699dd317b53": "daf6346a4992e223d8fb943779c76204",
".git/objects/a3/1fe507ad6e60926c7cc05aa277e21139d8594b": "35f1cdc415f7ab57103cfbd87990d88b",
".git/objects/a5/de584f4d25ef8aace1c5a0c190c3b31639895b": "9fbbb0db1824af504c56e5d959e1cdff",
".git/objects/a5/e2f8faaeff82c411deccecafecb2c2d38cb80c": "cfd633eb223a95278ba2f7c9bbbb3159",
".git/objects/a8/8c9340e408fca6e68e2d6cd8363dccc2bd8642": "11e9d76ebfeb0c92c8dff256819c0796",
".git/objects/b0/394ede28b4f59487554d263fdffbe274fe81e2": "cb271ad1b1c8c31774d1969556ce01bd",
".git/objects/b4/53ac3e6678f70379af1d73622a1cb964a69acd": "be07f786ee306044183b1a7145639d7e",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b7/e319a63c25eada787901be8dfec5658a86d267": "0c3e75871d2a9241c61b45e54bc33ff7",
".git/objects/b8/99aec19bcdd4bd76eda8e6d24cc59514350cee": "de62605cb333ca5f03cc62fe6a33c4ad",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/bc/b3926e3e3862ba744810262a5e05e446f17775": "23d05ae0ca5a83e46a06b7b5ea82867a",
".git/objects/bd/56e14069d4146a2edea01dc61f01b6b5f5031b": "33ae459decfd2e73de9d904c4ff0c7c4",
".git/objects/bf/37525569eeb2cee79de5227263dc82ef12f227": "d3185b51f3ceb522825bc1bd69a1481d",
".git/objects/c0/fe6738cbd389a0a596e04183a4c6a215d1f6fa": "634a44a25edd51977e367d479a47c52a",
".git/objects/c1/e2cbddff38a0fc08913634e2b7bf936f66a408": "85deb7204b86f92a64d54c1e743e648f",
".git/objects/c3/775820f68de7cb368934d9c29b5ed93f117eeb": "5e5af1a4be43e2e56e5b0c68b17af484",
".git/objects/c5/3ec3eb90d0239775c55f215bf240d91274bcc0": "45741a6e99bc3e7465c8c12d3c3e7cce",
".git/objects/cd/3a9d8c281f7267020290c9ec570f8d83136bb0": "7a562e59b5e606fd290b307fbb1c7d94",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d8/ded418b0b5f6872ca4994dcba9a751ec2ea0a4": "2218df688904a9d4ad402616aa96f926",
".git/objects/d9/3952e90f26e65356f31c60fc394efb26313167": "1401847c6f090e48e83740a00be1c303",
".git/objects/db/bac11adcd24ba77790cd9672a3dadbf3fd1ca6": "638f9f3bcbccbfb21b9d1401374021bb",
".git/objects/df/f386df0e359025981687a2248fd21c2392fc45": "3fa90917e16170bb910b52bbb4ec08db",
".git/objects/e7/98c01e0e8ede35d2640af56d4a905c1374f0d4": "06c0dc7205511dc63813321bfad687bf",
".git/objects/e9/8c19bf264b54c2124266f08482940da2031a00": "7795aaf4792c42967912857cfd9e57dc",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/eb/7ee7938f6d877a8095f1a882f93ae3b814e6e1": "40e683c3b34dcb0b4f4d3a55e8b76586",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ef/b875788e4094f6091d9caa43e35c77640aaf21": "27e32738aea45acd66b98d36fc9fc9e0",
".git/objects/f0/89ba0b72a0511ced59c9cb3aeaaeb7fb9d1eea": "2c61f42e92a35e89b3871529b56614ef",
".git/objects/f1/5c003842d0c888e7160cfbef735787e8395a56": "4e82b03538c7709f2c16f37277a961fe",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f3/709a83aedf1f03d6e04459831b12355a9b9ef1": "538d2edfa707ca92ed0b867d6c3903d1",
".git/objects/f3/7633dd5ac39ea851ab08cf196a0b781864c9ad": "e1aa863f4bc750a4d62108d1e2bf18bd",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f7/06ccfe43e6b0d83791c7a370a0ea5c40760ad6": "d1b7f48b0b94752345eef410cf243fa8",
".git/objects/fa/0a13dbdfb006b5bc6c9bf7afccab3dd1ee8e0d": "85a0e40c7f9e02bbad79843dfce1daea",
".git/objects/fb/084f5df969df3720d40cb415d2af85656fd400": "5d057986f7130e4706d2224a8073bbe1",
".git/objects/fc/283ded99309f48be0976e628a3f639e4c45cb7": "a3139083e115b19ff62b81bcbf4e1e13",
".git/objects/ff/b9285ac0dac9a9aa64a2307bc24d36b91881ab": "047580ced0cf418bdf11ceaacea81d99",
".git/refs/heads/gh-pages": "c8f5c3ed2bbf2a65388c2794a77e0442",
".git/refs/remotes/origin/gh-pages": "c8f5c3ed2bbf2a65388c2794a77e0442",
"assets/AssetManifest.bin": "47397f2f45536d5d76d8a9801e5b8f9b",
"assets/AssetManifest.bin.json": "fc4a10f4d207e3ab9aa2c855e59aab2e",
"assets/AssetManifest.json": "aeeea675a6c5ce98e04041b2adb2d4e4",
"assets/assets/data/exercise_library.json": "0d9bcab49ab543b26c9fe47557c1e1b0",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "856cce47a1fd789320098d8df8ab85dc",
"assets/NOTICES": "cc281b45767c65900b44c96af404ff26",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "37e7f8ca38aaa520da7b47997391a01f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "47cfa7f36a8c7cc5773acffa8d9493c4",
"/": "47cfa7f36a8c7cc5773acffa8d9493c4",
"live_deployed_screenshot.png": "1a23d860628324d9d3cf2b6d57579ee6",
"main.dart.js": "44ed3f5c1c7a12ccb2a9a3f5164857f8",
"manifest.json": "2e0f4314efbf7ad29e2e46046878d518",
"vercel.json": "725be581131571029d5ea0412dab46d4",
"version.json": "00d7331e4d632291801552b736bb0d89"};
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
