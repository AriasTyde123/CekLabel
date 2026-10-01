# Architecture.md — Lecturer GitHub Tracker

> Dokumen arsitektur untuk aplikasi full-stack sederhana bernama **Lecturer GitHub Tracker**.
> Tujuan: membantu dosen memantau aktivitas commit GitHub tiap mahasiswa. Data commit hanya diambil saat dosen menekan tombol, disimpan di MySQL, dan ditampilkan sebagai ringkasan progres di dashboard.
> Catatan konteks: file ini saat ini berada di repo `CekLabel` (Flutter offline-first). Spesifikasi di bawah ini adalah untuk proyek berbeda (`lecturer-github-tracker`, monorepo TypeScript). Jangan mencampur kedua tech-stack tersebut.

---

## 1. Ringkasan & Prinsip Arsitektur

* **Tipe aplikasi:** Full-stack web monorepo (npm workspaces), REST API tanpa auth v1. Asumsi satu dosen memakai aplikasi.
* **Prinsip utama:**
  1. `Manual sync only` — frontend tidak pernah memanggil GitHub secara otomatis. Dashboard hanya membaca dari MySQL. Sinkronisasi terjadi hanya via `POST .../sync` yang dipicu tombol.
  2. `Never delete / never overwrite commits` — sinkronisasi bersifat append-only. Dedup berdasarkan `(RepositoryId, Sha)`.
  3. `Single source of truth untuk tipe` — semua model domain, enum, DTO didefinisikan sekali di `packages/shared`, diimpor oleh `apps/web` dan `apps/api`. Tidak ada duplikasi definisi. Tipe Prisma tetap di backend saja.
  4. `Clean folder structure` — pemisahan jelas: routes/controllers, services, prisma, UI pages/components.
  5. `Public-first GitHub` — dukung repo publik tanpa token; jika `GITHUB_TOKEN` ada, pakai sebagai Bearer token untuk menaikkan rate limit.

---

## 2. Tech Stack

| Lapisan | Teknologi |
|---|---|
| Frontend | React + TypeScript + Vite + Tailwind CSS |
| Backend | Node.js + TypeScript + Express |
| Database | MySQL 8 (via Docker Compose) |
| ORM | Prisma (migrations + seed) |
| API style | REST API, JSON dengan property names PascalCase |
| GitHub | GitHub REST API `GET /repos/{Owner}/{RepositoryName}/commits` |
| Monorepo | npm workspaces: `apps/web`, `apps/api`, `packages/shared` |
| Config | `.env` + `.env.example` (`DATABASE_URL`, `GITHUB_TOKEN` opsional) |

Versi Node LTS, Prisma terbaru yang kompatibel MySQL 8.

---

## 3. Struktur Monorepo

```text
lecturer-github-tracker/
  package.json                    # workspaces: apps/*, packages/*
  tsconfig.base.json
  docker-compose.yml              # MySQL service
  .env.example
  README.md
  apps/
    web/                          # React + Vite + Tailwind
      package.json                # dependensi @lecturer-github-tracker/shared
      vite.config.ts
      tailwind.config.js
      src/
        main.tsx
        App.tsx                   # routing + layout + Course selector global
        api/Client.ts             # fetch wrapper ke /api
        pages/
          DashboardPage.tsx
          CourseListPage.tsx
          StudentListPage.tsx
          RepositoryListPage.tsx
          StudentProgressPage.tsx
        components/
          SummaryCard.tsx
          StudentTable.tsx
          CommitTable.tsx
          CourseForm.tsx
          StudentForm.tsx
          RepositoryForm.tsx
          StatusBadge.tsx
          ConfirmDialog.tsx
          EmptyState.tsx
    api/                          # Express + Prisma
      package.json                # dependensi @lecturer-github-tracker/shared, @prisma/client
      prisma/
        schema.prisma
        migrations/
        seed.ts
      src/
        index.ts                  # bootstrap Express
        App.ts                    # create app, middleware, routes
        routes/
          CourseRoutes.ts
          StudentRoutes.ts
          RepositoryRoutes.ts
          SyncRoutes.ts
          DashboardRoutes.ts
        controllers/
          CourseController.ts
          StudentController.ts
          RepositoryController.ts
          SyncController.ts
          DashboardController.ts
        services/
          CourseService.ts
          StudentService.ts
          RepositoryService.ts
          GithubService.ts
          SyncService.ts
          DashboardService.ts
        prisma/Client.ts
        utils/
          ParseRepositoryUrl.ts
          MapToShared.ts          # mapping Prisma -> shared API models
          HttpError.ts
  packages/
    shared/                       # @lecturer-github-tracker/shared
      package.json
      tsconfig.json
      src/
        models/Course.ts
        models/Student.ts
        models/Repository.ts
        models/Commit.ts
        enums/ActivityStatus.ts
        dto/DashboardResponse.ts
        dto/SyncResult.ts
        constants/ActivityRules.ts # mis. InactiveThresholdDays = 14
        index.ts
```

