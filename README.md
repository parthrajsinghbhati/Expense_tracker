# Smart Expense Tracker with Insights

A modern, premium Flutter application designed to help users track expenses efficiently and gain intelligent financial insights.

**Live Demo:** [https://expense-tracker-a3303.web.app](https://expense-tracker-a3303.web.app)

---

## 🚀 Approach and Architecture

This project follows a **Service-Oriented Architecture** with a focus on simplicity, reactivity, and performance.

### 1. Layered Structure
- **Models**: Plain Dart objects (e.g., `Expense`) with Firestore serialization logic.
- **Services**: The `ExpenseService` acts as the single source of truth for data operations. It handles Firebase interactions, data analysis, and complex business logic (like weekly comparisons).
- **Screens**: Dedicated widgets for main app flows (Expenses, Add Expense, Insights, Login).
- **Widgets**: Reusable UI components (e.g., `SpendingChartWidget`, `ExpenseCard`) to keep screens clean.

### 2. Reactive State Management
- Instead of using heavy state management libraries, the app leverages Flutter's native **`StreamBuilder`** and **`FutureBuilder`**.
- Data flows reactively from Cloud Firestore to the UI, ensuring real-time updates without manual refreshes.
- Internal UI state (like navigation) is managed using `StatefulWidget` and `setState`.

### 3. Modern Design System
- Built with **Material 3** for a fresh, tactile feel.
- Uses **Google Fonts (Outfit)** for premium typography.
- Implementation of **Glassmorphism** and subtle micro-animations (using `AnimatedSwitcher` and `AnimatedContainer`) to enhance user experience.

---

## 🛠 Backend Choice

### 1. Database: Cloud Firestore (NoSQL)
- **Why?** Real-time synchronization is crucial for financial tracking. Firestore's offline persistence and reactive streams make it a perfect fit for a mobile-first expense tracker.

### 2. Authentication: Firebase Auth
- **Why?** Provides secure, out-of-the-box support for email/password and anonymous authentication, allowing for a seamless user onboarding experience.

### 3. Smart Data Insights
- The app analyzes your spending patterns and provides data-driven feedback.
- It compares your current spending against previous periods and highlights major shifts or high-expenditure categories.

---

## ⚖️ Assumptions and Trade-offs

### 1. Local Filtering vs. Database Indexing
- **Trade-off**: The app fetches expenses filtered only by `userId` and performs sorting/date-range filtering **locally in Dart**.
- **Reasoning**: This avoids the need for complex **Composite Indexes** in Firestore, making the project easier to deploy and maintain for developers without requiring manual index configuration for every query combination.
- **Impact**: While slightly more memory-intensive on the client for users with *thousands* of expenses, it significantly speeds up development and improves flexibility for varied filter views.

### 2. Monday-Start Week
- **Assumption**: The "Weekly Comparison" logic assumes a standard calendar week starting on **Monday**. This simplifies the date math for calculating "Current Week" vs "Previous Week."

---

## 📁 Folder Structure

```text
lib/
  ├── models/          # Data models (Expense)
  ├── screens/         # Main navigation pages
  ├── services/        # Business logic & API calls (Firestore)
  ├── widgets/         # Reusable UI components
  └── firebase_options.dart  # Generated Firebase config
```

## ⚙️ Setup Instructions

1. **Clone the repo**
2. **Install dependencies**: `flutter pub get`
3. **Configure Firebase**:
   - Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
   - Run `flutterfire configure` to link your project.
4. **Run**: `flutter run`
