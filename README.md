# GoStory

Flutter ile konuma bağlı kullanıcı adlı fotoğraf ve not uygulaması.

## Terminalden çalıştırma

Komutları `pubspec.yaml` dosyasının bulunduğu proje klasöründe çalıştır. Flutter SDK'nın `bin` klasörü PATH'te olmalı. iOS için macOS ve Xcode, Android için Android SDK ve bir emülatör veya bağlı telefon gerekir.

```sh
cd /Users/barismerttarlaci/Downloads/gostory
flutter pub get
flutter devices
```

Başka bir bilgisayarda `cd` yolunu kendi GoStory klasörünle değiştir. `flutter devices` çıktısındaki cihaz kimliğini aşağıdaki komutlarda `DEVICE_ID` yerine yaz.

### iOS simülatörü (kamera donanımı gerektirmeyen demo)

```sh
xcrun simctl list devices available
```

Bu bilgisayarda Xcode Device Hub penceresini aç:

```sh
open /Applications/Xcode.app/Contents/Applications/DeviceHub.app
```

Xcode 27'de görüntüleyici Device Hub'dır; eski `open -a Simulator` komutu bu kurulumda çalışmaz. Başka bir bilgisayarda `open -a DeviceHub` kullanabilirsin. Xcode 26 ve daha eski sürümlerde `open -a Simulator` kullanılır. [Flutter resmi iOS kurulum rehberi](https://github.com/flutter/website/blob/main/sites/docs/src/content/platform-integration/ios/setup.md).

Kapalı bir simülatörü başlatmak için listeden kimliğini al:

```sh
xcrun simctl boot SIMULATOR_ID
flutter devices
flutter run -d SIMULATOR_ID --dart-define=SIMULATOR_PREVIEW=true
```

Bu bilgisayardaki iPhone 17 Pro için doğrudan çalıştırma:

```sh
cd /Users/barismerttarlaci/Downloads/gostory
flutter pub get
open /Applications/Xcode.app/Contents/Applications/DeviceHub.app
xcrun simctl boot 5E6DD63D-CAF0-4C80-9FC9-F27F2FCAC8EA
flutter run -d 5E6DD63D-CAF0-4C80-9FC9-F27F2FCAC8EA --dart-define=SIMULATOR_PREVIEW=true
```

Simülatör zaten açıksa `boot` satırını atla; kimlikler bilgisayara göre değişir.

### Gerçek iPhone / Android telefon

Telefonu bağla. iPhone'da bilgisayara güven ve gerektiğinde Geliştirici Modu'nu aç; Xcode'da `ios/Runner.xcworkspace` için Signing & Capabilities altında kendi geliştirme takımını seç. Android'de USB hata ayıklamayı aç ve bağlantı iznini kabul et.

```sh
flutter devices
flutter run -d DEVICE_ID
```

Gerçek cihazda `SIMULATOR_PREVIEW=true` verme; kamera ve konum izinleri uygulama akışında istenir.

### Android emülatörü

```sh
flutter emulators
flutter emulators --launch EMULATOR_ID
flutter devices
flutter run -d DEVICE_ID
```

Emülatör kimliği ile çalışan cihaz kimliği farklı olabilir; `flutter run` için `flutter devices` çıktısını kullan. Kamera yerine demo akışı istersen son komuta `--dart-define=SIMULATOR_PREVIEW=true` ekle.

Çalışan Flutter terminalinde `r` ile hot reload, `R` ile hot restart, `q` ile çıkış yapabilirsin. Chrome hedefi bu projede desteklenen mobil çalıştırma yolu değildir.

VS Code'da iOS simülatörünü seçip **GoStory · Simülatör demo** yapılandırmasını da başlatabilirsin.

Demo modunda kamera yerine çevrimdışı İstanbul illüstrasyonu gösterilir. Deklanşör fotoğraf önizlemesini açar; not yazıp BIRAK düğmesiyle akışı deneyebilirsin. HARİTA düğmesi gerçek dünya haritasını açar: sürükleyerek farklı şehirlere ve ülkelere gidebilir, iki parmakla veya +/− düğmeleriyle yakınlaştırabilirsin. Konum düğmesi başlangıç konumunu açar. Alt panelin başlığına dokunarak veya tutamacını sürükleyerek bölgedeki anıları açabilirsin. Yakınımda / Yeni / Popüler seçenekleri mevcut veriyi mesafe, tarih ve görüntülenme sayısına göre sıralar. Panel sayısı görünen harita sınırlarından hesaplanır; karta dokunmak haritayı anıya odaklar. Anı bırak düğmesi mevcut kamera akışını açar.

Harita tüm çalıştırma modlarında OpenStreetMap üzerinden yüklenir; internet gerekir, API anahtarı gerekmez. Demo konumu İstanbul’dur. Diğer bölgelerde gezilebilir ancak anılar halen yerel örnek verilerdir; sunucudan dünya genelinde paylaşım yükleme varsayılan yerel modda kapalıdır. OpenStreetMap kaynak bağlantısı harita ekranında görünür; standart ağ sağlayıcısının yerleşik karo önbelleği kullanılır. [Karo kullanım politikası](https://operations.osmfoundation.org/policies/tiles/).

Firebase varsayılan olarak devre dışıdır; anılar ve profil cihazdaki yerel arşivde saklanır. Bulut kurulumu için [yayın rehberini](docs/release/README.md) takip et; platform Firebase dosyaları ve sunucu kuralları hazır olduğunda çalıştırma komutuna `--dart-define=FIREBASE_ENABLED=true` ekle.

## Kontroller

```sh
flutter analyze
flutter test --dart-define=SIMULATOR_PREVIEW=true
```

Kullanıcı adı kamera ekranındaki profil düğmesinden veya Profil sekmesinden değiştirilebilir. Yerel profil cihazda saklanır; paylaşım taslakları kullanıcı kimliği ve adını taşır. Varsayılan yerel modda sunucu kimlik doğrulaması kullanılmaz; kullanıcı adı benzersizliği garanti edilmez.

## Sekmeler ve profil

Alt menüde Harita, Paylaş ve Profil bulunur. Profil düzenleyicisinde kullanıcı adı, biyografi ve galeriden profil fotoğrafı kaydedilir. Profil ve fotoğraf cihazda saklanır.

Mağaza sayfaları yayınlandığında `--dart-define=APP_STORE_URL=https://apps.apple.com/...` ve `--dart-define=GOOGLE_PLAY_URL=https://play.google.com/store/apps/details?id=...` ile gerçek yayın adreslerini ver. Adres tanımlı değilken ilgili mağaza satırı “Yakında” olarak pasiftir.

Fotoğraf seçimi ve bağlantı açma: [image_picker](https://pub.dev/packages/image_picker), [url_launcher](https://pub.dev/packages/url_launcher).


Koyu harita filtresi, ekran düzenlemeleri ve alternatif CARTO tile yapılandırması: [görsel düzenleme rehberi](docs/dark-ui-refresh.md).
