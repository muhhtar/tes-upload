# Daftar Prompt Berurutan: Lore Fase 1

Cara pakai:
1. Salin folder `docs/` dan `.github/` ke root proyek Anda, lalu buka di VS Code.
2. Kerjakan prompt **satu per satu, berurutan**. Jangan lompat.
3. Pakai **Copilot Chat mode Agent** (atau Edit) dengan model terkuat yang tersedia. Mulai chat baru tiap beberapa langkah agar konteks tidak penuh.
4. Setelah tiap langkah: jalankan, tes, dan commit ke Git sebelum lanjut. Kalau ada error, pakai "Prompt Perbaikan" di bagian akhir.
5. Di tiap prompt, tempel juga file yang relevan lewat `#file:docs/SPEC.md` bila Copilot tidak otomatis membacanya.

---

## LANGKAH 0: Setup manual (kerjakan sendiri, bukan oleh Copilot)

- [ ] Install Flutter SDK, Android Studio/emulator, Node.js 20+, Firebase CLI (`npm i -g firebase-tools`), dan FlutterFire CLI (`dart pub global activate flutterfire_cli`).
- [ ] Buat proyek di Firebase Console. Aktifkan **Authentication** (Email/Password + Google), **Firestore**, **Storage**, dan **Cloud Functions** (butuh paket Blaze; anggaran bisa dibatasi dengan budget alert).
- [ ] Di folder proyek: `firebase login`, lalu `flutterfire configure` (ini membuat `firebase_options.dart`).
- [ ] Untuk Google Sign-In di Android: daftarkan SHA-1 dan SHA-256 debug key di Firebase Console.
- [ ] Siapkan API key penyedia gambar AI, simpan nanti lewat `firebase functions:secrets:set IMAGE_API_KEY` (jangan ditaruh di kode).
- [ ] `git init`, buat `.gitignore` standar Flutter, dan pastikan file rahasia tidak ter-commit.

---

## PROMPT 1: Scaffold proyek

```
Baca #file:docs/SPEC.md dan #file:.github/copilot-instructions.md.

Tugas: siapkan fondasi proyek Flutter "Lore".
- Buat struktur folder lib/ persis seperti SPEC bagian 5 (folder kosong boleh berisi file .gitkeep).
- Tambahkan dependency di pubspec.yaml sesuai tabel Tech Stack (versi stabil terbaru yang kompatibel).
- Siapkan main.dart: inisialisasi Firebase (pakai firebase_options.dart yang sudah ada), ProviderScope Riverpod, dan MaterialApp.router dengan go_router berisi satu halaman placeholder "Lore".
- Aktifkan persistence offline Firestore.
- Jangan buat fitur lain.

Setelah selesai, jelaskan cara menjalankannya dan apa yang perlu saya cek.
```
**Cek sebelum lanjut:** `flutter run` menampilkan halaman placeholder tanpa error.

---

## PROMPT 2: Tema dan widget umum

```
Baca #file:docs/SPEC.md bagian 6 (Design Tokens).

Tugas: buat sistem tema Lore.
- core/theme/app_colors.dart: semua warna light dan dark dari SPEC.
- core/theme/app_text_styles.dart: gaya teks (judul serif Lora, isi Nunito via google_fonts, base 16sp, line height 1.5).
- core/theme/app_theme.dart: ThemeData light dan dark (ColorScheme, CardTheme radius 16, tombol radius 20, input field membulat, AppBar bersih).
- core/widgets: LoreButton (primary/secondary), LoreCard, LoadingView, ErrorView (pesan ramah + tombol coba lagi), EmptyState (ikon + teks + aksi opsional), PolaroidFrame (bingkai foto ala polaroid), AiBadge (chip "Ilustrasi AI").
- Pasang tema di MaterialApp dengan themeMode mengikuti sistem.
- Buat satu halaman debug sementara yang menampilkan semua widget di atas agar saya bisa melihatnya.

Larangan: jangan menulis hex warna di luar app_colors.dart.
```
**Cek:** buka halaman debug di mode terang dan gelap; kontras teks terbaca jelas.

---

## PROMPT 3: Model data dan repository memori

