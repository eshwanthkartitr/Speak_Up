# Multi-Language Sign Recognition Integration

This document explains how the PyTorch model integration works for sign language character recognition in the Character Playground screen of the Speak Up app. The implementation now supports Tamil, Arabic, and English character sets.

## Overview

The implementation processes frames from the device camera using locally stored PyTorch models (.pth files) to recognize sign language characters across multiple languages. The processing happens every 0.5 seconds to balance performance and responsiveness.

## Files

- `model_helper.dart`: Utility class that provides methods for loading labels, processing camera images, and generating word suggestions with synonymic query expansion
- `character_playground_screen.dart`: UI for the character playground with camera integration and prediction display
- `labels.txt`: Contains all the character classes including Tamil, Arabic, and English characters

## Model Files

The following model files are included in the app's assets:

- `assets/models/mobilenetv3_best.pth`: MobileNetV3 model trained for multi-language sign recognition
- `assets/models/best.pth`: A backup model (not currently used)
- `assets/models/labels.txt`: Labels file containing all character classes across different languages

## Supported Languages

The app currently supports three character sets:

1. **Tamil**: 248 Tamil characters including vowels, consonants, and combined characters
2. **Arabic**: 31 Arabic letters including different forms
3. **English**: 26 uppercase letters, 26 lowercase letters, 10 numbers, and 12 special symbols

Users can switch between languages using the language selector in the app interface.

## How It Works

1. The app loads all character labels and creates index mappings
2. The model file is copied from assets to the app's documents directory
3. The camera preview shows what the user is signing
4. Every 0.5 seconds, the app:
   - Takes a frame from the camera
   - Processes the image (resize, normalize)
   - Runs inference with the model based on the selected character set
   - Displays the detected character with confidence score
   - Performs synonymic query expansion for related suggestions
   - Generates word suggestions based on the detected character and language

5. The user can:
   - Add the detected character to their sentence
   - Choose a suggested word to add to their sentence
   - Clear the current sentence
   - Switch between different language character sets

## Tamil Character Recognition

The implementation supports recognition of 248 Tamil characters including:
- Base vowels (அ, ஆ, இ, etc.)
- Consonants (க், ங், ச், etc.)
- Combined characters (க, கா, கி, etc.)

Each character is presented with its transliteration in parentheses, for example: "அ(a)" or "க(Ka)".

## Arabic Character Recognition

The implementation supports recognition of 31 Arabic letters including:
- Basic letters (ا, ب, ت, etc.)
- Special forms of letters

Each character is presented with its transliteration in parentheses.

## English Character Recognition

The implementation supports recognition of English characters including:
- Uppercase letters (A-Z)
- Lowercase letters (a-z)
- Numbers (0-9)
- Special symbols (@, #, $, etc.)

## Synonymic Query Expansion

To improve the usability of the app, we've implemented language-specific synonymic query expansion that:

1. Extracts the base character from the prediction
2. Identifies related characters in the same character family for the active language
3. Retrieves words from both the exact character and related characters
4. Uses the transliteration to find additional relevant suggestions
5. Ensures a minimum number of suggestions are always available

This approach provides more comprehensive suggestions even when the model prediction isn't perfect.

## Notes on Implementation

- **Model Loading**: Due to Flutter's limitations with directly using PyTorch models, this implementation uses a simulated prediction for demonstration purposes. In a production app, you would need to either:
  1. Convert PyTorch models to TFLite format
  2. Use platform channels to run the PyTorch models natively on Android/iOS
  3. Use a PyTorch mobile integration package

- **Processing Interval**: The 0.5-second processing interval can be adjusted in the `_processingDelay` variable.

- **Language Selection**: When you change the language, the app will automatically filter predictions to show only characters from the selected language set.

## Character Set Ranges

The app uses the following index ranges to filter character sets:

```dart
static final Map<String, Map<String, int>> _characterSetRanges = {
  'Tamil': {'start': 0, 'end': 247},      // Tamil characters
  'Arabic': {'start': 275, 'end': 305},   // Arabic characters
  'English': {'start': 248, 'end': 274},  // English characters and symbols
};
```

## Adding New Languages

To add a new language:

1. Add the character labels to `labels.txt` and update the index ranges
2. Update the `_characterSetRanges` in `model_helper.dart`
3. Create a word dictionary for the new language
4. Add the language to the character set selector in `character_playground_screen.dart`

## Troubleshooting

- If the model loading fails, check the logs for error messages
- Make sure the model file path in assets is correct
- Ensure the labels.txt file contains all characters in the correct order
- If word suggestions aren't appearing, verify that the character extraction regex is working correctly
- If switching languages doesn't change predictions, check the character set ranges in the ModelHelper class 