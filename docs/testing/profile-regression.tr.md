# Profil değişiklikleri için regresyon testleri

Tarih: 11 Ekim 2026

Son profil değişiklikleri için 24 Flutter ve 2 Firebase emülatör senaryosu eklendi. Tüm paket çalıştırıldığında 150 Flutter testi ve 6 Firestore/Storage kural testi geçti. `flutter analyze` sorun bildirmedi.

## Yerel profil ve dosyalar

Dosya: `test/core/user_profile_test.dart`

1. Yeni profil ve düzenlenen profil yalnızca `uid`, `username`, `bio` ve `photo` alanlarını kaydeder. Kullanıcı adı ve biyografinin başındaki/sonundaki boşluklar temizlenir.
2. Biyografi alanı bulunmayan eski kayıt açılır. Ek, artık kullanılmayan alanlar açılışı engellemez; sonraki kayıtta dosyadan çıkarılır. Kimlik ve fotoğraf korunur.
3. Biyografi gönderilmeyen güncelleme mevcut biyografiyi korur. Boş biyografi gönderilmesi biyografiyi temizler ve bu sonuç yeniden açılışta korunur.
4. Geçersiz kullanıcı adı ile kayıt reddedilir. Dosyanın içeriği, kimlik ve önceki biyografi değişmez.
5. Fotoğraf değiştirme ve kaldırma kimliği ve biyografiyi korur. Seçilen kaynak fotoğraf silinse bile uygulamanın kopyası okunabilir.
6. Fotoğraf kopyalanamazsa mevcut kayıt değişmez. Kullanıcı daha sonra yeniden düzenleme yapabilir.

Mevcut testler ayrıca yeniden açılışta fotoğraf/biyografi/kullanıcı adı korunmasını, desteklenen kullanıcı adı karakterlerini ve anılardaki yazar kimliğini kontrol eder.

## Bulut profili

Dosya: `test/core/cloud_profile_test.dart`

1. Profil belgesi yalnızca `ownerId`, `username` ve `bio` ile değiştirilir. Cihazdaki fotoğraf yolu gönderilmez. Yazma işlemi birleştirme kullanmadığından eski alanlar korunmaz.
2. Boş biyografi de gönderilir; önceki bulut biyografisi temizlenebilir.
3. Bulut yazma hatası çağırana iletilir; hata başarılı kayıt gibi gösterilmez.
4. Ek, artık kullanılmayan alanlar bulunan uzak profilin desteklenen bilgileri okunur.
5. Biyografisi bulunmayan eski uzak profil boş biyografiyle açılır.
6. Olmayan profil belgesi `null` döndürür.
7. Bulut devre dışıyken Firestore'a erişilmez.

Bu testler Firebase SDK çağrılarını taklit eder. Gerçek izin kuralları aşağıdaki emülatör testleriyle ayrıca sınanır.

## Profil düzenleyicisi

Dosya: `test/features/profile/profile_editor_test.dart`

1. Formda yalnızca kullanıcı adı ve biyografi metin alanları bulunur. Kaydetme iki alanı da profil ekranına yansıtır.
2. İptal kaydı değiştirmez. Form yeniden açıldığında kaydedilmiş değerler gösterilir.
3. Kayıt hatası kullanıcıya gösterilir, girilen metin korunur ve tekrar deneme başarılı olur.
4. Kayıt sürerken alanlar, kapatma ve kaydetme düğmesi devre dışıdır. İkinci dokunuş ek kayıt başlatmaz.
5. 320 × 568 ekranda, iki kat yazı boyutunda ve klavye açıkken form kaydırılabilir ve kaydedilebilir.

Mevcut testler geçersiz kullanıcı adının kaydedilmemesini, profilin yenilenmesini, yalnızca kullanıcının kendi anılarının listelenmesini ve anı seçeneklerine erişimi kontrol eder.

## Herkese açık profil

Dosya: `test/features/profile/public_profile_test.dart`

1. 320 × 568 ekranda normal yazı boyutunda kullanıcı adı, biyografi ve paylaşılan anı gösterilir.
2. Aynı içerik iki kat yazı boyutunda taşma hatası olmadan gösterilir.
3. Profil bulunamazsa anının yazar adı kullanılır ve paylaşılan anı gösterilmeye devam eder.
4. Boş biyografi kullanıcı adı ve anının gösterilmesini engellemez.
5. Bekleyen istekte yükleniyor göstergesi görünür; istek tamamlandığında profil açılır.
6. Başarısız yükleme tekrar denenebilir; başarılı tekrar kullanıcı adı, biyografi ve anıyı gösterir.

## Firestore ve Storage

Dosya: `firebase/tests/rules.test.js`

1. Eski belgede ek alanlar olsa da sahibi belgeyi desteklenen alanlarla değiştirebilir. Ek alanlar silinir, biyografi temizlenebilir ve desteklenmeyen alanların tekrar yazılması reddedilir.
2. Oturumsuz okuma, başka kullanıcının düzenlemesi, sahiplik değiştirme ve hatalı alan türleri reddedilir. Kullanıcı adı ve biyografi uzunluk sınırları uygulanır; 24 karakterlik kullanıcı adı ve 160 karakterlik biyografi kabul edilir.

Mevcut dört emülatör testi de geçti: özel/herkese açık anı erişimi, etkileşimlerde yazar kimliği, fotoğraf erişimi ve bildirim cihazı sahipliği.

## Yeniden çalıştırma

```sh
flutter analyze
flutter test --no-pub --dart-define=SIMULATOR_PREVIEW=true
firebase emulators:exec --project demo-gostory --only firestore,storage 'npm test --prefix firebase/tests'
```

Emülatör komutu için Java 21, Firebase CLI ve `firebase/tests` bağımlılıkları gerekir. Bu çalıştırmada Java ve CLI geçici klasörde hazırlandı; uygulamanın bağımlılıkları değiştirilmedi. Testler demo projede çalıştı, üretim verilerine erişilmedi.

Testlerde uygulama davranışını değiştirmeyi gerektiren bir hata bulunmadı. Yeni widget testleri, kaydırma sonrasında ekranın yerleşmesini bekleyerek düğmelere dokunur. Fiziksel cihazdaki galeri izinleri ve Android'in uygulama kapanışı sonrası fotoğraf seçimini kurtarması bu otomatik pakette sınanmadı.
