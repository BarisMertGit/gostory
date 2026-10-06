# Arayüz uygulaması ve doğrulama

Harita, Paylaş, fotoğraf sonrası önizleme ve Profil ekranları mevcut Flutter/Riverpod akışları üzerinde düzenlendi. Backend şeması, oturum, arşiv ve bulut servisleri değiştirilmedi; bağımlılık eklenmedi.

- Renkler `AppColors`, aralıklar `AppSpacing`, köşeler/boyutlar/hareket `design.dart`, tipografi ve kontrol durumları `AppTheme.dark` üzerinden yönetiliyor.
- Ortak parçalar: `PageHeading`, `SectionHeading`, `SurfacePanel`, `PrimaryAction`, `SecondaryAction`, `FilterControl`, `EmptyState`, `LocationPermissionBand`, `MemoryTile`.
- Haritadaki izin bandı haritanın üzerinde; sürüklenebilir panel metin büyüklüğüne göre ölçülüyor. Atıf ayrı, erişilebilir bir alanda. Kümeler gerçek kayıt sayısını gösteriyor; aynı yerdeki kayıtlar birlikte açılabiliyor. Konum yokken mesafe gösterilmiyor.
- Mevcut OpenStreetMap raster sağlayıcısı korundu. Etiketleri ve yolları karartmadan doygunluk %55'e indirildi. Raster karolar ayrı yol/etiket renkleriyle yeniden stillendirilemiyor; başka sağlayıcı veya API anahtarı eklenmedi.
- Paylaş ekranında tek kamera aksiyonu var. Hazır kamerada ortalanmış deklanşör ve yalnızca donanım destekliyorsa çevirme kontrolü görünüyor. Galeri mevcut üründeki gibi yalnızca profil fotoğrafı için kullanılıyor.
- Önizlemede form kaydırılabiliyor, paylaşma aksiyonu klavyenin üzerinde kalıyor. Kayıt sürerken yeniden gönderim ve konum değiştirme engelleniyor; hatada not ve fotoğraf korunuyor.
- Profil özeti büyük yazıda dikey düzene geçiyor. Fotoğraflar kare; 360 genişlikte normal yazıyla iki sütun, büyük yazıda tek sütun kullanılıyor. Tarihler kısa Türkçe biçimde.
- Alt navigasyon 64 mantıksal piksel + sistem güvenli alanı kullanıyor; mevcut IndexedStack sekmeler arasında harita durumunu koruyor.

## Görseller

[Harita](map-390.png), [Paylaş](share-390.png), [Profil](profile-390.png).

Görüntüler 390 × 844 mantıksal pikselde uygulama widget'larından alındı ve görsel olarak incelendi. Mevcut yerel profil/arşiv kullanıldı; arşiv boş olduğundan sayaçlar sıfır. Görüntülere tasarım için kullanıcı veya anı eklenmedi. Kamera izni/konum izni verilmiş gibi gösterilmedi. Harita karoları gerçek sağlayıcıdan yüklendi. Yakalama aracında sistem Arial fontu kullanılır; uygulama platform fontunu kullanmayı sürdürür.

```sh
flutter test --no-pub tool/capture_redesign_test.dart
# Başka bir mevcut arşiv için: GOSTORY_ARCHIVE_DIR=/arşiv/dizini
```

## Kontroller

- `flutter analyze --no-pub`
- `flutter test --no-pub`: 102 başarılı, önizleme bayrağı gerektiren 3 test atlandı. Sonradan eklenen küme testi ayrıca başarılı.
- `flutter test --dart-define=SIMULATOR_PREVIEW=true --no-pub`: 106 başarılı; tüm testler çalıştı.
- iPhone 17 Pro / iOS 26.1 simülatöründe `integration_test/memory_flow_test.dart`: başarılı.
- 360 / 390 / 430 genişlik, 1× / 2× sistem yazısı, güvenli alanlar, uzun kullanıcı adı, konum reddi, sekme değişiminde harita konumunun korunması, panel açma/sürükleme ve erişilebilir atıf kontrol edildi. Ek olarak mevcut 320 × 568 harita testi geçti.
- Klavye açıkken paylaşma düğmesinin görünürlüğü, kayıt sırasında tekrarlı gönderim engeli ve hatadan sonra not/fotoğraf korunması altı boyut/yazı kombinasyonunda doğrulandı.
- 125 aynı konumdaki kaydın küme sayısı, küme açılması ve büyük yazı ayarında taşmaması doğrulandı.
- Kontrast: yükseltilmiş yüzeyde ana metin 12,77:1, ikincil metin 7,23:1; şeftali aksiyonda koyu metin 8,98:1. Mevcut kontrast testleri geçti.

