# SPEC: Lore (Fase 1 / MVP)

> Dokumen ini adalah sumber kebenaran untuk Copilot. Kerjakan HANYA yang ada di bagian "Cakupan Fase 1". Jangan menambah fitur di luar itu.

## 1. Ringkasan
**Lore** adalah aplikasi mobile (Android + iOS) untuk menyimpan kenangan pribadi: menulis cerita, menambah foto/audio asli, atau membuat ilustrasi AI dari cerita. Slogan: "Save your lore. Biar kenangan gak ilang."
Target pengguna: Gen Z. Nada UI dan teks: santai, hangat, campur Indonesia-Inggris, tidak menggurui. Semua data bersifat privat per pengguna.

## 2. Cakupan Fase 1 (WAJIB)
1. Autentikasi: daftar/login email+password, Google Sign-In, lupa kata sandi, logout.
2. CRUD kenangan: judul, cerita, tanggal perkiraan, kategori, suasana hati.
3. Unggah foto (maks 5 per kenangan) dan 1 berkas audio opsional.
4. Linimasa kenangan (kronologis, per tahun) dengan filter kategori.
5. Detail kenangan: lihat, ubah, hapus (hapus juga membersihkan file di Storage).
6. Ilustrasi AI dasar ("Lore Studio"): pilih gaya, pratinjau, terima/ulang/buang. Dipanggil lewat Cloud Function.
7. Kartu "Lore Hari Ini" di beranda (satu kenangan acak, tanpa notifikasi push).
8. Kunci biometrik opsional (sidik jari/Face ID) saat membuka aplikasi.
9. Dukungan offline: daftar kenangan tetap bisa dibuka tanpa internet (cache Firestore).
10. Mode terang dan gelap.

## 3. DI LUAR CAKUPAN (jangan dikerjakan)
Cerita suara + transkripsi, Lore Prompt, orang & album, pencarian cerdas, notifikasi push, Time Capsule, Ruang Bersama, Lore Book PDF, Mode Peringatan, Lore Wrapped, langganan/pembayaran.

## 4. Tech Stack
| Lapisan | Pilihan |
|---|---|
| Framework | Flutter (stable terbaru), Dart null-safety |
| State | Riverpod (flutter_riverpod, gunakan riverpod_annotation bila cocok) |
| Navigasi | go_router |
| Backend | Firebase: Auth, Cloud Firestore, Storage, Cloud Functions (Node.js + TypeScript), App Check |
| Paket penting | firebase_core, firebase_auth, google_sign_in, cloud_firestore, firebase_storage, cloud_functions, image_picker, flutter_image_compress, file_picker, local_auth, intl, cached_network_image, google_fonts |
| Uji | flutter_test, mocktail, Firebase Emulator Suite |

Aturan: kunci API layanan AI TIDAK BOLEH ada di kode Flutter. Hanya ada di Cloud Functions (Secret Manager / environment config).

## 5. Struktur Folder
```
lib/
  core/
    theme/            (app_colors.dart, app_theme.dart, app_text_styles.dart)
    constants/
    utils/            (date_utils.dart, validators.dart)
    widgets/          (widget umum: tombol, kartu, loading, empty state)
    router/           (app_router.dart)
  data/
    models/           (user_model.dart, memory_model.dart, media_item.dart)
    repositories/     (auth_repository.dart, memory_repository.dart, storage_repository.dart, illustration_repository.dart)
  domain/             (entitas/use case ringan bila perlu)
  features/
    auth/             (login, register, forgot_password)
    home/             (home_screen, lore_hari_ini_card)
    memories/         (timeline, memory_detail, memory_form)
    illustration/     (lore_studio_screen)
    settings/         (settings_screen, biometric_lock)
  main.dart
functions/            (Cloud Functions TypeScript)
firestore.rules
storage.rules
firestore.indexes.json
```

## 6. Design Tokens
**Warna (light):**
- Krem Senja (background): `#FBF3E4`
- Surface kartu: `#FFFFFF` dengan border `#E8D9BC`
- Sepia Tua (primary): `#8B5E3C`
- Terakota Lembut (accent): `#C77D5B`
- Biru Kabut (info/link): `#6F8FAF`
- Hijau Sage (sukses/fitur AI): `#8FA68E`
- Cokelat Malam (teks utama): `#3B2A20`

**Warna (dark):** background `#2B2118`, surface `#3B2A20`, teks `#F3E6CE`, primary `#C77D5B`. Jangan pakai hitam pekat.

**Tipografi:** judul memakai serif lembut (Lora), isi memakai Nunito. Ukuran dasar 16 sp, line height longgar (1.5).
**Bentuk:** sudut membulat 16 px (kartu) dan 20 px (tombol besar), bayangan sangat tipis. Foto ditampilkan dengan bingkai ala polaroid.
**Gerak:** transisi 250-350 ms, lembut. Hormati pengaturan "reduce motion".
**Aksesibilitas:** kontras teks minimal 4.5:1, target sentuh minimal 48x48 dp, semua gambar punya semantic label.
**Label AI:** setiap gambar hasil AI wajib menampilkan chip "Ilustrasi AI".

## 7. Model Data (Firestore)

### users/{uid}
| Field | Tipe | Catatan |
|---|---|---|
| name | string | nama panggilan |
| email | string | |
| created_at | timestamp | |
| settings | map | `{ theme: "system|light|dark", biometric_lock: bool, default_style: string }` |
| ai_quota | map | `{ used_today: number, reset_at: timestamp }` (hanya boleh ditulis server) |

