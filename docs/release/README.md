# Yayın hazırlığı

## Mac üzerinde etkileşimli önizleme

Simulator arayüzü bulunmayan Mac kurulumlarında uygulama ayrı bir masaüstü penceresinde çalıştırılabilir:

```sh
flutter run -d macos --dart-define=SIMULATOR_PREVIEW=true
```

Bu hedef yerel kayıt ve örnek keşif verilerini kullanır. Fotoğraf eklemek için galeriden ekle düğmesi Mac dosya seçicisini açar; masaüstü kamera desteği yoktur. Mobil Firebase/APNs doğrulamasının yerine geçmez.

## Üretilen dosyalar

- `assets/brand/icon.svg`: düzenlenebilir GoStory işareti. Flutter şablon ikonları iOS ve Android için değiştirildi; açılış ekranları aynı renk ve işareti kullanır.
- `screenshots/*-sample.png`: gerçek ProfileScreen ve PreviewScreen widget’larından, açıkça örnek veriyle alınmış iOS/Android ekranları. Yer tutucu metin veya yapay uygulama ekranı değildir. Mağazaya göndermeden önce yayın cihazında, son görünüm ve gerçek izin/konum koşullarıyla tekrar çek.
- `store-metadata.tr.md`: Firebase etkin sürüm için Türkçe mağaza metinleri.
- `privacy-policy.tr.md`, `terms.tr.md`: gerçek uygulama davranışına göre yazılmış yayın öncesi taslaklar. Yayıncı/iletişim, saklama süreleri ve hukuki hükümler tamamlanıp kendi HTTPS adreslerinde yayımlanmalı.

Üretim komutları:

```sh
flutter test tool/generate_brand_assets_test.dart
flutter test tool/capture_release_screenshots_test.dart
```

## Firebase kurulumu

1. Firebase konsolunda `com.gostory.gostory` kimlikli iOS ve Android uygulamalarını kaydet. Android için `android/app/google-services.json` ekle. iOS için `GoogleService-Info.plist` dosyasını Runner hedefinin Copy Bundle Resources bölümüne ekle. Bu proje henüz bir gerçek Firebase projesine bağlanmadı.
2. Anonymous Authentication, Firestore ve Storage’ı etkinleştir. Fonksiyonlar ve Storage için uygun faturalandırma planını yapılandır. Firestore veritabanı bölgesini yayın tercihine göre belirle; fonksiyonlar `europe-west1` kullanıyor.
3. APNs anahtarını Firebase’e ekle, Apple App ID/provisioning profilinde Push Notifications ve App Attest desteğini ayarla. Xcode Runner entitlements dosyası APNs development alanını içerir; dağıtım imzalama profili production yetkisini sağlamalı. Android POST_NOTIFICATIONS izni manifestte vardır.
4. App Check için Android Play Integrity ve Apple App Attest/DeviceCheck uygulama kayıtlarını yapılandır. Debug cihazların tokenlarını yalnızca geliştirme projesinde kaydet. Firestore, Storage ve Authentication için desteklenen enforcement ayarlarını konsoldan aç. Kodda provider etkinleştirmek konsolda enforcement açmakla aynı şey değildir.
5. Sunucu kurallarını, indekslerini ve fonksiyonlarını dağıt:

```sh
npm ci --prefix firebase/functions
npx firebase-tools@14 deploy --project YOUR_PROJECT_ID --only firestore,storage,functions
```

6. Firebase etkin bir build üret:

```sh
flutter run --dart-define=FIREBASE_ENABLED=true
```

Varsayılan build yereldir. Anılar ve silmeler dayanıklı kuyrukta saklanır. Firebase başlangıcı başarısızsa kayıt kaybolmaz; Firebase yapılandırması düzeltildikten sonra yeniden başlat. Bağlantı değişiklikleri ve 30 saniyelik aralık yükleme denemesini tetikler. Kamera/önizleme/profil akışındaki yerel kayıt iyimser güncellemedir; yükleme bitene kadar bulutta yayımlanmış sayılmaz. Eski arşiv kayıtları otomatik yayımlanmaz; görünürlük düğmesi onları kuyruğa alır.

Firebase anonim oturumu cihazda korunur; yeniden kurulum veya kimlik verisi kaybı için hesap kurtarma henüz yoktur. Kullanıcı adı benzersizliği bu sürümde garanti edilmez. Profil fotoğrafı cihazda kalır. Kullanıcı profilindeki anı bağlantısı haritada seçilen anıyı açar; tüm kullanıcının arşivini listeleyen bir sunucu profili sayfası henüz yoktur.

Oluşturma yaşam döngüsü `memory_creation_started`, `memory_created_local`, `memory_creation_failed` olaylarını uygulama içi stream’e ve debug loguna verir. Olaylar not, fotoğraf, koordinat veya kullanıcı/anı kimliği içermez; Firebase Analytics gönderimi yoktur. Yerel kayıt olayı bulut yayını anlamına gelmez.

Görüntülemeler oturum kimliği başına tek ziyaret olarak sayılır. Bulut sayaçları Cloud Functions tamamlandığında güncellenir. Yerel beğeni/yorumlar sadece cihazda kalır; Firebase etkinleştiğinde eski yerel etkileşimler buluta taşınmaz. Yeni anı kayıtlarının kuyrukta yüklenmesi uygulama çalışırken denenir; işletim sistemi tarafından sonlandırılan uygulama arka planda upload çalıştırmaz.

