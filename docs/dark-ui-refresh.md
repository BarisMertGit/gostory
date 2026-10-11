# Koyu arayüz düzenlemesi

Route, tab sırası, callback hedefleri, izin akışları ve veri/state yönetimi korundu. Türkçe UI metinleri değiştirilmedi. Mevcut sıcak bej vurgu korundu; yardımcı aksiyonlar için #9DCED5 eklendi.

## Harita: uygulanan çözüm

`lib/shared/widgets/map_tiles.dart` mevcut OSM raster verisine ters luminans ve petrol tint uygular. URL hâlâ `https://tile.openstreetmap.org/{z}/{x}/{y}.png`; provider ve `com.gostory.app` user-agent değişmedi. Açık zemin koyulaşır, koyu etiketler açılır. Bu yöntem gerçek Dark Matter kartografisi değildir; tüm detayların rengi aynı luminans dönüşümüne tabidir. Raster TileLayer için stil JSON kullanılmaz. OSM attribution kendi satırında görünür ve tıklanabilir kalır.

## CARTO Dark Matter'a isteğe bağlı geçiş

1. [CARTO Basemaps](https://www.carto.com/basemaps/) üzerinden anahtar edin; mobil uygulama kapsamına sınırla. Güncel servis anahtar kullanıyor.
2. DiscoveryMap içindeki TileLayer URL'sini aşağıdaki raster URL ile değiştir. FlutterMap, MapController, işaretçiler, konum ve izin provider'ları aynı kalabilir.
3. `tileBuilder: mapTileBuilder` satırını kaldır; koyu raster tile'a ters luminans filtresi uygulama.
4. Mevcut user-agent ve enjekte edilen tileProvider alanını koru. MapOptions zoom sınırı 19 olarak kalabilir; kaynak 256 px raster döndürür. @2x kullanımı tile boyutu/retina ayarıyla ayrıca eşleştirilmelidir.
5. Attribution satırına © CARTO ekle; OSM bağlantısını korurken CARTO için ayrı tıklanabilir bağlantı kullan. Her iki hedef en az 44 px olsun. Bu sağlayıcıya geçildiğinde attribution metni eklemek lisans gereğidir.
6. Tile yükleme, pan/zoom, işaretçi seçimi ve sheet açıkken attribution görünürlüğünü cihaz üzerinde kontrol et.

```dart
const cartoKey = String.fromEnvironment('CARTO_BASEMAP_KEY');
TileLayer(
  urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png?key=$cartoKey',
  userAgentPackageName: 'com.gostory.app',
  tileProvider: widget.tileProvider,
)
```

Build: `flutter run --dart-define=CARTO_BASEMAP_KEY=YOUR_KEY`. Uygulamaya gömülen anahtar gizli sunucu anahtarı değildir; servis kısıtlamalarını kullan.

Attribution: `© OpenStreetMap contributors, © CARTO`. Bağlantılar: https://www.openstreetmap.org/copyright ve https://carto.com/attribution/.

Vektör stil JSON alternatifi: `https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json?key=YOUR_KEY`. Mevcut raster TileLayer stil JSON tüketmez; bunu kullanmak vektör renderer entegrasyonu gerektirir ve bu görsel düzenlemenin kapsamı dışındadır. Kaynak: [CARTO resmi basemap açıklaması](https://www.carto.com/basemaps/). Mevcut OSM servisi için [tile kullanım politikası](https://operations.osmfoundation.org/policies/tiles/) geçerlidir.

## Yerleşim ve ikonlar

- Paylaş tab aksiyonu: ekleme (+). Harita anısı: fotoğraf koleksiyonu. Kamera başlangıcı: kamera. Callback'ler aynı; ikonlar oluşturma, var olan anı ve çekim anlamlarını ayırır.
- Konum banner'ı SafeArea içinde, harita overlay Column'unda kontrollerden önce ayrı satırdadır; alt boşluğu 12 px. Banner ve kontroller aynı koordinatlara yerleştirilmez. Kısa ekran/büyük metinde üst banner gizlenir; aynı izin aksiyonu kaydırılabilir panelde her zaman bulunur. Flutter Stack çocuk sırası katmanlamayı sağlar, CSS z-index yoktur.
- FAB alt mesafesi `haritaYüksekliği × sheetExtent + 12`. Sheet hareket ettikçe FAB aynı mesafeyle izler; kalan harita yüksekliği 280–200 px arasında opacity 1–0 olur, 200 px altında FAB yerleşimden çıkar. Paneldeki mevcut boş durum aksiyonu ve tab aksiyonu erişilebilir kalır. Kontroller alan yetersizliğinde kompakt satıra döner.
- Segment grubu: dış radius 24, border #2B4143, padding 4. Eşit genişlikte, en az 44 px yüksekliğinde pill'ler; iç radius 20. Seçili #F5D4B3 → #E8B58B gradyan ve #142122 yazı; diğerleri #1B3032 zemin ve #AFBEC0 yazı. İç yatay padding 4, dikey 8.
- Paylaş: kaydırılabilir, yukarı hizalı tek kart; konum, ayırıcı, fotoğraf açıklaması ve mevcut CTA. Konum zorunluluğunu değiştiren stepper ya da yeni koşul eklenmedi.
- Profil: petrol gradyan ve ince kontur çizgileri, 80 px avatar, ortalanmış kullanıcı adı hizası. Ayarlar #F4F6F5 simge ve #1F3234 zemin kullanır.
- Boş durum: gri daire yerine iki anı kartı, bağlama özgü ikon ve küçük yıldız; dekoratif çizim ekran okuyucudan dışlanır. Mevcut açıklama ve aksiyonlar korunur.

## Doğrulama

Paylaşılan aksiyonların minimum hedef boyutları 44 px; ana CTA 48 px. Kontrast testi yardımcı rengi ve yeni yüzeyleri kapsar. Filtrelenmiş harita etiketlerinde tüm tile/zoom kombinasyonları için WCAG AA garantisi yoktur; uygulama metinlerinin AA kontrastı ayrıca ölçülür. Cihazda harita etiketi okunabilirliği görsel olarak kontrol edilmelidir.
