# GoStory

Flutter ile konuma bağlı kullanıcı adlı fotoğraf ve not uygulaması.

## iOS simülatöründe çalıştırma

```sh
flutter pub get
open -a Simulator
flutter devices
flutter run -d <simulator-id> --dart-define=SIMULATOR_PREVIEW=true
```

VS Code'da iOS simülatörünü seçip **GoStory · Simülatör demo** yapılandırmasını da başlatabilirsin.


Demo modunda kamera yerine çevrimdışı İstanbul illüstrasyonu gösterilir. Deklanşör fotoğraf önizlemesini açar; not yazıp BIRAK düğmesiyle akışı deneyebilirsin. HARİTA düğmesi gerçek dünya haritasını açar: sürükleyerek farklı şehirlere ve ülkelere gidebilir, iki parmakla veya +/− düğmeleriyle yakınlaştırabilirsin. Konum düğmesi başlangıç konumunu açar. Alt panelin başlığına dokunarak veya tutamacını sürükleyerek bölgedeki anıları açabilirsin. Yakınımda / Yeni / Popüler seçenekleri mevcut veriyi mesafe, tarih ve görüntülenme sayısına göre
 sıralar. Panel sayısı görünen harita sınırlarından hesaplanır; karta dokunmak haritayı anıya odaklar. Anı bırak düğmesi mevcut kamera akışını açar.

Harita tüm çalıştırma modlarında OpenStreetMap üzerinden yüklenir; internet gerekir, API anahtarı gerekmez. Demo konumu İstanbul’dur. Diğer bölgelerde gezilebilir ancak anılar halen yerel örnek verilerdir; sunucudan dünya genelinde paylaşım yükleme henüz bağlı değildir. OpenStreetMap kaynak bağlantısı harita ekranında görünür; standart ağ sağlayıcısının yerleşik karo önbelleği kullanılır. [Karo kullanım politikası](https://operations.osmfoundation.org/policies/tiles/).

Firebase şu anda devre dışıdır; not gönderimi yalnızca demo geri bildirimi verir, kalıcı kayıt yapmaz.

## Kontroller

```sh
flutter analyze
flutter test
```

Kullanıcı adı kamera ekranındaki profil düğmesinden veya Profil sekmesinden değiştirilebilir. Yerel profil cihazda saklanır; paylaşım taslakları kullanıcı kimliği ve adını taşır. Sunucu kimlik doğrulaması ve kullanıcı adı benzersizliği henüz bağlı değildir.

## Sekmeler ve profil

Alt menüde Harita, Paylaş (kamera) ve Profil bulunur. Profil düzenleyicisinde kullanıcı adı, galeriden profil fotoğrafı ve Instagram / TikTok / X / YouTube profil adresleri kaydedilir. Sosyal bağlantılar dış uygulamada açılır; OAuth hesap bağlama değildir. Profil ve fotoğraf cihazda saklanır.

Mağaza sayfaları yayınlandığında `--dart-define=APP_STORE_URL=https://apps.apple.com/...` ve `--dart-define=GOOGLE_PLAY_URL=https://play.google.com/store/apps/details?id=...` ile gerçek yayın adreslerini ver. Adres tanımlı değilken ilgili mağaza satırı “Yakında” olarak pasiftir.

Fotoğraf seçimi ve bağlantı açma: [image_picker](https://pub.dev/packages/image_picker), [url_launcher](https://pub.dev/packages/url_launcher).


