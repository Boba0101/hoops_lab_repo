# HoopsLab - AI-Powered Basketball Performance Tracker

HoopsLab is a comprehensive, cross-platform mobile application built with Flutter and Firebase, designed to be the ultimate analytical tool for basketball coaches and players. It moves beyond simple stat-keeping by integrating a contextual AI assistant to transform raw game data into actionable performance insights.

## Project Overview

The application provides a complete ecosystem for team management, featuring role-specific user experiences, a flexible dual-mode stat tracking system, and powerful, data-driven dashboards. The core innovation is an integrated AI Performance Assistant (powered by Google's Gemini API) that provides conversational analysis of player and team performance.

https://github.com/user-attachments/assets/5186b511-7360-44be-ac5f-3686851f5056

## Key Features

### 1. Role-Specific Dashboards
The app provides a unique, tailored experience for each user role.

-   **Coach's "Command Center":** A high-level dashboard focused on team-wide analytics, including win-loss records, performance trends, and player leaderboards with a seamless drill-down to detailed player analytics.
-   **Player's "Performance Hub":** A personalized dashboard focused on individual progress, showcasing personal season averages, a game-by-game performance trend chart, and an extensive personal game log.

| Coach Dashboard | Player Dashboard |
| :---:           | :---:            |
| ![Coach Dashboard Demo] ![Animation](https://github.com/user-attachments/assets/45129141-7d77-420c-8934-e3a4b51d03ff) |![Player Dashboard Demo] ![playerdash](https://github.com/user-attachments/assets/9e5f3123-8be4-4d88-8523-0d3b09bf3280)|

### 2. Dual-Mode Stat Tracking
HoopsLab offers maximum flexibility for data entry to suit any coaching scenario.

-   **Live Tally Mode:** An intuitive, real-time interface for game days, featuring a game clock, quarter management, quick-tally buttons, automated "Minutes Played" tracking, and an "Undo" function.
-   **Manual Entry Mode:** A comprehensive post-game system that allows a coach to add or edit a full, detailed box score for any past event from the match history.
<img alt="Screenshot_20250920-151911" src="https://github.com/user-attachments/assets/59f9e757-c84c-4461-8ae0-164a76415b53" />

<img alt="Screenshot_20250920-151923" src="https://github.com/user-attachments/assets/d2a93d88-16f5-4ac3-8f9a-0642f6f7b958" />


### 3. AI Performance Assistant
The integrated chatbot transforms raw data into knowledge.

-   **Contextual Analysis:** The AI compares a player's performance in their last game against their historical season averages.
-   **Multi-Intent Understanding:** The chatbot can understand and answer a variety of questions, including single-player performance, team summaries, stat leaders, and head-to-head player comparisons.
-   **Dynamic Suggestions:** After each response, the AI provides tappable, context-aware follow-up questions to guide the analytical conversation.

<img width="1080" height="2400" alt="Screenshot_20250920-160204" src="https://github.com/user-attachments/assets/b28730cc-c330-405a-a2e8-1f4efb8e31d4" />


### 4. Comprehensive Schedule & History
-   **Event Management:** Coaches can create, edit, and delete team events (Matches or Trainings), selecting participants and locations with an interactive map.
-   **Game Summaries:** All users can view the match history, which includes color-coded win/loss indicators and detailed box scores for completed games.

---

## Technical Architecture & Stack

This project was built with a clean, service-oriented architecture to ensure maintainability and scalability.

-   **Frontend:** [Flutter](https://flutter.dev/) (Cross-Platform Framework)
-   **Backend & Database:** [Firebase](https://firebase.google.com/)
    -   **Authentication:** Firebase Authentication for secure user management.
    -   **Database:** Cloud Firestore for storing all user, schedule, and statistical data.
    -   **Security:** Firestore Security Rules to enforce role-based data access.
-   **APIs:**
    -   **Generative AI:** [Google Gemini API (1.5 Flash)](https://ai.google.dev/) for the chatbot.
    -   **Location Services:** [Google Maps Platform](https://developers.google.com/maps) (Maps SDK & Places SDK) for event location management.
-   **State Management:** [Provider](https://pub.dev/packages/provider) for dependency injection and managing shared UI state.
-   **Architecture:** The project follows clean programming principles, with a clear separation of concerns between the UI (screens), business logic (services), and data models.

---

## Setup & Installation

To run this project locally, please follow these steps:

1.  **Prerequisites:**
    *   Flutter SDK installed.
    *   A configured Firebase project.
    *   A Google Cloud project with billing enabled and the **Maps SDK for Android**, **Places API**, and **Generative Language API** enabled.

2.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-username/hoopslab.git
    cd hoopslab
    ```

3.  **Configure Firebase:**
    *   Follow the `flutterfire configure` steps to link the app to your own Firebase project. This will generate a `firebase_options.dart` file and download your project's `google-services.json` file.

4.  **Add Secure API Keys:**
    *   Navigate to the `android/` directory and create a file named `local.properties`.
    *   Add your secret API keys to this file. This file is included in `.gitignore` and will not be committed to version control.
        ```properties
        # In android/local.properties
        MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE
        GEMINI_API_KEY=YOUR_GOOGLE_GEMINI_API_KEY_HERE
        ```

5.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

6.  **Run the App:**
    ```bash
    flutter run
    ```
    *(Note: The Gemini API key is provided as a build config field, so no `--dart-define` flag is needed for the run command.)*

---

## Acknowledgements

This project was developed as part of the Bachelor of Information Technology (Honours) Communication and Networking program. I would like to express my sincere thanks to my project supervisor for their invaluable guidance and support throughout this process.
