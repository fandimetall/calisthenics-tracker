# Coding Workflow Protocol — Calisthenics Tracker

File ini WAJIB dibaca oleh SEMUA agent (Friday, Jarvis, Claude Code, Codex) sebelum memulai task coding apapun di project ini.

## Urutan Eksekusi (tiap task coding)

### 1. Cek Coding Journal
- Baca `D:/Porto/calisthenics_tracker/.hermes/coding_journal.md`
- Cari entry yang relevan dengan masalah saat ini
- Kalau ketemu → adapt solusi lama dulu, jangan mulai dari nol

### 2. CodeGraph (blast-radius)
- Jalankan `codegraph explore <keyword>` atau `codegraph impact <symbol>` SEBELUM edit kode
- Pastikan tahu dampak perubahan ke file/fungsi lain

### 3. Referensi API (kalau ada library eksternal)
- Pakai Context7 MCP: `resolve-library-id` + `query-docs`
- Pastikan API signature mutakhir, jangan halusinasi

### 4. Eksekusi
- Kode paling minimum yang bekerja
- Input validation, error handling, security TIDAK boleh disederhanakan

### 5. Verifikasi
- Linter: `dart analyze lib/ test/` → 0 issues
- Test: `flutter test` → semua pass
- E2E bila UI berubah

### 6. Git Commit (WAJIB)
- `git add . && git commit -m "type(scope): deskripsi"`
- Type: `feat` / `fix` / `refactor` / `test` / `docs`
- Push: `git push origin master`
- Deploy web: build → copy ke public/ → push gh-pages

### 7. Log ke Coding Journal
- Append entry ke `.hermes/coding_journal.md`
- Format: Task, Approach, Problems, Solution, Files, Tests, Lesson
- Error message asli, jangan paraphrase
- Lesson harus actionable (bukan "hati-hati")

## Kredensial
- JANGAN simpan API key/secret di chat atau kode
- Ambil dari `.env` atau environment variable
- Supabase: `https://kbmldbqnkjkrspbjcoyo.supabase.co`

## Stack
- Flutter 3.29.3 Web + Mobile
- Supabase Cloud (auth, database, RLS)
- Deploy: Vercel + GitHub Pages