```
Baca #file:docs/SPEC.md bagian 7.

Tugas: buat lapisan data tanpa UI.
- data/models: UserModel, MemoryModel, MediaItem, MemoryDate (year, month?, day?, precision, sortKey dihitung otomatis), AiIllustration. Immutable, dengan copyWith, fromMap, toMap.
- data/repositories/memory_repository.dart (abstract + implementasi Firestore): 
  watchMemories({String? category, int limit = 20, DocumentSnapshot? startAfter}), getMemory(id), createMemory, updateMemory, deleteMemory (hapus juga file Storage terkait), getRandomMemory().
  Semua query WAJIB difilter user_id milik pengguna yang login dan diurutkan memory_date.sort_key desc.
- Provider Riverpod untuk repository.
- Tambahkan firestore.indexes.json sesuai indeks di SPEC.
- Tulis unit test untuk MemoryDate.sortKey dan serialisasi MemoryModel (toMap/fromMap bolak-balik).

Jangan buat layar apa pun di langkah ini.
```
**Cek:** `flutter test` hijau.

---

## PROMPT 4: Autentikasi

```
Baca #file:docs/SPEC.md bagian 2 poin 1 dan bagian 10 (Login/Daftar).

Tugas: fitur autentikasi lengkap.
- data/repositories/auth_repository.dart: signUpWithEmail, signInWithEmail, signInWithGoogle, sendPasswordReset, signOut, authStateChanges. Saat pertama kali daftar, buat dokumen users/{uid} (name, email, created_at, settings default, ai_quota awal).
- features/auth: LoginScreen, RegisterScreen, ForgotPasswordScreen. Validasi form (email valid, password min 8 karakter), tombol Google, tampilkan loading dan pesan error ramah berbahasa Indonesia untuk kode error umum FirebaseAuthException.
- Teks singkat soal privasi di layar login ("Cuma kamu yang bisa baca lore kamu.").
- Provider authState dan currentUser.
- Tambahkan test untuk validator.

Pakai tema dan widget yang sudah ada. Jangan ubah router dulu.
```
**Cek:** daftar, login, logout, dan lupa sandi berjalan; dokumen `users/{uid}` muncul di Firestore.

---

## PROMPT 5: Router, guard login, dan onboarding

```
Tugas: sambungkan navigasi.
- core/router/app_router.dart dengan go_router: rute /onboarding, /login, /register, /forgot-password, /home, /timeline, /memory/:id, /memory/new, /memory/:id/edit, /studio/:memoryId, /settings.
- Redirect: belum login -> /login (kecuali /onboarding, /register, /forgot-password); sudah login -> /home. Onboarding hanya tampil sekali (simpan flag di shared_preferences).
- OnboardingScreen: 3 slide ("Simpan", "Ceritakan", "Wariskan") dengan teks santai, indikator titik, tombol Lewati dan Mulai.
- Router harus reaktif terhadap perubahan authState (refreshListenable).
- Halaman /home, /timeline, dll. boleh masih placeholder.

Tambahkan shared_preferences bila belum ada.
```
**Cek:** alur buka aplikasi → onboarding → login → home benar; setelah logout kembali ke login.

---

## PROMPT 6: Beranda dan "Lore Hari Ini"

```
Baca #file:docs/SPEC.md bagian 10 poin 3.

Tugas: bangun HomeScreen.
- Sapaan sesuai jam (pagi/siang/sore/malam) memakai nama pengguna, gaya santai, contoh "Sore, Rani!".
- Kartu LoreHariIniCard: menampilkan satu kenangan acak milik pengguna (gambar/ilustrasi bila ada, judul, tanggal perkiraan). Tap membuka detail. Jika belum ada kenangan, tampilkan EmptyState dengan ajakan menambah lore pertama.
- Daftar "Terbaru" (5 kenangan terakhir) memakai PolaroidFrame bila ada gambar.
- FAB (+) menuju /memory/new. Ikon menuju Linimasa dan Pengaturan di AppBar atau bottom navigation sederhana.
- Tangani loading, error, dan kosong.

Gunakan provider dari repository yang sudah ada. Jangan mengubah repository kecuali benar-benar perlu.
```

