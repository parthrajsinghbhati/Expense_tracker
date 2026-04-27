# Smart Expense Tracker with Insights

Clean Flutter + Material 3 expense tracker backed by Cloud Firestore.

**Live Demo:** [https://expense-tracker-a3303.web.app](https://expense-tracker-a3303.web.app)

## Folder Structure

```text
lib/
  main.dart
  models/
    expense.dart
  services/
    expense_service.dart
  screens/
    add_expense_screen.dart
    expense_list_screen.dart
    insights_screen.dart
  widgets/
    category_breakdown_bar.dart
    empty_state.dart
    expense_card.dart
```

## Firebase Setup

This code expects Firebase to be configured for the target mobile app.

```bash
flutter create .
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
flutter run
```

Firestore collection used by the app:

```text
expenses
  amount: number
  category: string
  date: timestamp
  note: string?
  createdAt: timestamp
```

Firestore may ask you to create indexes for category/date insight queries. Use the index link shown in the Firebase console error if prompted.
