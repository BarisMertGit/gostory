# GoStory Gizlilik Politikası · yayın öncesi taslak

Yayıncı: [Yayıncı unvanı]
İletişim: [Gizlilik iletişim adresi]
Yürürlük tarihi: [Yayın tarihi]

GoStory, fotoğraf, not ve seçtiğin konumla anı arşivi oluşturmanı sağlar.

## İşlenen bilgiler

Cihazında kullanıcı kimliği, kullanıcı adı, biyografi, profil fotoğrafı, sosyal profil bağlantıları, anı fotoğrafları, kısa notlar, seçtiğin koordinatlar, şehir ve oluşturulma zamanı saklanır. Yer işaretleri ve yerel etkileşimler de cihazda tutulur.

Bulut özelliği etkin bir sürümde Firebase anonim kimlik doğrulaması, Firestore ve Storage kullanılır. Anı fotoğrafları, notlar, konum, görünürlük, profil bilgileri ve etkileşim kayıtları bu hizmetlere iletilir. Profil fotoğrafı mevcut uygulamada buluta yüklenmez. Cihazdaki fotoğraf dosya yolları yayımlanmaz.

Herkese açık olarak seçtiğin anının fotoğrafı, notu ve kesin konumu diğer kullanıcılara gösterilir. Kullanıcı adı, biyografi ve eklediğin sosyal bağlantılar bulut profiline aktarılır. Özel anılar erişim kurallarıyla sahibine ayrılır. Başkaları yayımladığın içeriği cihazlarına kaydetmiş olabilir.

Bildirimleri etkinleştirdiğinde FCM cihaz anahtarı, bildirim tercihleri ve kimliğin kaydedilir. Yakın anı bildirimini ayrıca açarsan izin verdiğin son cihaz konumu kaydedilir. Yakınlık eşleşmesi son 24 saatte güncellenen konumlar ve 1 km yarıçapla yapılır. Sürekli veya arka planda konum takibi yapılmaz.

App Check uygulama/cihaz doğrulaması için platform sağlayıcılarını kullanır. Harita karoları OpenStreetMap sunucularından istenir; sağlayıcı ağ adresini ve istenen harita karosunu alabilir. Şehir adı çözümleme işletim sisteminin konum hizmetlerini kullanır.

## Amaç, paylaşım ve saklama

Bilgiler anı saklama, seçtiğin içeriği paylaşma, yorum/beğeni gösterme, bildirim gönderme ve yetkisiz erişimi önleme için kullanılır. Bu uygulamada reklam veya pazarlama analitiği entegrasyonu yoktur. Altyapı hizmetleri Firebase/Google, Apple doğrulama ve cihaz hizmetleri ile OpenStreetMap’i içerir.

Yerel arşiv uygulama verileri silinene kadar cihazında tutulur. Bulut kayıtları silme işlemi tamamlanana kadar saklanır; bağlantı yoksa silme işlemi kuyruğa alınır. Servis yedekleri, güvenlik günlükleri, olay işleme makbuzları ve bunların süreleri yayıncı tarafından yapılandırılmalı ve bu metinde açıklanmalıdır. Son konumun 24 saat sonra bildirim eşleşmesinden çıkarılması, verinin fiziksel olarak silindiği anlamına gelmez.

## Kontrollerin ve başvuruların

Kamera, fotoğraf, konum ve bildirim izinlerini cihaz ayarlarından yönetebilirsin. Anı görünürlüğünü profilinde değiştirebilir ve kendi anını silebilirsin. Bildirimleri uygulama ayarlarından kapatabilirsin. Buluttaki değişiklikler internet bağlantısı gerektirir. Anonim oturum uygulama silindikten sonra kurtarılamayabilir; cihazdaki arşiv otomatik olarak başka cihaza taşınmaz.

Erişim, düzeltme ve silme başvuruları için [Gizlilik iletişim adresi] üzerinden yayıncıya ulaş. Yayın öncesinde uygulama içi hesap/veri silme, uygulama dışı başvuru adresi, hizmet bölgeleri, yasal dayanaklar, aktarım mekanizmaları, saklama süreleri ve yaş politikası yayıncı tarafından tamamlanmalıdır.