FCM yorum/yanıt ve yakın anı bildirimlerini sağlar. FCM otomatik başlangıcı platformlarda varsayılan kapalıdır; açık izin ve etkinleştirme eylemiyle açılır. Bildirim ekranındaki açma/kapatma tercihi kalıcıdır; token yenileme ve uygulama yeniden açılışı desteklenir. Yakın bildirimde son izinli konum kullanılır; 24 saatten eski konumlar eşleştirilmez. Uygulama görünürken gelen bildirim snackbar gösterir; açma eylemi veya bildirim dokunuşu ilgili anıyı açar. Teslimat garanti edilmez; Firestore/FCM tekrarlarında bildirim çoğalabilir. Fiziksel iOS/Android cihazlarında APNs/FCM ve App Check doğrulaması gerekir.

Özel fotoğraflar Storage SDK ile yetkilendirilmiş olarak alınır; kalıcı public download URL üretilmez. Storage fotoğraf byte önbelleği kimliğe göre ayrılır ve en fazla 12 fotoğraf tutar; HTTPS görseller CachedNetworkImage ile önbelleğe alınır. Harita önbelleğinin başlangıçta uygulanacak hedef sınırı 128 MiB’dir; çalışan oturumda geçici olarak aşılabilir. HTTP tazelik başlıkları korunur, toplu/offline karo indirmesi yapılmaz.

## Testler

```sh
flutter analyze
flutter test
flutter test --dart-define=SIMULATOR_PREVIEW=true
flutter test integration_test/memory_flow_test.dart -d DEVICE_ID
npm test --prefix firebase/functions
npm ci --prefix firebase/tests
npx firebase-tools@14 emulators:exec --project demo-gostory --only firestore,storage "npm test --prefix firebase/tests"
```

Integration akışı gerçek ekran/rota/validasyon/arşiv/profil kodunu çalıştırır; native kamera fotoğrafını ve GPS sonucunu kontrollü fixture ile enjekte eder. Önizleme boş konumla açılır; otomatik GPS sonucunun kayda ve profile taşındığı doğrulanır. Kamera donanımı, gerçek GPS/izin davranışı ve Firebase ağının gerçek cihazda ayrı doğrulanması gerekir. Erişim kuralı testleri sahiplik, private/public okuma, sayaç koruması, ziyaret/beğeni/yazar taklidi ve Storage erişimini kapsar. Emulator testleri Java 21 gerektirir. Geçici Java çalışma ortamıyla yerel Firestore/Storage emulatoründe dört test geçti. CI bunu ayrı işte çalıştırır. Kamera ve GPS sonuçları enjekte edilen native integration testi iPhone 17 Pro / iOS 26.1 simülatöründe de geçti.

## CI/CD ve imzalama

`.github/workflows/checks.yml` her PR’da analiz, normal/demo testleri, coverage, fonksiyon testleri, Firebase emulator kuralları ve iOS simülatör integration testini çalıştırır. Flutter sürümü mevcut proje SDK’sı olan `3.48.0-0.5.pre` beta’ya sabittir. Kararlı Flutter geçişi ayrı doğrulanmalı.

`build.yml` manuel Android debug APK ve unsigned iOS release app üretir. Bunlar inceleme içindir. `deploy-firebase.yml` manuel sunucu dağıtımı için `FIREBASE_SERVICE_ACCOUNT` secret ve `FIREBASE_PROJECT_ID` variable ister. Servis hesabına gereken izinleri ver ve production ortamını repo ayarlarında yapılandır. Bu dosyalar herhangi bir canlı dağıtım çalıştırmış değildir.

Android release artık debug anahtarıyla imzalanmaz. Kendi upload keystore’unla git dışında `android/key.properties` oluştur:

```properties
storeFile=../upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Gerçek mağaza kayıtlarından alınan URL’leri kullan; tahmini kimliklerle doldurma:

```sh
flutter build appbundle --release --dart-define=FIREBASE_ENABLED=true --dart-define=APP_STORE_URL=https://apps.apple.com/... --dart-define=GOOGLE_PLAY_URL=https://play.google.com/store/apps/details?id=...
flutter build ipa --release --dart-define=FIREBASE_ENABLED=true --dart-define=APP_STORE_URL=https://apps.apple.com/... --dart-define=GOOGLE_PLAY_URL=https://play.google.com/store/apps/details?id=...
```

iOS için Apple Developer Team, dağıtım sertifikası/provisioning profili ve App Store Connect kayıtları gerekir. Mağaza upload/deploy otomasyonu imzalama ve mağaza API anahtarları eklendikten sonra kurulmalıdır; mevcut CI mağazalara yükleme yapmaz.

## Yayın öncesi kalanlar

Canlı Firebase proje dosyaları, rules emulator doğrulaması, FCM/APNs/App Check cihaz testi, release imzalama, gerçek mağaza URL’leri, final cihaz ekran görüntüleri ve yayıncı tarafından tamamlanmış politika adresleri gerekir. Herkese açık UGC için içerik şikâyeti, kullanıcı engelleme, içerik moderasyonu ve işletilecek destek süreci; anonim hesap/veri silme için uygulama içi ve dışı süreç de tamamlanmalı. Bunlar mevcut uygulamada henüz yoktur; mağaza yayını tamamlanmış sayılmaz.

Kaynaklar: [Firebase FCM Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started), [App Check Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers), [Firestore query/rules](https://firebase.google.com/docs/firestore/security/rules-query), [Apple inceleme kuralları](https://developer.apple.com/app-store/review/guidelines/), [Google Play hesap silme](https://support.google.com/googleplay/android-developer/answer/13327111), [Google Play kullanıcı verisi](https://support.google.com/googleplay/android-developer/answer/10144311).
