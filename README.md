# 💙 CareConnect

A premium elderly care coordination mobile application built with Flutter. CareConnect replaces scattered WhatsApp messages and paper notes with one organised platform for medications, appointments, daily care notes, reminders, and reports.

---

## 👥 Users

| Role | Description |
|------|-------------|
| 🧑‍⚕️ Caregiver | Manages daily care hands-on — adds medications, logs appointments, writes care notes |
| 👨‍👩‍👧 Family Member | Monitors remotely — read-only dashboard, receives alerts, views reports |

---

## 📦 Modules

**Module 1 — Authentication & Profile**
Register, login, logout, forgot password, and profile management for both Caregiver and Family Member roles.

**Module 2 — Medication Management**
Add, view, edit, and delete medications. Mark as Given, Missed, or Pending. Receive missed medication alerts and reminders.

**Module 3 — Appointment Management**
Add, view, edit, and delete appointments. Google Calendar sync, Google Maps navigation, reminder notifications.

**Module 4 — Daily Care Reports & Smart Monitoring**
Log daily care notes (meals, mood, blood pressure, sleep). Generate care summary reports. View health trend charts. Emergency alert support.

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| 📱 Frontend / Mobile App | Flutter, Dart |
| 🔐 Authentication | Firebase Authentication |
| ☁️ Database | Cloud Firestore |
| 🗄️ Storage | Firebase Storage |

---

## 🗂️ Project Structure

CareConnect uses a feature-based layered Flutter folder structure:

lib/
├── main.dart
├── core/
│   ├── constants/        # App colors, text styles, spacing
│   ├── theme/            # App-wide theme configuration
│   ├── routes/           # Named route definitions
│   ├── utils/            # Validators and helper functions
│   └── widgets/          # Reusable UI components
│
├── data/
│   ├── models/           # Shared models (UserModel, MedicationModel)
│   ├── repositories/     # Shared app-level data logic
│   └── services/         # Firebase Auth & Firestore services
│
└── features/
    ├── onboarding/       # Welcome & role selection
    ├── auth/             # Login & forgot password
    ├── caregiver/        # Caregiver dashboard
    ├── family/           # Family monitoring dashboard
    ├── medications/      # Medication tracking
    ├── appointments/     # Scheduling & calendar sync
    ├── care_notes/       # Daily care notes
    ├── reports/          # Care reports & charts
    └── notifications/    # Reminders & alerts
---

## 🚀 Getting Started

To run this project locally:

```bash
git clone https://github.com/fatemaj6/MobileApplicationProject_Shiftrs.git
cd MobileApplicationProject_Shiftrs
flutter pub get
flutter run
```

> Make sure Flutter is installed and an emulator or physical device is running before executing `flutter run`.




