# CekLabel - Technical Architecture Document

## 1. Overview
CekLabel is a Flutter-based mobile application designed to scan food ingredient labels, extract text using OCR, and analyze the ingredients to alert users of potential allergens, hidden sugars, and complex chemical additives. This document outlines the technical architecture for the application based on its primary goals.

## 2. High-Level System Architecture
The application is designed primarily as an offline-first mobile client to ensure fast and reliable scanning without needing a constant internet connection. 

### System Components:
1.  **Mobile Client (Flutter):** The core application running on iOS and Android. Handles the UI, camera interactions, OCR processing, and ingredient analysis logic.
2.  **Local Database:** Stores the ingredient dictionary, allergen profiles, and user scan history locally on the device for instantaneous matching and offline access.
3.  **Remote Backend (Optional/Future):** A cloud service (e.g., Firebase, Supabase, or a custom REST API) to push periodic updates to the local ingredient dictionary and sync user profiles across multiple devices.

## 3. Mobile Client Architecture
The Flutter app will follow a **Clean Architecture** approach combined with **Riverpod** for state management and dependency injection. This ensures a clear separation of concerns, making the app testable and scalable.

The client is divided into three primary layers:

### 3.1. Presentation Layer
Responsible for the user interface and handling user interactions.
*   **Widgets/Pages:** Flutter UI components (e.g., `CameraScannerPage`, `ResultPage`, `SettingsPage`, `DictionaryPage`).
*   **State Providers (Riverpod):** Manages the UI state and communicates with the domain layer. For example, a `ScanResultProvider` holds the current scanned text and the analyzed results.

### 3.2. Domain Layer
Contains the core business logic, decoupled from Flutter-specific libraries.
*   **Models:** Data classes representing `Ingredient`, `Allergen`, `AnalysisResult`, and `UserProfile`.
*   **Use Cases (Interactors):** Encapsulate specific business rules.
    *   `AnalyzeIngredientsUseCase`: Takes raw OCR text, parses it into an ingredient list, and checks against the database for allergens and hidden sugars.
    *   `ExtractTextFromImageUseCase`: Wraps the OCR invocation logic.

### 3.3. Data Layer
Handles data retrieval and persistence from various internal and external sources.
*   **Repositories:** Abstracts the data sources from the domain layer (e.g., `IngredientRepository`, `HistoryRepository`).
*   **Data Sources:**
    *   **Local DB Data Source:** Interfaces with the local database (e.g., SQLite or Isar) to query ingredient definitions.
    *   **OCR Service:** Interfaces with **Google ML Kit** to process image frames and return recognized text blocks.

## 4. Key Modules and Workflows

### 4.1. OCR & Scanning Module
*   Utilizes the device camera to capture images or live frames.
*   Passes the image data to the Google ML Kit Text Recognition API.
*   Outputs a raw string of text detected on the package, specifically targeting the ingredients block.

### 4.2. Ingredient Parsing & Analysis Engine
*   **Sanitization:** Cleans up the raw OCR text (handling common typos, removing irrelevant promotional text).
*   **Tokenization:** Splits the text block into a list of individual ingredients (typically comma-separated).
*   **Matching:** Compares each token against the local database of allergens, hidden sugars, and chemical codes (e.g., E621).
*   **Categorization:** Tags each ingredient with a status, such as "Safe", "Warning (Allergen)", or "Caution (Sugar/Additive)".

## 5. Technology Stack Recommendations
Based on the project requirements and current Flutter best practices:
*   **Framework:** Flutter (Dart)
*   **State Management & DI:** Riverpod (`flutter_riverpod`)
*   **Text Recognition / OCR:** Google ML Kit (`google_mlkit_text_recognition`)
*   **Local Storage:** Isar Database (`isar`) or SQLite (`sqflite`). Isar is highly recommended for Flutter as it provides fast full-text search capabilities which will be crucial for matching ingredient names.
*   **Routing:** `go_router` for structured, declarative navigation.
*   **Camera:** `camera` plugin for custom scanning UI, or `image_picker` for simpler gallery/camera selection.

## 6. Core Data Flow (Scan Process)
1.  **User** captures an image of the label via the UI.
2.  **UI** calls the `ExtractTextFromImageUseCase`.
3.  **OCR Service** (Data Layer) processes the image and returns raw text.
4.  **UI** triggers the `AnalyzeIngredientsUseCase` with the raw text.
5.  **Use Case** requests ingredient data matching the text from the `IngredientRepository`.
6.  **Repository** queries the **Local Database**.
7.  **Use Case** constructs an `AnalysisResult` containing warnings and translations.
8.  **Riverpod Provider** updates its state with the `AnalysisResult`.
9.  **UI** rebuilds to show the user the translated ingredients, alerting them of any allergens or hidden sugars.

