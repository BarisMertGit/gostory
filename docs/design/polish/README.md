# GoStory görsel kontrolü

Bu klasördeki görüntüler **örnek verilerle** alınmıştır. Kullanıcı adı, anılar, yorumlar ve fotoğraf yerine kullanılan çizim test verisidir; gerçek kullanıcı içeriği değildir.

- [Profil](profile-sample.png): kayan başlık, avatar halkası, gerçek arşiv sayılarından üretilen sayaçlar ve masonry düzeni.
- [Kamera başlangıcı](camera-starter-sample.png): kamera izni istemeden görünen başlangıç ve alt navigasyon.
- [Önizleme](preview-sample.png): fotoğraf, cam not alanı, görünürlük tercihi ve sabit paylaş düğmesi.
- [Anı](memory-sample.png): parallax fotoğraf ve sabit yorum girişi.
- [Yorumlar](comments-sample.png): bilgi çipleri, yorum balonları ve yorum gönderme alanı.

Görüntüleri yeniden üretmek için:

```sh
flutter test --no-pub tool/capture_polish_test.dart --dart-define=SIMULATOR_PREVIEW=true
```

Plus Jakarta Sans ve Inter uygulamaya gömülüdür; çalışma zamanında font indirilmez. Font lisansları `assets/fonts/` altında bulunur. `journal.json` bu proje için hazırlanmış yerel Lottie illüstrasyonudur. Buton, filtre, giriş ve sayaç animasyonları Flutter'ın yerleşik araçlarıyla uygulanır. Hareket azaltma açıkken geçişler anlık, illüstrasyonlar sabittir.

Yeni bağımlılıklar: `flutter_svg 2.0.17`, `lottie 3.3.1`, `flutter_staggered_grid_view 0.7.0`. SVG'nin geçişli bağımlılıkları Dart 3.6 koşulunu yükseltmeyecek sürümlere sabitlenmiştir. Mevcut uygulamanın tüm bağımlılıkları Flutter 3.27 üzerinde yeniden doğrulanmış değildir; bu kontrol yeni görsel paketlerin sürüm koşullarını kapsar.

Widget testleri 320–430 genişliklerde, 568/844 ekran yüksekliğinde ve 1×/2× yazıda sekme durumunu, klavyenin üzerinde kalan yorum/paylaş düğmelerini, gönderim tekrarını, hata sonrası taslağı ve ilk kullanım tercihinin kalıcı kaydını kontrol eder. Gerçek cihazda kamera önizlemesi, flaş ve zamanlayıcının donanım davranışı ayrıca denenmelidir.