Aturan workspace:

* `apps/web` dan `apps/api` mengimpor tipe dari `@lecturer-github-tracker/shared`. Frontend dilarang mengimpor tipe Prisma.
* Backend memetakan entity Prisma ke model shared sebelum dikembalikan sebagai respons.
* Konfigurasi TypeScript paths, script build/dev dibuat agar semua package berhasil dikompilasi (`tsc -b` atau Project References).

Script root contoh:

```json
{
  "scripts": {
    "Build": "npm run build -ws",
    "Dev:Api": "npm run dev -w apps/api",
    "Dev:Web": "npm run dev -w apps/web",
    "Migrate": "npm run migrate -w apps/api",
    "Seed": "npm run seed -w apps/api"
  }
}
```

---

## 4. Model Domain & Database

### 4.1 Entitas (Shared Models — PascalCase)

Semua interface/type, enum, class, DTO, dan JSON property memakai PascalCase. Local variable boleh camelCase. Baris kode dijaga < 150 karakter bila memungkinkan. Tanpa komentar kecuali benar-benar perlu.

`packages/shared/src/models/Course.ts`:

```ts
export interface Course { Id: string; Name: string; Semester: string; Year: number; CreatedAt: string; }
```

`packages/shared/src/models/Student.ts`:

```ts
export interface Student { Id: string; CourseId: string; StudentNumber: string; Name: string; Email: string; GithubUsername: string; CreatedAt: string; }
```

`packages/shared/src/models/Repository.ts`:

```ts
export interface Repository { Id: string; StudentId: string; Name: string; RepositoryUrl: string; Owner: string; RepositoryName: string; IsActive: boolean; LastSyncedAt: string | null; CreatedAt: string; }
```

`packages/shared/src/models/Commit.ts`:

```ts
export interface Commit { Id: string; RepositoryId: string; Sha: string; Message: string; AuthorName: string; AuthorEmail: string; CommittedAt: string; CommitUrl: string; CreatedAt: string; }
```

`packages/shared/src/enums/ActivityStatus.ts`:

```ts
export enum ActivityStatus { Active = "ACTIVE", Inactive = "INACTIVE", NoCommit = "NO_COMMIT" }
```

`packages/shared/src/dto/SyncResult.ts`:

```ts
export interface SyncResult { RepositoryId: string; FetchedCommitCount: number; NewCommitCount: number; ExistingCommitCount: number; LastSyncedAt: string; Message: string; }
```

`packages/shared/src/dto/DashboardResponse.ts`:

```ts
import { ActivityStatus } from "../enums/ActivityStatus";
export interface CourseSummary { TotalStudents: number; TotalRepositories: number; TotalCommits: number; ActiveStudents: number; InactiveStudents: number; StudentsWithoutCommits: number; }
export interface StudentProgress { StudentId: string; StudentName: string; StudentNumber: string; RepositoryCount: number; TotalCommits: number; LatestCommitAt: string | null; ActivityStatus: ActivityStatus; }
export interface DashboardResponse { Summary: CourseSummary; Students: StudentProgress[]; }
```