---

## PROMPT 7: Form tambah/ubah kenangan (tanpa media)

```
Baca #file:docs/SPEC.md bagian 7 dan bagian 10 poin 6.

Tugas: MemoryFormScreen untuk tambah dan ubah (satu layar, mode ditentukan parameter).
- Field: judul (wajib, maks 100), cerita (maks 5000, multiline, penghitung karakter), tanggal perkiraan (pilih tahun wajib; bulan dan hari opsional; tampilkan hasilnya dalam teks seperti "Agustus 2010"), kategori (chip pilihan), mood (chip emoji).
- Validasi dan pesan error ramah.
- Draf otomatis tersimpan lokal (shared_preferences) dan dipulihkan bila pengguna kembali; hapus draf setelah berhasil simpan.
- Tombol Simpan memakai memory_repository (createMemory/updateMemory). Tampilkan loading, lalu arahkan ke detail kenangan.
- Konfirmasi saat keluar dengan perubahan belum tersimpan.
- Belum ada media dan ilustrasi AI di langkah ini (beri placeholder area "Foto & audio" yang dinonaktifkan).

Tambahkan test untuk validator form.
```
**Cek:** buat, ubah, simpan; periksa dokumen di Firestore (`memory_date.sort_key` benar).

---

## PROMPT 8: Linimasa

```
Tugas: TimelineScreen.
- Daftar kenangan kronologis (terbaru di atas) dikelompokkan per tahun dengan header tahun yang menempel (sticky) atau pemisah jelas.
- Chip filter kategori di atas (Semua + kategori dari SPEC).
- Paginasi 20 item (infinite scroll, memakai startAfter di repository).
- Kartu kenangan: gambar kecil (foto/ilustrasi), judul, tanggal perkiraan, ikon favorit.
- Pull-to-refresh, empty state ramah, dan tetap bisa dibuka saat offline (data dari cache).
- Tap kartu menuju /memory/:id.

Pakai cached_network_image untuk gambar. Jaga performa (ListView builder/Sliver).
```

---

## PROMPT 9: Detail kenangan (lihat, ubah, hapus, favorit)

```
Tugas: MemoryDetailScreen.
- Tampilkan gambar utama besar (foto pertama atau ilustrasi AI; beri AiBadge pada ilustrasi AI), judul, tanggal perkiraan, kategori, mood, cerita, dan area pemutar audio (placeholder dulu).
- Aksi: favorit (toggle), ubah (ke form mode edit), hapus (dialog konfirmasi bertingkat; hapus dokumen DAN file Storage terkait via repository).
- Animasi transisi lembut 250-350 ms (hormati reduce motion).
- Tangani loading, error, dan kenangan tidak ditemukan.

Tambahkan widget test sederhana untuk dialog konfirmasi hapus.
```

---

## PROMPT 10: Unggah foto dan audio

```
Baca #file:docs/SPEC.md bagian 7 (field media) dan bagian 8 (storage.rules).

Tugas: fitur media.
- data/repositories/storage_repository.dart: uploadPhoto, uploadAudio, deleteFile. Path: users/{uid}/memories/{memoryId}/photo_{n}.jpg dan audio.m4a. Kembalikan url, path, size.
- Kompres foto sebelum unggah (flutter_image_compress, sisi terpanjang maks 1600 px, kualitas ~80).
- Di MemoryFormScreen: aktifkan area media. Pilih foto dari galeri/kamera (maks 5, bisa dihapus dan diurutkan sederhana), pilih 1 berkas audio (file_picker, maks 10 MB). Tampilkan progres unggah dan thumbnail.
- Simpan memoryId lebih dulu (dokumen draf) agar path Storage konsisten, lalu perbarui array media.
- Di MemoryDetailScreen: galeri foto (geser) dan pemutar audio (paket audioplayers atau just_audio) dengan tombol play/pause dan seek.
- Minta izin kamera/galeri dengan penjelasan ramah; tangani izin ditolak.
- Antrian unggah offline tidak wajib; cukup tampilkan pesan jelas bila gagal dan tawarkan coba lagi.

Jangan ubah firestore.rules/storage.rules.
```
**Cek:** foto terkompres masuk Storage di path yang benar; hapus kenangan membersihkan file.

