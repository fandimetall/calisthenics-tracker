# Coding Journal — Calisthenics Tracker

Backfill dari session 2026-09-08. Entry berikut direkonstruksi dari session history.

---

## 2026-09-08 supabase-register-no-response

**Task**: User klik Register di app web, tidak terjadi apa-apa (blank)

**Approach**: Cek database Supabase via REST API → user `fandimetall@gmail.com` sudah ada di `auth.users` tapi `currentUser` null pasca signUp. Root cause: Supabase default aktifkan email confirmation, membuat `session` null setelah signUp.

**Problems**:
1. `_client.auth.signUp()` return session null saat email confirmation aktif
2. `_checkSession()` di main.dart langsung redirect ke login karena `currentUser()` null
3. User tidak tahu apa yang terjadi (no feedback)

**Solution**: Tambah `RegisterOutcome` class dengan enum `RegisterStatus { success, needsEmailConfirmation, emailAlreadyInUse, error }`. Banner notice oranye di login screen. Auto-switch ke tab "Masuk" dengan email terisi. Listener `onAuthStateChange` → auto-redirect saat link verifikasi diklik.

**Files**: `lib/services/supabase_service.dart`, `lib/features/auth/login_screen.dart`, `lib/services/auth_service.dart`

**Tests**: 16/16 pass

**Lesson**: Supabase Auth signUp tidak menjamin session langsung aktif — selalu cek `res.session` dan handle `null` dengan UI feedback.

---

## 2026-09-08 email-verification-redirect-localhost

**Task**: Klik link verifikasi email Supabase redirect ke localhost:3000

**Approach**: Bukan bug di app — ini konfigurasi project Supabase. Site URL di dashboard masih localhost.

**Problems**:
1. `Site URL` di Supabase Dashboard masih `http://localhost:3000`
2. `Redirect URLs` belum termasuk domain Vercel

**Solution**: Instruksi ke user untuk ubah Site URL ke `https://calisthenics-tracker-sigma.vercel.app` dan Redirect URLs ke `https://calisthenics-tracker-sigma.vercel.app/**`. Tidak bisa lewat API tanpa PAT Supabase.

**Files**: Supabase Dashboard (bukan file app)

**Tests**: N/A

**Lesson**: Config redirect auth di Supabase Dashboard, bukan di app. Selalu cek Site URL setelah deploy ke domain baru.

---

## 2026-09-08 workout-session-grey-box

**Task**: Sesi latihan menampilkan kotak abu-abu kosong alih-alih daftar gerakan

**Approach**: Cek console log browser via Playwright → ketemu type error `String is not a subtype of num?`. Data `rest` tersimpan sebagai "60s" (string) tapi kode expect num. Tidak ganti format data (breaking change untuk existing users), buat parser fleksibel.

**Problems**:
1. `ex['rest'] as num?` crash saat value = "60s" (String)
2. `ex['sets'] as num?` juga bisa crash jika format berubah
3. Flutter Web release build swallow error → tampil kotak abu-abu tanpa pesan error

**Solution**: Tambah `_parseSets()` dan `_parseRest()` helper yang handle both num dan String (extract digits via regex). Ganti semua cast langsung ke helper. Safe map casting di itemBuilder.

**Files**: `lib/features/workout/workout_session_screen.dart`

**Tests**: 17/17 pass, Playwright E2E verified cards render

**Lesson**: Data dari database/JSON selalu parse defensively — pakai converter yang handle String/int/double, jangan `as num` langsung.

---

## 2026-09-08 dashboard-greeting-empty

**Task**: Dashboard menampilkan "Halo,  👋" (nama kosong) setelah login via Supabase Cloud

**Approach**: Login via Supabase tidak menyimpan session ke SharedPreferences lokal, jadi `_loadData()` di dashboard tidak menemukan `auth_session` key.

**Problems**:
1. `_client.auth.signInWithPassword()` berhasil tapi tidak bridge ke SharedPreferences
2. `_loadData()` hanya baca dari `auth_session` SharedPreferences, tidak fallback ke Supabase auth