### 4.2 Skema Prisma (Backend only)

Model Prisma memakai PascalCase untuk nama model agar selaras dengan aturan. Contoh `prisma/schema.prisma`:

```prisma
model Course {
  Id        String    @id @default(cuid())
  Name      String
  Semester  String
  Year      Int
  CreatedAt DateTime  @default(now())
  Students  Student[]
  @@map("courses")
}

model Student {
  Id             String       @id @default(cuid())
  CourseId       String
  StudentNumber  String
  Name           String
  Email          String
  GithubUsername String
  CreatedAt      DateTime     @default(now())
  Course         Course       @relation(fields: [CourseId], references: [Id], onDelete: Cascade)
  Repositories   Repository[]
  @@map("students")
}

model Repository {
  Id             String    @id @default(cuid())
  StudentId      String
  Name           String
  RepositoryUrl  String
  Owner          String
  RepositoryName String
  IsActive       Boolean   @default(true)
  LastSyncedAt   DateTime?
  CreatedAt      DateTime  @default(now())
  Student        Student   @relation(fields: [StudentId], references: [Id], onDelete: Cascade)
  Commits        Commit[]
  @@map("repositories")
}

model Commit {
  Id           String     @id @default(cuid())
  RepositoryId String
  Sha          String
  Message      String     @db.Text
  AuthorName   String
  AuthorEmail  String
  CommittedAt  DateTime
  CommitUrl    String
  CreatedAt    DateTime   @default(now())
  Repository   Repository @relation(fields: [RepositoryId], references: [Id], onDelete: Cascade)
  @@unique([RepositoryId, Sha])
  @@map("commits")
}
```

Relasi: Course 1—N Student, Student 1—N Repository, Repository 1—N Commit. Hapus Course/Student/Repository boleh cascade, tetapi sinkronisasi tidak pernah menghapus Commit secara logika bisnis.

### 4.3 Database Rules (wajib ditegakkan di `SyncService`)

* `Commit` unik berdasarkan `(RepositoryId, Sha)` via `@@unique`.
* Jangan pernah menghapus data commit saat sinkronisasi.
* Jangan pernah mengganti/menimpa record commit yang ada.
* Saat fetch ulang, hanya simpan commit yang belum ada (`Sha` belum tersimpan untuk `RepositoryId` tersebut).
* Update `LastSyncedAt` hanya setelah sinkronisasi sukses.
* Gunakan Prisma migrations + seed: 1 contoh course, 3 students, repo GitHub publik.

---

## 5. Backend Architecture

Lapisan: `Routes -> Controllers -> Services -> Prisma`. Controllers tipis (validasi input + mapping status HTTP). Logic di Services.

### 5.1 CRUD Course

* Service: `CourseService` (Create, List, Detail, Update, Delete).
* Validasi: `Name`, `Semester`, `Year` wajib.

### 5.2 CRUD Student (dalam Course)

* Service: `StudentService`.
* `CourseId` berasal dari path untuk create/list. Validasi `StudentNumber`, `Name`, `GithubUsername` wajib.

### 5.3 CRUD Repository (milik Student)

* Service: `RepositoryService` + util `ParseRepositoryUrl`.
* Validasi & parsing URL GitHub mis. `https://github.com/owner/repository`:
  * Terima dengan/tanpa trailing slash dan `.git`.
  * Tolak URL non-github, path tidak lengkap, atau mengandung spasi.
  * Hasil parsing mengisi `Owner`, `RepositoryName`, normalisasi `RepositoryUrl`.
* Field: `Name` (label tampilan), `RepositoryUrl`, `Owner`, `RepositoryName`, `IsActive`.

### 5.4 Manual GitHub Commit Synchronization

