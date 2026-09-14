# Recipe Finder — Flutter

Choose the ingredients you have, get the recipes you can make. Backed by
Firestore rather than a bundled JSON file.

## Features

- Ingredient selector driving a recipe query
- Recipes and ingredients stored in **Cloud Firestore**
- Recipe images in **Firebase Storage**, uploaded from camera or gallery
  (`image_picker`)

## Structure

```
lib/
├── models/  recipe_model.dart · ingredient_model.dart
└── views/
    ├── home_screen.dart
    ├── ingredient_selector_screen.dart
    └── receipe_screen.dart
```

## Setup

Needs your own Firebase project:

1. Create a project and enable **Firestore** and **Storage**
2. Run `flutterfire configure`
3. Add your `google-services.json` / `GoogleService-Info.plist`

```bash
flutter pub get
flutter run
```

## Stack

Flutter · Dart · cloud_firestore · firebase_storage · firebase_core · image_picker