---

## PROMPT 11: Aturan keamanan dan uji emulator

```
Baca #file:docs/SPEC.md bagian 8.

Tugas: kunci keamanan data.
- Buat/rapikan firestore.rules dan storage.rules persis sesuai SPEC (jangan dilonggarkan).
- Konfigurasi firebase.json untuk Emulator Suite (auth, firestore, storage, functions).
- Tulis test aturan keamanan (paket @firebase/rules-unit-testing, di folder rules_tests/ dengan Node) yang membuktikan:
  1. pengguna A tidak bisa membaca/menulis/menghapus memori pengguna B,
  2. pengguna tanpa login ditolak,
  3. klien tidak bisa mengubah users/{uid}.ai_quota,
  4. judul kosong atau lebih dari 100 karakter ditolak saat create,
  5. file Storage hanya bisa diakses pemilik dan maksimal 10 MB.
- Tambahkan skrip npm "test:rules" dan jelaskan cara menjalankannya.
```
**Cek:** semua test aturan lolos sebelum lanjut ke AI.

---

## PROMPT 12: Cloud Function ilustrasi AI

```
Baca #file:docs/SPEC.md bagian 9 secara teliti.

Tugas: buat Cloud Function callable "generateIllustration" di folder functions/ (TypeScript).
- Validasi input (memoryId, style dari 4 pilihan), cek login dan kepemilikan kenangan.
- Cek dan perbarui kuota 5 ilustrasi/hari di users/{uid}.ai_quota memakai transaksi Firestore (Admin SDK). Jika habis, lempar HttpsError "resource-exhausted" dengan pesan santai.
- Moderasi sederhana (tolak cerita kosong dan kata kunci terlarang dari daftar konfigurasi).
- Susun prompt gambar: ringkasan adegan/suasana/warna dari cerita + templat gaya dari SPEC. Jangan menyertakan nama orang nyata atau instruksi meniru wajah.
- Fungsi terpisah callImageApi(prompt) yang membaca kunci dari secret IMAGE_API_KEY (defineSecret). Buat implementasi untuk penyedia gambar yang saya pilih: [ISI NAMA PENYEDIA, mis. OpenAI Images / Gemini Imagen / lainnya]. Penyedia harus mudah diganti.
- Simpan hasil ke Storage dan perbarui memories/{memoryId}.ai_illustration (status pending -> done/failed).
- Tambahkan test unit untuk fungsi penyusun prompt dan logika kuota (mock).

Jangan menaruh kunci apa pun di kode. Jelaskan perintah untuk set secret dan deploy.
```
**Cek:** jalankan di emulator, lalu coba deploy. Pantau biaya di dashboard penyedia.

---

## PROMPT 13: Lore Studio (UI ilustrasi AI)

```
Baca #file:docs/SPEC.md bagian 10 poin 7.

Tugas: LoreStudioScreen dan illustration_repository.
- illustration_repository memanggil callable generateIllustration lewat cloud_functions dan memetakan error (unauthenticated, resource-exhausted, failed) ke pesan ramah.
- Layar: pilih gaya (4 kartu bergambar/ikon), tombol "Buat", animasi loading yang lucu dengan teks bergantian (contoh "Lagi nyeduh warna...", "Bentar, lagi gambar lore kamu"), pratinjau hasil dengan AiBadge, tombol Pakai, Ulangi, Buang. Tampilkan sisa kuota hari ini.
- Dari MemoryFormScreen dan MemoryDetailScreen tambahkan tombol "Buat Ilustrasi AI" menuju /studio/:memoryId (kenangan harus sudah tersimpan dulu).
- "Buang" menghapus file ilustrasi dan mengosongkan field ai_illustration; "Pakai" mempertahankannya dan kembali ke detail.
- Tampilkan persetujuan singkat sekali saja: "Cerita kamu dikirim ke layanan AI buat dibikinin ilustrasi."

Tangani semua state (loading, error, kuota habis, gagal).
```

---