* `GithubService`: satu fungsi `FetchCommits(Owner, RepositoryName)` memanggil `GET https://api.github.com/repos/{Owner}/{RepositoryName}/commits?per_page=100`. Jika `GITHUB_TOKEN` ada, kirim header `Authorization: Bearer <token>` dan `Accept: application/vnd.github+json`. Tangani pagination dasar (hingga N halaman, mis. 5) bila perlu.
* `SyncService.SyncOneRepository(RepositoryId)`:
  1. Load repository dari DB.
  2. Fetch commits dari GitHub.
  3. Ambil daftar `Sha` yang sudah ada untuk `RepositoryId` tersebut.
  4. Insert hanya yang baru via `createMany(skipDuplicates: true)` atau insert selektif.
  5. Update `LastSyncedAt = now()`.
  6. Kembalikan `SyncResult` berisi `RepositoryId, FetchedCommitCount, NewCommitCount, ExistingCommitCount, LastSyncedAt, Message`.
* `SyncService.SyncCourse(CourseId)`: ambil semua repository aktif (`IsActive = true`) dalam course, panggil sync satu-per-satu, agregasikan hasil. Repository gagal tidak menghentikan keseluruhan; catat error per-repo dan lanjutkan.
* Error bermakna (status + pesan Indonesia di frontend):
  * Repo privat/invalid/unavailable (404) -> "Repositori tidak ditemukan atau bersifat privat."
  * Rate limit (403 + `X-RateLimit-Remaining: 0`) -> "Batas permintaan GitHub tercapai. Coba lagi nanti atau isi GITHUB_TOKEN."
  * Network/timeout -> "Gagal menghubungi GitHub."

### 5.5 Dashboard API

* `DashboardService.GetCourseDashboard(CourseId)`:
  * `TotalStudents`: hitung students dalam course.
  * `TotalRepositories`: hitung repositories milik students tersebut.
  * `TotalCommits`: hitung commits dari repositories tersebut.
  * Per student: `RepositoryCount`, `TotalCommits`, `LatestCommitAt` (max `CommittedAt`).
  * `ActivityStatus`:
    * `NO_COMMIT` bila tidak ada commit tersimpan.
    * `INACTIVE` bila commit terakhir > 14 hari.
    * `ACTIVE` bila commit terakhir <= 14 hari.
  * `ActiveStudents`, `InactiveStudents`, `StudentsWithoutCommits` diagregasi dari status tiap student.
* `DashboardService.GetStudentProgress(StudentId)`: info student + daftar repositories + total/latest commit + tabel riwayat commit (Message, Author, Date, SHA, link).

Mapping Prisma -> shared dilakukan di `MapToShared.ts` agar JSON memakai PascalCase.

---

## 6. API Contract (Required Routes)

| Method | Route | Deskripsi |
|---|---|---|
| GET | `/api/courses` | List course |
| POST | `/api/courses` | Buat course |
| GET | `/api/courses/:Id` | Detail course |
| PUT | `/api/courses/:Id` | Ubah course |
| DELETE | `/api/courses/:Id` | Hapus course (konfirmasi di UI) |
| GET | `/api/courses/:CourseId/students` | List students dalam course |
| POST | `/api/courses/:CourseId/students` | Tambah student |
| PUT | `/api/students/:Id` | Ubah student |
| DELETE | `/api/students/:Id` | Hapus student |
| GET | `/api/students/:Id/repositories` | List repositories milik student |
| POST | `/api/students/:Id/repositories` | Tambah repository (validasi URL) |
| PUT | `/api/repositories/:Id` | Ubah repository |
| DELETE | `/api/repositories/:Id` | Hapus repository |
| POST | `/api/repositories/:Id/sync` | Sinkronisasi satu repository, kembalikan `SyncResult` |
| POST | `/api/courses/:CourseId/sync` | Sinkronisasi semua repository aktif dalam course |
| GET | `/api/courses/:CourseId/dashboard` | Ringkasan course + progres tiap student (`DashboardResponse`) |
| GET | `/api/students/:Id/progress` | Detail progres + riwayat commit satu student |

