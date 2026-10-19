# Instruksi Proyek untuk Copilot: Lore

Kamu membantu membangun **Lore**, aplikasi Flutter untuk menyimpan kenangan pribadi (Firebase backend). Sumber kebenaran ada di `docs/SPEC.md`. Baca file itu sebelum mengerjakan tugas apa pun.

## Aturan utama
1. **Kerjakan hanya yang diminta** pada prompt saat ini. Jangan menambah fitur, layar, atau paket di luar permintaan. Fitur di bagian "Di luar cakupan" pada SPEC.md dilarang dikerjakan.
2. **Ikuti struktur folder** di SPEC.md bagian 5. Jangan membuat folder baru tanpa alasan jelas.
3. **Bahasa:** nama class, variabel, dan fungsi memakai bahasa Inggris. Teks yang tampil ke pengguna memakai bahasa Indonesia santai (campur Inggris boleh), tanpa kesan menggurui. Komentar kode singkat dalam bahasa Indonesia.
4. **Jangan pernah menaruh API key, secret, atau kredensial di kode Flutter atau di repositori.** Panggilan ke layanan AI hanya lewat Cloud Functions.
5. **Keamanan data:** setiap query ke `memories` wajib memfilter `user_id == currentUser.uid`. Jangan melonggarkan `firestore.rules` atau `storage.rules` tanpa diminta.

## Gaya kode Flutter
- State management: Riverpod. Navigasi: go_router.
- Pisahkan UI, logika, dan data (UI tidak memanggil Firebase langsung; lewat repository).
- Gunakan model immutable (`copyWith`, `fromMap`, `toMap`), `const` constructor bila bisa.
- Semua warna, ukuran font, dan radius diambil dari `core/theme`. Dilarang menulis hex warna atau angka ajaib di widget.
- Tangani state loading, error, dan kosong di setiap layar (pakai widget umum di `core/widgets`).
- Tangani error Firebase dengan pesan ramah berbahasa Indonesia, jangan tampilkan stack trace ke pengguna.
- Jangan memakai API yang sudah deprecated. Jalankan `dart format` dan pastikan `flutter analyze` bersih.
- Aksesibilitas: target sentuh minimal 48x48 dp, tambahkan `Semantics` pada gambar dan ikon tombol.

## Cloud Functions
- TypeScript, validasi input, periksa `request.auth`, kembalikan error terstruktur (`HttpsError`).
- Kuota dan moderasi dijalankan di server, tidak boleh bergantung pada klien.

## Cara bekerja
- Jika permintaan ambigu, ajukan maksimal 2 pertanyaan klarifikasi singkat, lalu lanjut dengan asumsi terbaik dan sebutkan asumsinya.
- Setelah selesai, tulis ringkasan: file yang dibuat/diubah, cara menjalankan/menguji, dan hal yang masih perlu dilakukan manual (misalnya setup di Firebase Console).
- Tambahkan test untuk logika penting (model, repository, validator). Jangan menghapus test yang ada agar test lolos.
- Jangan mengubah file di luar cakupan tugas. Jika perlu, jelaskan dulu alasannya.