## PROMPT 14: Pengaturan, tema, dan kunci biometrik

```
Tugas: SettingsScreen dan kunci biometrik.
- Pengaturan: pilihan tema (Ikuti sistem / Terang / Gelap, tersimpan di users.settings), saklar kunci biometrik, gaya ilustrasi default, tombol logout, bagian "Tentang privasi" berisi teks singkat dan jelas.
- Kunci biometrik dengan local_auth: jika aktif, saat aplikasi dibuka atau kembali dari background > 30 detik, tampilkan layar kunci dan minta autentikasi. Sediakan fallback bila perangkat tidak mendukung biometrik (nonaktifkan saklar dengan penjelasan).
- Pastikan layar kunci tidak menampilkan konten kenangan (hindari preview di task switcher bila memungkinkan).
- Tambahkan konfigurasi platform yang dibutuhkan (izin Android/iOS) dan jelaskan langkahnya.
```

---

## PROMPT 15: Offline, performa, dan aksesibilitas

```
Tugas: poles kualitas.
- Offline: pastikan linimasa, beranda, dan detail membuka data dari cache saat tanpa internet; tampilkan banner kecil "Lagi offline, tetap bisa baca lore kamu". Buat kenangan (tanpa media) saat offline harus tersimpan dan tersinkron saat online.
- Performa: audit rebuild yang tidak perlu, pakai const, batasi ukuran gambar thumbnail di daftar, pastikan daftar memakai builder.
- Aksesibilitas: periksa kontras, ukuran target sentuh 48x48 dp, Semantics untuk gambar/ikon, dukung font besar tanpa overflow, hormati reduce motion.
- Jalankan flutter analyze dan perbaiki semua peringatan.
Buat daftar temuan dan perbaikan yang dilakukan.
```

---

## PROMPT 16: Uji akhir dan checklist rilis

```
Baca #file:docs/SPEC.md bagian 11 (Kriteria Selesai).

Tugas: verifikasi Fase 1.
- Tulis integration test atau skenario uji manual terperinci untuk: daftar -> tambah kenangan dengan foto -> buat ilustrasi AI -> lihat di linimasa -> ubah -> hapus -> logout.
- Periksa tidak ada API key/secret di repositori (grep) dan tidak ada fitur dari daftar "di luar cakupan".
- Buat README.md berisi cara setup, menjalankan emulator, menjalankan test, dan deploy functions + rules.
- Buat checklist rilis: ikon aplikasi, splash, nama aplikasi "Lore", versi/build, kebijakan privasi, App Check, budget alert Firebase, screenshot toko aplikasi.
Laporkan item yang belum terpenuhi.
```

---

## PROMPT PERBAIKAN (template)

**Saat ada error:**
```
Saya mendapat error ini saat [menjalankan/membangun/menguji] [fitur]:
[TEMPEL PESAN ERROR LENGKAP]
Konteks: [langkah yang dikerjakan]. 
Cari akar masalahnya, perbaiki seminimal mungkin, dan jelaskan penyebabnya. Jangan mengubah hal yang tidak berkaitan.
```

**Saat hasil kurang bagus (UI):**
```
Tampilan [layar] belum sesuai. Masalahnya: [jelaskan, mis. terlalu padat / warna kurang kontras / terasa kaku].
Rapikan sesuai Design Tokens di docs/SPEC.md bagian 6 tanpa mengubah logika. Tampilkan perubahan yang dibuat.
```

**Review sebelum commit:**
```
Review perubahan terakhir terhadap #file:.github/copilot-instructions.md dan #file:docs/SPEC.md.
Cari: pelanggaran aturan, fitur di luar cakupan, risiko keamanan (query tanpa filter user_id, kunci bocor), state loading/error yang terlewat, dan test yang kurang. Berikan daftar temuan berurutan dari yang paling berisiko.
```

**Saat Copilot melebar/ngelantur:**
```
Berhenti. Kamu menambah hal di luar permintaan. Batalkan perubahan di luar tugas "[tugas]" dan kembali ke cakupan di docs/SPEC.md bagian 2. Kerjakan hanya: [ulangi tugas].
```
