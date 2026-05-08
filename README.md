# CareConnect

A premium elderly care coordination mobile application built with Flutter, designed for Kolej communities. CareConnect replaces scattered WhatsApp messages and paper notes with one organized platform for medications, appointments, daily care notes, reminders, and reports.

## Users

| Role | Description |
|------|-------------|
| Caregiver | Manages daily care hands-on — adds medications, logs appointments, writes care notes |
| Family Member | Monitors remotely — read-only dashboard, receives alerts, views reports |

## Modules

**Sprint 1 — Authentication & Profile**
Register, login, logout, forgot password, and profile management for both Caregiver and Family Member roles.

**Sprint 2 — Medication Management**
Add, view, edit, and delete medications. Mark as Given, Missed, or Pending. Receive missed medication alerts and reminders.

**Sprint 3 — Appointment Management**
Add, view, edit, and delete appointments. Google Calendar sync, Google Maps navigation, reminder notifications.

**Sprint 4 — Daily Care Reports & Smart Monitoring**
Log daily care notes (meals, mood, blood pressure, sleep). Generate care summary reports. View health trend charts. Emergency alert support.

## Tech Stack

- **Frontend / Mobile App:** Flutter, Dart
- **Backend / Cloud Services:** Firebase Authentication, Cloud Firestore
- **Database:** Cloud Firestore
- **Storage:** Firebase Storage

## Project Structure

CareConnect uses a feature-based layered Flutter folder structure:
lib/
├── main.dart
├── core/
│   ├── constants/       # App colors, text styles, spacing
│   ├── theme/           # App-wide theme configuration
│   ├── utils/           # Validators and helper functions
│   └── widgets/         # Reusable UI components
├── data/
│   ├── models/          # Shared models e.g. UserModel, MedicationModel
│   ├── repositories/    # Shared app-level data logic
│   └── services/        # Firebase Auth and Firestore service functions
└── features/
├── onboarding/       # Welcome and role selection screens
├── auth/             # Login, register, forgot password
├── caregiver/        # Caregiver home dashboard
├── family/           # Family member monitoring dashboard
├── medications/      # Medication tracker and management
├── appointments/     # Appointment scheduling and calendar sync
├── care_notes/       # Daily care notes logging
├── reports/          # Care summary reports and charts
└── notifications/    # Reminders and alerts

## Getting Started

To run this project locally:

```bash
git clone https://github.com/fatemaj6/MobileApplicationProject_Shiftrs.git
cd MobileApplicationProject_Shiftrs
flutter pub get
flutter run
```

Make sure Flutter is installed and an emulator or physical device is running before executing the `flutter run` command.