Simülatördeki kayıt akışı kontrollü kamera ve konum verisi kullanır. Fiziksel kamerayla çekim, gerçek cihazdaki sistem izin ekranları, canlı Firebase yüklemesi ve Android cihaz çalıştırması bu turda doğrulanmadı.

## 6 Ekim 2026 — tamamlayıcı düzenleme

Mevcut petrol/şeftali tasarım sistemi korunarak kalan yerleşim ve erişilebilirlik ayrıntıları tamamlandı:

- `AdaptiveStateBody`: Paylaş başlangıcını kullanılabilir alanda dengeler; küçük ekranlarda ve büyük yazıda kaydırmaya izin verir. Harita ve Profil hata durumları da bu ortak bileşeni kullanır.
- Harita kontrolleri sürüklenen panelin üstünde kalan gerçek alana göre yatay/dikey yerleşir. Alan daraldığında izin açıklaması açılan panelde erişilebilir kalır.
- `MapAttribution`: keşif haritası ve manuel konum seçicisinde ortak, en az 44 piksel dokunma alanlı atıf bağlantısı; tarayıcı açılamadığında hata geri bildirimi.
- Filtre düğmeleri hareket azaltma tercihini izler. Android sistem navigasyon çubuğu ortak yüzey rengini kullanır.
- 360/390/430 × 640/844 boyutları ve 1×/2× yazıyla 12 düzen testi; kontrollerin panelle çakışmadığı da kontrol edilir.
- Son test: `flutter test --dart-define=SIMULATOR_PREVIEW=true --no-pub` — 112 başarılı, atlanan test yok.
- Üç ekran görüntüsü mevcut yerel arşivle yeniden üretildi ve görsel olarak incelendi. Profil görüntüsü öncekiyle aynı; Paylaş ve Harita görüntüleri güncellendi.

Bu turda fiziksel kamera, gerçek cihaz izin ekranları, canlı Firebase aktarımı ve cihaz/simülatör entegrasyon testi çalıştırılmadı. Yukarıdaki simülatör sonucu önceki doğrulamaya aittir.

## Fotoğraf odağı ve geçişler

- Paylaş başlangıcındaki iki iç içe yüzey kaldırıldı; küçük kamera ikonu, güçlü başlık ve tek ana aksiyon kaldı.
- Profil özeti ve boş durumun dış kartları kaldırıldı. Düzenleme aksiyonu 44 piksel dokunma alanını koruyan metin butonuna dönüştü; anı ızgarası yukarı taşındı.
- Seçilen harita anısında geniş fotoğraf gösterilir; 700 pikselden kısa ekranlarda metin erişimini korumak için yatay fotoğraflı kart kullanılır. Yeni işaretçi seçiminde panel listesi başa döner.
- Harita ve profil fotoğrafları ayrı kaynak etiketleriyle detay ekranına Hero geçişi yapar. Geçiş 200 ms; hareket azaltmada Hero ve rota animasyonu kapalıdır.
- Paylaşım başarısı kısa süreli, onay ikonlu bildirimle gösterilir.
- Profil, anı ızgarası ve harita ilk yüklemesi için sabit yer tutucular eklendi. Fotoğraf yüklenmesi ve fotoğrafın bulunamaması ayrı durumlardır. Yer tutucular ekran okuyucuya yükleme durumunu bildirir ve sürekli animasyon üretmez.
- Statik analiz temiz. Tam takımda 114 test geçti; yeni üç yer tutucu testindeki test-sonu SemanticsHandle temizliği düzeltildikten sonra bu üç test de ayrıca geçti. Yeni ileri/geri fotoğraf geçişi ve hareket azaltma testleri başarılı.
- Üç ekran görüntüsü mevcut arşivle yeniden alındı; Paylaş ve Profil görsel olarak incelendi. Gerçek cihaz kamera/izinleri ve canlı bulut aktarımı bu turda çalıştırılmadı.