### memories/{memoryId}
| Field | Tipe | Catatan |
|---|---|---|
| user_id | string | UID pemilik |
| title | string | wajib, 1-100 karakter |
| story | string | opsional, maks 5000 karakter |
| memory_date | map | `{ year: int, month?: int, day?: int, precision: "year\|month\|day", sort_key: int }` |
| category | string | `Nasihat, Liburan, Lucu, Keluarga, Teman, Lainnya` |
| mood | string | `hangat, haru, lucu, rindu, bangga` |
| media | array<map> | `[{ type: "photo\|audio", url, path, size, duration? }]` maks 5 foto + 1 audio |
| ai_illustration | map? | `{ url, path, style, status: "pending\|done\|failed", generated_at }` |
| is_favorite | bool | default false |
| created_at / updated_at | timestamp | |

`sort_key` dihitung = `year*10000 + (month ?? 0)*100 + (day ?? 0)` agar tanggal perkiraan tetap bisa diurutkan.

**Indeks komposit:**
- `memories`: `user_id ASC, memory_date.sort_key DESC`
- `memories`: `user_id ASC, category ASC, memory_date.sort_key DESC`

## 8. Aturan Keamanan

### firestore.rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow create: if request.auth != null && request.auth.uid == uid;
      allow update: if request.auth != null && request.auth.uid == uid
        && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['ai_quota']);
      allow delete: if false;
    }
    match /memories/{id} {
      allow create: if request.auth != null
        && request.resource.data.user_id == request.auth.uid
        && request.resource.data.title is string
        && request.resource.data.title.size() > 0
        && request.resource.data.title.size() <= 100;
      allow read, delete: if request.auth != null && resource.data.user_id == request.auth.uid;
      allow update: if request.auth != null
        && resource.data.user_id == request.auth.uid
        && request.resource.data.user_id == request.auth.uid;
    }
  }
}
```

### storage.rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow write: if request.auth != null && request.auth.uid == uid
        && request.resource.size < 10 * 1024 * 1024;
    }
  }
}
```
Path Storage: `users/{uid}/memories/{memoryId}/photo_{n}.jpg`, `.../audio.m4a`, `.../ai_illustration.png`.

## 9. Cloud Function: `generateIllustration` (callable, TypeScript)
**Input:** `{ memoryId: string, style: "watercolor" | "pencil" | "vintage" | "storybook" }`
**Langkah:**
1. Tolak jika tidak login (`unauthenticated`) atau bukan pemilik kenangan (`permission-denied`).
2. Cek kuota: maks **5 ilustrasi per hari per pengguna** (reset tiap 24 jam), baca/tulis `users/{uid}.ai_quota` memakai Admin SDK. Jika habis, lempar `resource-exhausted` dengan pesan ramah.
3. Moderasi sederhana: tolak jika cerita kosong atau terdeteksi konten tidak pantas.
4. Ringkas cerita jadi deskripsi visual (adegan, suasana, 3 warna dominan), gabungkan dengan templat gaya. Jangan meniru wajah orang nyata; hasilkan ilustrasi bergaya.
5. Panggil API gambar (penyedia dibuat mudah diganti lewat satu fungsi `callImageApi`; kunci dari Secret Manager).
6. Simpan hasil ke Storage `users/{uid}/memories/{memoryId}/ai_illustration.png`, perbarui `memories/{memoryId}.ai_illustration`.
7. Kembalikan `{ url, style }`. Jika gagal, set `status: "failed"` dan lempar error terstruktur.

**Templat gaya:**
- watercolor: "soft watercolor illustration, warm sepia tones, gentle light, nostalgic mood, no text, no logos"
- pencil: "delicate pencil sketch on cream paper, soft shading, nostalgic, no text"
- vintage: "vintage faded photograph look, warm film grain, 1990s feel, no text"
- storybook: "children's storybook illustration, cozy colors, whimsical, no text"

## 10. Layar & Perilaku
1. **Splash/Onboarding:** 3 slide singkat (Simpan, Ceritakan, Wariskan), tampil sekali.
2. **Login/Daftar:** tombol Google dan Email, teks singkat tentang privasi, tautan lupa kata sandi.
3. **Beranda:** sapaan sesuai waktu (contoh: "Sore, Rani!"), kartu **Lore Hari Ini**, kenangan terbaru, FAB tambah (+).
4. **Linimasa:** daftar per tahun, chip filter kategori, paginasi 20 item, empty state ramah.
5. **Detail Kenangan:** gambar besar (foto atau ilustrasi AI), pemutar audio, cerita, tombol ubah/hapus/favorit.
6. **Form Kenangan (tambah/ubah):** judul, cerita, tanggal perkiraan (tahun wajib, bulan/hari opsional), kategori, mood, foto, audio, tombol "Buat Ilustrasi AI". Draf tersimpan otomatis secara lokal.
7. **Lore Studio:** pilih gaya, tombol "Buat", pratinjau, tombol Pakai / Ulangi / Buang.
8. **Pengaturan:** tema, kunci biometrik, logout, tentang privasi.

## 11. Kriteria Selesai Fase 1
- Semua layar di atas berfungsi di Android dan iOS (minimal Android terverifikasi).
- Pengguna A tidak bisa membaca/menulis data pengguna B (terbukti lewat uji emulator).
- Kunci API AI tidak ada di repositori Flutter.
- `flutter analyze` bersih, `flutter test` hijau.
- Kenangan yang dibuat saat offline tersinkron saat online lagi.
- Tidak ada teks atau fitur dari daftar "di luar cakupan".
