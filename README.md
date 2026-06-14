# easy_diet

`easy_diet` is a simple Flutter app that generates a daily diet schedule with meal suggestions. It helps users quickly view a randomized breakfast, snacks, lunch, and dinner plan, with a clean interface and image-backed meal cards.

## What it does

- Loads diet options from a local JSON asset (`assets/diet.json`).
- Shows the current meal recommendation for the current time of day.
- Displays a full daily menu with entries for:
  - Colazione
  - Spuntino 11
  - Pranzo
  - Spuntino 17
  - Cena
- Lets the user refresh the current meal or regenerate the full daily menu.
- Uses unsplash-style image URLs for a more attractive UI.

## Main files

- `lib/main.dart` — app entry point.
- `lib/screens/meal_screen.dart` — main UI screen for displaying the current meal and daily menu.
- `lib/services/diet_service.dart` — loads diet data, returns random meals, and selects meal type based on time.
- `assets/diet.json` — diet item data source.

## How to run

1. Make sure you have Flutter installed.
2. Open the project folder in your editor.
3. Run:

```bash
flutter pub get
flutter run
```

## Notes

- The app currently uses remote image URLs for meal images.
- If no meal items are available, it shows a fallback message in Italian: `Nessun elemento disponibile`.
- The app is designed as a small demo for a diet schedule generator.
