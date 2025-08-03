# Wellnex - Your Personal AI Health & Wellness Companion

**Wellnex is a modern Flutter application designed to empower you on your health journey. It moves beyond simple data entry, providing a seamless way to track your wellness metrics and gain personalized insights from a context-aware AI assistant.**

<!-- You can replace this link with a GIF or screenshot of your app! -->
<p align="center">
  <b>A showcase of the Wellnex app's core features.</b>
</p>

<table align="center">
  <tr>
    <td align="center"><b>Secure Sign In</b></td>
    <td align="center"><b>Easy Sign Up</b></td>
    <td align="center"><b>Home Dashboard</b></td>
  </tr>
  <tr>
    <td><img src="![Image](https://github.com/user-attachments/assets/fc30b61e-af99-42a5-b71c-50908e93937d)" alt="Sign In Screen" width="260"></td>
    <td><img src="![Image](https://github.com/user-attachments/assets/6a671e20-69b5-43bb-9ffe-8a7977eab49d)" alt="Sign Up Screen" width="260"></td>
    <td><img src="![Image](https://github.com/user-attachments/assets/ccdc6ade-ed52-4f45-b023-634dff36da21)" alt="Home Dashboard" width="260"></td>
  </tr>
  <tr>
    <td align="center"><b>Dynamic Log Form</b></td>
    <td align="center"><b>Daily AI Fitness Tip</b></td>
    <td align="center"><b>Contextual AI Chat</b></td>
  </tr>
  <tr>
    <td><img src="![Image](https://github.com/user-attachments/assets/80e65774-c157-41ab-96e4-d0dda6850b8c)" alt="Add Wellness Log Screen" width="260"></td>
    <td><img src="![Image](https://github.com/user-attachments/assets/a58cfbad-247d-461f-9455-ef41036945f0)" alt="AI Fitness Tip Popup" width="260"></td>
    <td><img src="![Image](https://github.com/user-attachments/assets/ca32aea5-500a-41f6-af04-aebe7e7e4261)" alt="AI Chat Screen" width="260"></td>
  </tr>
</table>

## ✨ Core Philosophy

In a world of data, context is everything. Wellnex was built on the principle that your health data should work *for* you. It's not just a digital diary; it's an intelligent partner that understands your recent state to provide more relevant, supportive, and actionable advice.

---

## 🚀 Key Features

*   🧠 **Context-Aware AI Assistant:** Our standout feature. Before you even ask a question, Wellnex fetches your latest sleep and mood data. This context is sent to the Groq API along with your query, allowing for a deeply personalized and empathetic conversation.

*   📊 **Dynamic Wellness Logging:** Log what matters to you with an intelligent, adaptive form. Whether you're tracking your **sleep quality**, **mood**, **water intake**, **exercise sessions**, or **blood pressure**, the interface provides exactly the fields you need.

*   🔐 **Secure & Versatile Authentication:** Your data is private and secure. Wellnex provides multiple ways to sign in, ensuring easy access for everyone:
    *   Email & Password
    *   Google Sign-In
    *   Phone Number (with OTP Verification)

*   📈 **Visual Health Dashboard:** Your home screen acts as a personal dashboard, providing an at-a-glance view of your most recent wellness logs in a clean, beautifully designed list.

---

## 🛠️ Tech Stack

This project was built using a modern and robust set of technologies:

| Category          | Technology / Service                                     |
| ----------------- | -------------------------------------------------------- |
| **Frontend**      | [Flutter](https://flutter.dev/)                          |
| **Backend**       | [Firebase](https://firebase.google.com/)                 |
| **Authentication**| Firebase Authentication                                  |
| **Database**      | Cloud Firestore                                          |
| **AI Service**    | [Groq API](https://groq.com/) (using the Llama3 model)   |
| **Other Tools**   | `http`, `flutter_dotenv`, `google_sign_in`, `intl`       |

---

## ⚙️ Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   You must have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed on your machine.
*   An IDE like VS Code or Android Studio.

### Installation & Setup

1.  **Clone the Repository**
    ```sh
    git clone https://github.com/your-username/your-repo-name.git
    cd your-repo-name
    ```

2.  **Set Up Your Own Firebase Project**
    *   Create a new project on the [Firebase Console](https://console.firebase.google.com/).
    *   Install the Firebase CLI on your machine if you haven't already.
    *   From your project's root directory, run the following command and follow the prompts to connect the app to your own Firebase project. This will generate a new `lib/firebase_options.dart` file.
      ```sh
      flutterfire configure
      ```

3.  **Create an Environment File for API Keys**
    This project uses the Groq API for its AI features. You must provide your own API key.
    *   Go to the [Groq Cloud Console](https://console.groq.com/keys) to get your free API key.
    *   In the root directory of this project, create a file named `.env`.
    *   Add your API key to this file like so:
      ```
      GROQ_API_KEY=your_actual_groq_api_key_here
      ```
      _Note: The `.gitignore` file is already configured to keep this file private._

4.  **Install Dependencies**
    Run the following command to get all the required packages:
    ```sh
    flutter pub get
    ```

5.  **Run the App**
    Now you're ready to launch the app on your emulator or physical device!
    ```sh
    flutter run
    ```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/your-username/your-repo-name/issues).

## 📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.
