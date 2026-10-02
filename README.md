# GoStory

Flutter ile fotoğraf, not ve konumdan anı arşivi oluşturma; isteğe bağlı herkese açık keşif ve sosyal etkileşim.

```sh
flutter pub get
flutter run --dart-define=SIMULATOR_PREVIEW=true
flutter analyze
flutter test
flutter test --dart-define=SIMULATOR_PREVIEW=true
```

Varsayılan olarak cihazdaki kalıcı arşiv ve yerel profil kullanılır. Firebase yapılandırılıp `FIREBASE_ENABLED=true` verildiğinde özel/herkese açık paylaşım, public profiller, bulut beğeni/yorumları, gerçek ziyaret sayaçları ve FCM kullanılabilir. Firebase proje dosyaları bu çalışma alanında bulunmadığı için canlı hizmetler henüz etkin değildir.

Fotoğraf önce cihazda saklanır. Public/private seçimi taslaktan kayda taşınır; eski kayıtlar özel kalır. Yükleme ve silmeler bağlantı gelince, uygulama çalışırken tekrar denenir. Kuyruk sürüm bilgisi eşzamanlı görünürlük/silme işlemlerini korur. Profil kartındaki kilit/dünya düğmesi görünürlüğü değiştirir.

Anı oluşturma kameradan fotoğraf çekerek başlar; galeri yalnızca profil fotoğrafı için kullanılır. Önizlemede konum boşsa GPS bir kez istenir ve alınırken ilerleme gösterilir. Konum haritadan değiştirilebilir; geciken GPS sonucu elle seçilen yeri değiştirmez. Profil yalnızca kullanıcının kendi anılarını gösterir.

Haritada başkasının anısını seçmek kullanıcı profiline gider; paylaşılmış biyografi/sosyal bağlantılar ve seçilen anıya bağlantı gösterilir. Detay ekranında tekil ziyaretler, beğeni ve son 50 yorum bulunur. Yeni yorumlar ve 1 km yakınlıktaki yeni anılar için bildirimler Profil → Ayarlar → Bildirimler’den açılır. Yakınlık son izinli konumla eşleştirilir; arka planda sürekli konum takibi yapılmaz.

Yorumlar düğmeden veya klavyenin gönder eyleminden iletilir. Boş yorum gönderilemez; işlem sırasında ilerleme, tamamlandığında başarı mesajı gösterilir. Hata durumunda yorum metni korunur. Yeni yorumlar tarih ve saat bilgisiyle gösterilir.

Keşif Firebase’de 40 kayıtlık cursor sayfaları kullanır; profil kartları 20’lik gruplarla oluşturulur. Ağ fotoğraflarında CachedNetworkImage, özel Storage fotoğraflarında kimliğe göre ayrılmış sınırlı byte önbelleği kullanılır. OpenStreetMap karolarının HTTP önbelleği 128 MiB hedefle başlatılır; toplu karo indirme yoktur. [OSM karo politikası](https://operations.osmfoundation.org/policies/tiles/).

Yeni testler kuyruk/kimlik/provider davranışını, paylaşım seçimini, profil düzenleme validasyonunu, temel renk kontrastlarını ve kontrollü kamera olayı → önizleme → gerçek kayıt → profil akışını kapsar. Donanım kamerası, gerçek Firebase/FCM/App Check ve platform build’leri ayrıca cihazda doğrulanmalıdır.

[Firebase kurulumu, test kapsamı ve yayın hazırlığı](docs/release/README.md), [mağaza metinleri](docs/release/store-metadata.tr.md), [changelog](CHANGELOG.md).

Uygulama yeniden kurulursa anonim bulut kimliği kurtarılamayabilir; hesap kurtarma, hesap/veri silme ve UGC moderasyonu mağaza yayını öncesinde tamamlanmalıdır. Yayın için imzalama kimlikleri, gerçek mağaza/politika URL’leri ve Firebase platform dosyaları gerekir.
