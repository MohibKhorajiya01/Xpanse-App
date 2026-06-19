# 💸 Expense Tracker App

A mobile application built using **Flutter** and **Firebase** that helps users track their income, expenses, and manage personal budgets in a simple and organized way. The application allows users to record financial transactions, monitor spending habits, and analyze their financial activity through charts and statistics.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

---

## ✨ Features

- 💸 Track daily income and expenses
- 👛 Manage multiple wallets (Cash, Bank accounts, etc.)
- 🗂️ Category-based transaction management
- 📅 Monthly budget planning
- 📊 Financial insights with interactive charts
- 🔐 Secure user authentication
- ✉️ Email verification using Firebase Authentication
- ☁️ Cloud data storage using Firebase Firestore

---

## ⚙️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform mobile app development |
| **Dart** | Programming language used for application logic |
| **Firebase Authentication** | User authentication and email verification |
| **Firebase Firestore** | Cloud database for storing transactions and user data |
| **Riverpod** | State management |
| **fl_chart** | Data visualization for financial charts |

---

## 🔐 Authentication Flow

1. Users create an account using email and password.
2. After registration, Firebase Authentication sends a verification email to confirm the user's identity.
3. Once the email is verified, the user can log in and access their personal financial data securely.

---

## 💰 How the App Works

1. User registers using email and password
2. Firebase sends a verification email
3. After verification, the user logs into the application
4. Users can add income and expense transactions
5. Transactions are stored securely in Firebase Firestore
6. The app displays financial insights through charts and statistics

---

## 📸 Screenshots

> Add your app screenshots here for a better first impression.

| Home | Add Transaction | Statistics |
|------|------------------|------------|
| ![home](screenshots/home.png) | ![add](screenshots/add.png) | ![stats](screenshots/stats.png) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- A [Firebase project](https://console.firebase.google.com/) set up
- Android Studio / VS Code with Flutter & Dart plugins

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/expense-tracker-app.git

# Navigate to the project directory
cd expense-tracker-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup
1. Create a new project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** (Email/Password) and **Firestore Database**.
3. Download `google-services.json` (for Android) and/or `GoogleService-Info.plist` (for iOS).
4. Place them in:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
5. Run `flutterfire configure` if using FlutterFire CLI.

---

## 📂 Project Structure

```
lib/
├── models/          # Data models (Transaction, Wallet, Category, etc.)
├── providers/       # Riverpod state management
├── screens/         # App screens (Home, Add Transaction, Stats, Auth)
├── widgets/         # Reusable UI components
├── services/        # Firebase Auth & Firestore services
└── main.dart        # App entry point
```

---

## 🚀 Future Improvements

- 🤖 AI-based spending insights
- 📷 Receipt / bill scanner using camera
- 📑 Export financial reports (PDF / CSV)
- 🧠 Smart budgeting recommendations
- 📈 Advanced financial analytics
- 🎨 Improved data visualization

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check the [issues page](../../issues) or submit a pull request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Mohib Khorajiya**

- GitHub: [@your-username](https://github.com/MohibKhorajiya01)

---

⭐ If you found this project helpful, consider giving it a star on GitHub!