**Solution**: Setelah signIn sukses, bridge session ke SharedPreferences: `sp.setString('auth_session', json.encode({...}))`. Tambah fallback `SupabaseService.instance.currentUser()` di `_loadData()`.

**Files**: `lib/services/supabase_service.dart`, `lib/features/dashboard/dashboard_screen.dart`

**Tests**: 17/17 pass

**Lesson**: Auth bridge wajib — setelah login supabase sukses, SELALU simpan session ke local store. Dual-source auth (Supabase + SharedPreferences) butuh sinkronisasi.

---

## 2026-09-08 xp-level-not-incrementing

**Task**: Selesai latihan, XP dan level tidak berubah di dashboard

**Approach**: `_finishWorkout()` menyimpan XP ke SharedPreferences tapi `DashboardScreen` tersimpan dalam `IndexedStack` — tidak rebuild saat kembali dari session screen.

**Problems**:
1. IndexedStack preserve state — `initState()` tidak dipanggil ulang
2. `_loadData()` hanya dijalankan di `initState()`, tidak ada trigger refresh
3. Level calculation bug: `_xp` langsung dipakai tanpa modulo 100

**Solution**: Tambah `GlobalKey<DashboardScreenState>` di MainShell. Panggil `_dashboardKey.currentState?.reload()` setelah session selesai. Fix level calculation: `_xp = totalXp % 100`, `_level = 1 + (totalXp ~/ 100)`. Tambah `last_completed_date_$email` check untuk streak dedup.

**Files**: `lib/features/dashboard/dashboard_screen.dart`, `lib/features/navigation/main_shell.dart`, `lib/features/workout/workout_session_screen.dart`

**Tests**: 17/17 pass

**Lesson**: IndexedStack preserve state — pakai GlobalKey + public reload method untuk cross-screen refresh.

---

## 2026-09-08 plan-not-advancing-next-day

**Task**: Selesai latihan hari Senin, dashboard tetap menampilkan hari Senin (tidak maju ke Rabu)

**Approach**: `_todayWorkoutDay` selalu mengambil `days[0]` (hari pertama) dari plan. Tidak ada tracking indeks hari aktif.

**Problems**:
1. `days[0]` hardcoded — tidak peduli sudah berapa kali latihan
2. Tidak ada field `current_day_index` di SharedPreferences
3. Tidak ada self-healing jika local state hilang (browser clear storage)

**Solution**: Tambah `current_day_index_$email` di SharedPreferences. Increment setelah workout selesai. Dashboard baca `currentDayIdx % days.length` untuk pick hari yang tepat. Tambah self-healing: kalau `totalXp == 0`, restore dari Supabase `workout_logs` table.

**Files**: `lib/features/dashboard/dashboard_screen.dart`, `lib/features/workout/workout_session_screen.dart`, `lib/services/supabase_service.dart`

**Tests**: 17/17 pass

**Lesson**: State progression (hari ke-N, level ke-M) wajib persist dan punya modulo wrap. Self-healing dari cloud backup kalau local state kosong.

---

## 2026-09-08 cloud-onboarding-not-restored

**Task**: Login di browser baru → masuk ke onboarding lagi padahal sudah pernah onboarding

**Approach**: `isOnboarded()` hanya cek SharedPreferences lokal. Browser baru = storage kosong = `false`.

**Problems**:
1. `isOnboarded()` hanya baca `sp.getBool('onboarded_$email')`
2. Tidak ada fallback ke Supabase untuk cek apakah data metrics sudah ada
3. Plan juga hilang dari local storage

**Solution**: Tambah fallback di `isOnboarded()`: kalau local false, cek `getUserMetrics(email)` di Supabase. Jika metrics ada, set local flag true + restore plan ke SharedPreferences. Tambah fungsi `getUserMetrics()` dan `getActiveWorkoutPlan()` di SupabaseService.

**Files**: `lib/services/auth_service.dart`, `lib/services/supabase_service.dart`

**Tests**: 17/17 pass

**Lesson**: Offline-first app butuh reverse sync — kalau local kosong tapi cloud punya data, pull dari cloud.
