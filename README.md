# SchoolHub

## Aktifkan log masuk Google (Firebase)

SchoolHub menggunakan Firebase Authentication. Log masuk Google boleh dimulakan
dengan pelan Firebase Spark percuma. Ciri Firebase lain mungkin mempunyai had
atau caj berasingan; semak pelan projek sebelum mengaktifkannya.

1. Cipta projek di [Firebase Console](https://console.firebase.google.com/).
2. Pasang Firebase CLI dan FlutterFire CLI, kemudian log masuk:

   ```powershell
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```

3. Dari folder projek SchoolHub, daftarkan platform yang hendak digunakan:

   ```powershell
   flutterfire configure
   ```

   Pilih projek Firebase dan platform Android atau Web yang diperlukan.
   Konfigurasi projek `schoolhub-16736` untuk Android dan Web sudah dijana.
4. Dalam Firebase Console, pastikan **Authentication → Sign-in method →
   Google** diaktifkan dan e-mel sokongan projek ditetapkan.
5. SHA-1 debug untuk mesin pembangunan semasa sudah didaftarkan pada aplikasi
   Android Firebase. Jika membangunkan pada mesin lain, tambah SHA-1 debug mesin
   itu dan jalankan semula `flutterfire configure`. Sebelum menerbitkan aplikasi,
   tambah juga fingerprint sijil release atau Play App Signing.
6. Cloud Firestore untuk projek ini telah dicipta di `asia-southeast1`
   (Singapore). Selepas log masuk pertama, pengguna memilih salah satu daripada
   lima sekolah yang disediakan dan jenis akaun Guru, Ibu bapa atau PK HEM. Guru,
   Guru dan PK HEM boleh membuka **Servis → Permohonan tukar sekolah** untuk
   memohon pertukaran sekolah atau jawatan; admin perlu meluluskan sebelum
   sekolah atau jawatan pada profil pemohon dikemas kini. Permohonan disimpan di
   `schoolTransferRequests`.
   Aduan fasiliti, tempahan dan pengumuman disimpan dalam subkoleksi
   `schools/{schoolId}/services`. Aduan fasiliti memerlukan gambar kerosakan dan
   memaparkan penjejakan `Diterima` → `Dalam Siasatan` → `Sedang Dibaiki` →
   `Selesai`; PK HEM atau Admin perlu memuat naik gambar bukti siap sebelum
   menandakan aduan selesai. Aduan selesai memaparkan slider perbandingan gambar sebelum
   dan selepas. Status tempahan boleh diubah kepada `Pending` atau `Approved`;
   setiap tempahan menyimpan tarikh, masa mula dan masa tamat. Pengumuman
   mempunyai tarikh yang boleh dipilih dan dipaparkan pada kad pengumuman.
   PK HEM boleh memadam item Lost & Found, aduan fasiliti,
   tempahan dan pengumuman dengan swipe ke kiri dan pengesahan. Ibu bapa hanya
   boleh melihat Lost & Found dan Pengumuman, serta boleh meninggalkan komen
   pada laporan Lost & Found yang dapat dilihat oleh ahli sekolah. Akses PK HEM
   terhad kepada sekolah pada profilnya.
   Akaun Admin membuka **Servis → Permohonan tukar
   sekolah** untuk menyemak permohonan. Lost & Found disimpan di
   `schools/{schoolId}/lostItems` dan dipaparkan secara langsung kepada ahli
   sekolah tersebut. Guru boleh melapor dan menuntut barang; akaun Ibu bapa hanya
   boleh melihat Lost & Found dan Pengumuman serta boleh mengomen laporan barang.
   Tekan kad barang untuk melihat gambar,
   penerangan dan lokasi dengan lebih jelas.

   Akaun Google `knightt.fc@gmail.com` boleh memilih Guru, Ibu bapa, PK HEM atau Admin
   semasa setup; akaun lain boleh memilih Guru, Ibu bapa atau PK HEM. Firestore
   rules menguatkuasakan had Admin dan skop sekolah PK HEM. Pemilihan PK HEM
   semasa setup belum memerlukan jemputan atau pengesahan pihak sekolah, jadi
   hadkan akses aplikasi kepada pengguna yang dipercayai. Jika memilih Admin, skop ditetapkan
   kepada `all-schools` secara automatik dan pengguna tidak perlu memilih
   sekolah. Akaun Admin boleh
   menyemak permohonan pertukaran sekolah daripada semua sekolah melalui tab
   Servis. Untuk akaun Admin yang sudah mempunyai profil lama, log masuk semula
   dengan akaun yang ditetapkan dan lengkapkan setup sekali lagi supaya skopnya
   ditukar kepada semua sekolah. Pastikan rules terbaru sudah diterbitkan selepas
   sebarang perubahan; rules yang belum diterbitkan boleh menyebabkan
   `permission-denied` ketika menyimpan profil.

   Senarai sekolah yang dibenarkan:

   - Sekolah Menengah Kebangsaan Seri Bintang Selatan
   - Sekolah Menengah Kebangsaan Cochrane
   - Sekolah Menengah Kebangsaan Bandar Baru Ampang
   - Sekolah Menengah Kebangsaan Victoria
   - Sekolah Menengah Kebangsaan St. John

   Gambar Lost & Found dan pengumuman dikecilkan dan disimpan sebagai data gambar
   dalam dokumen Firestore (maksimum 700 KB setiap gambar), jadi Firebase Storage
   tidak diperlukan. Pengumuman yang belum dipadam kekal dalam bahagian **Untuk
   perhatian**; pengumuman terbaharu dipaparkan sebagai pop-up sekali setiap sesi
   aplikasi dan boleh ditutup dengan butang pangkah. Firestore rules berada dalam
   `firestore.rules`; selepas mengubahnya, gunakan:

   ```powershell
   firebase deploy --only firestore:rules --project schoolhub-16736
   ```

Nama sekolah dan peranan dipilih sendiri semasa persediaan; aplikasi belum
mempunyai kod jemputan atau pengesahan pihak sekolah.

7. Jalankan aplikasi:

   ```powershell
   flutter run
   ```

## Portal web Admin

Portal web menggunakan Firebase yang sama dengan aplikasi telefon. Akaun Admin
boleh log masuk melalui pelayar komputer untuk melihat ringkasan langsung bagi
aduan, tempahan dan Lost & Found di lima sekolah, menyemak permohonan pertukaran,
mengurus pengumuman (termasuk gambar) dan mengemas kini servis sekolah. Pilih
sekolah pada menu sebelah sebelum membuka servis. Butang **Buat pengumuman**
berada pada dashboard Admin. Akaun bukan Admin tidak boleh menggunakan portal
web; aplikasi telefon kekal seperti biasa.

Untuk jalankan secara setempat:

```powershell
flutter run -d chrome
```

Untuk bina dan terbitkan portal ke Firebase Hosting:

```powershell
flutter build web
firebase deploy --only firestore:rules,hosting --project schoolhub-16736
```

Pastikan Google Sign-In diaktifkan dalam Firebase Authentication, domain Hosting
dibenarkan di tetapan Authentication, profil akaun Admin sudah lengkap dan
Firestore rules terkini telah diterbitkan sebelum portal digunakan.

Selepas konfigurasi, pengguna akan log masuk dengan akaun Google dan aplikasi
akan kembali ke skrin log masuk selepas mereka log keluar. Profil sekolah
disimpan per akaun; akaun yang memilih nama sekolah sama berkongsi laporan
Lost & Found sekolah itu. Jangan hantar fail konfigurasi peribadi atau kata
laluan ke dalam chat.

## Semakan pembangunan

```powershell
flutter analyze
flutter test
```
