# 📑 README.md: Event Kampus Locator

## 🚀 Fitur Utama & Capaian Tugas

Aplikasi ini mendemonstrasikan:

1. **Lokasi & Tracking:** One-Time Location, Continuous Stream Tracking, dan Toggle Akurasi.
2. **Geocoding:** Menampilkan alamat (Reverse Geocoding) dan menghitung jarak ke event.
3. **Peta:** Integrasi Peta OpenStreetMap (OSM) sebagai alternatif bebas API Key.

## 🏃 Cara Menjalankan Proyek

1. **Clone/Unzip** proyek.
2. Buka terminal di direktori proyek.
3. Unduh dependencies: `flutter pub get`
4. Pastikan **Izin Lokasi** di _AndroidManifest.xml_ sudah dikonfigurasi.
5. Jalankan di perangkat fisik: `flutter run`

## 🔒 Kebijakan Privasi & Catatan Izin Lokasi

- **Kebijakan Privasi Ringkas:** Data lokasi pengguna digunakan **hanya saat aplikasi berjalan** (`NSLocationWhenInUseUsageDescription`) untuk tujuan _tracking_ dan menghitung jarak ke _event_. Data lokasi **tidak disimpan** atau **dikirim** ke pihak ketiga.
- **Catatan Izin Lokasi:**
  - Kami menggunakan **Toggle Akurasi** (`High` vs `Low`). Akurasi **High** memberikan data GPS yang presisi tetapi **lebih boros baterai**. Akurasi **Low** lebih hemat tetapi kurang presisi.
  - **Distance Filter** diatur ke 10 meter untuk mencegah _update_ lokasi yang terlalu sering saat pengguna tidak bergerak.