Semua respons sukses/error memakai envelope konsisten, contoh `{ Data, Message }` dengan property PascalCase. Error memakai status HTTP yang tepat (400 validasi, 404 tidak ditemukan, 502/429 untuk GitHub).

---

## 7. Frontend Architecture

* **Routing sederhana** (React Router): `/` (Course Management), `/courses/:CourseId/dashboard` (Dashboard), `/courses/:CourseId/students` (Student Management), `/students/:Id/repositories` (Repository Management), `/students/:Id/progress` (Student Progress Detail).
* **Data fetching:** `api/Client.ts` sebagai wrapper `fetch`. Dashboard hanya membaca dari MySQL saat dibuka; tidak ada panggilan GitHub otomatis. Sync hanya via tombol.
* **Halaman:**
  1. **Dashboard:** pemilih course, kartu ringkasan (total students, repositories, commits, active students, students without commits), tabel student (repository count, total commits, latest commit, status), tombol `Sinkronkan Semua Repositori`, state loading/sukses/error.
  2. **Course Management:** daftar courses, form buat/ubah, tombol buka dashboard.
  3. **Student Management:** daftar students dalam course terpilih, form tambah/ubah, tampilkan GitHub username.
  4. **Repository Management:** daftar repositories milik student, form tambah/ubah URL GitHub, tombol `Sinkronkan Commit`, tampilkan last sync + jumlah commit tersimpan.
  5. **Student Progress Detail:** info student, daftar repositories, total + latest commit, tabel riwayat (message, author, date, SHA, link ke GitHub).
* **Komponen:** `SummaryCard`, `StudentTable`, `CommitTable`, `StatusBadge`, `ConfirmDialog` (sebelum hapus), `EmptyState`, form terpisah per entitas.

### UI Requirements

* Semua label, tombol, pesan, validasi berbahasa Indonesia.
* Bersih & responsif (Tailwind), tabel sederhana, cards, badges, forms, dialog konfirmasi hapus, empty states.
* Warna badge: Active hijau, Inactive oranye, No Commit merah.
* Tanpa chart di v1.

---

## 8. GitHub Integration & Env

`.env.example`:

```text
DATABASE_URL="mysql://user:password@localhost:3306/lecturer_tracker"
GITHUB_TOKEN=""
PORT=3001
WEB_PORT=5173
```

* `docker-compose.yml` menjalankan MySQL 8 + volume persisten + healthcheck. Contoh service `db` port `3306`, kredensial sinkron dengan `DATABASE_URL`.
* Backend membaca `GITHUB_TOKEN` opsional; bila kosong tetap dukung repo publik.
* README wajib menjelaskan: instalasi, migrasi Prisma, seed, cara jalan backend/frontend, Docker, dan konfigurasi token GitHub.

---

## 9. Konvensi Kode

* Tanpa komentar kecuali benar-benar perlu.
* PascalCase untuk semua class, type, interface, enum, komponen React, model DB, API DTO, dan JSON property. Contoh: `StudentProgress`, `ActivityStatus`, `SyncResult`, `TotalCommits`.
* camelCase hanya untuk local variable.
* Jaga panjang baris < 150 karakter bila praktis.
* Struktur folder bersih & sederhana seperti di Bagian 3.

---

## 10. Deliverables & Kriteria Selesai

* Source frontend + backend lengkap, schema/migrasi/seed Prisma, Docker Compose MySQL, `.env.example`, README (instalasi, migrasi, seed, startup, Docker, token).
* Aplikasi berhasil build dan CRUD dasar + sinkronisasi commit manual terbukti bekerja: tambah course/student/repo, tekan sync, commit baru tersimpan tanpa menghapus yang lama, dashboard terupdate.

---

## 11. Out of Scope v1

* Tanpa autentikasi (satu dosen).
* Tanpa chart.
* Fokus repo publik dulu; privat hanya tampilkan error bermakna.
