# Speak Up - UML Class Diagram

## Core Models

### UserModel
- **Attributes**
  - id: String
  - name: String
  - email: String
  - level: int
  - xpPoints: int
  - streak: int
  - isAuthenticated: bool
- **Relationships**
  - Used by UserProvider

### CourseModel
- **Attributes**
  - id: UniqueKey
  - title: String
  - subtitle: String
  - caption: String
  - color: Color
  - image: String
  - icon: IconData
  - progress: double
  - xpReward: int
  - lessons: List<LessonModel>
- **Methods**
  - getIcon(): IconData
- **Relationships**
  - Contains LessonModel

### LessonModel
- **Attributes**
  - title: String
  - description: String
  - duration: String
  - difficulty: String
  - isCompleted: bool

## ML Model Integration

### ModelHelper
- **Attributes**
  - _labelToIndexMap: Map<String, int>
  - _indexToLabelMap: Map<int, String>
  - _cachedLabels: List<String>
  - _characterSetRanges: Map<String, Map<String, int>>
- **Methods**
  - loadLabels(path: String): Future<List<String>>
  - copyModelToDocuments(assetPath: String, filename: String): Future<String?>
  - processCameraImage(cameraImage: CameraImage): Future<Image?>
  - simulatePrediction(image: Image?, characterSet: String): String
  - generateWordSuggestions(character: String, characterSet: String): List<String>
  - _generateTamilSuggestions(baseChar: String, transliteration: String): Set<String>
  - _generateArabicSuggestions(baseChar: String, transliteration: String): Set<String>
  - _generateEnglishSuggestions(character: String): Set<String>

### HandSignDetector
- **Methods**
  - initialize(): Future<void>
  - detectHand(image: CameraImage, rotation: InputImageRotation): Future<List<PoseLandmark>>
  - classifySign(landmarks: List<PoseLandmark>): String?

## Screens

### CharacterPlaygroundScreen
- **Attributes**
  - _controller: CameraController
  - _isCameraInitialized: bool
  - _currentPrediction: String?
  - _currentConfidence: double?
  - _currentSentence: String
  - _wordSuggestions: List<String>
  - _isProcessing: bool
  - _detectedCharacters: List<String>
  - _processingDelay: Duration
  - _processingTimer: Timer?
  - _labels: List<String>?
  - _modelInitialized: bool
  - _characterType: String
  - _characterSets: List<String>
- **Methods**
  - _initializeModel(): Future<void>
  - _initializeCamera(): Future<void>
  - _stopCamera(): void
  - _startProcessing(): void
  - _processFrame(): Future<void>
  - _addCharacterToSentence(): void
  - _addWordToSentence(word: String): void
  - _clearSentence(): void
  - _changeCharacterSet(newSet: String): void

### ChatScreen
- **Attributes**
  - _textController: TextEditingController
  - _scrollController: ScrollController
  - _animationController: AnimationController
  - _showSignLanguageOption: bool
  - _isSignDetectionActive: bool
  - _riveController: StateMachineController?
  - _triggerSuccess: SMITrigger?
  - _messages: List<ChatMessage>
  - _geminiService: GeminiService
  - _isLoading: bool
  - _showOptions: bool
- **Methods**
  - _onRiveInit(artboard: Artboard): void
  - _navigateWithAnimation(screen: Widget): void
  - _handleSubmitted(text: String): void
  - _respondToMessage(message: String): void
  - _handleSignDetected(sign: String): void
  - _sendMessage(): Future<void>

### LearningPathScreen
- **Attributes**
  - _progressController: AnimationController
  - _headerController: AnimationController
  - _contentController: AnimationController
  - _progressAnimation: Animation<double>
  - _headerScaleAnimation: Animation<double>
  - _headerSlideAnimation: Animation<double>
  - _selectedNodeIndex: int
  - _isPathLoaded: bool
  - _pathNodes: List<Map<String, dynamic>>
- **Methods**
  - _buildProgressHeader(): Widget
  - _buildPathNode(...): Widget
  - _showLessonDetails(node: Map<String, dynamic>): void

## Services

### UserProvider
- **Attributes**
  - currentUser: UserModel?
  - isAuthenticated: bool
- **Methods**
  - login(email: String, password: String): Future<bool>
  - logout(): void
  - updateUserProfile(UserModel): Future<void>

### GeminiService
- **Attributes**
  - _apiKey: String
- **Methods**
  - generateResponse(prompt: String): Future<String>

## Theme & UI

### ThemeProvider
- **Attributes**
  - isDarkMode: bool
- **Methods**
  - toggleTheme(): void

### RiveAppTheme
- **Static Methods**
  - getTextColor(isDarkMode: bool): Color
  - getBackgroundColor(isDarkMode: bool): Color
  - getCardColor(isDarkMode: bool): Color
  - getInputBackgroundColor(isDarkMode: bool): Color
  - getTextSecondaryColor(isDarkMode: bool): Color

## Relationships

1. **HomeTabView** navigates to **CharacterPlaygroundScreen**, **ChatScreen**, and **LearningPathScreen**
2. **CharacterPlaygroundScreen** uses **ModelHelper** for character recognition
3. **ChatScreen** uses **GeminiService** for AI responses and **SignCamera** for sign detection
4. **LearningPathScreen** navigates to **LessonDetailScreen**
5. **UserProvider** manages **UserModel** data
6. All screens consume **ThemeProvider** for theme management
7. **HandSignDetector** is used by **SignCamera** component 
8. **ModelHelper** processes labels from `labels.txt` for multi-language recognition

## Notes

This UML focuses on the key classes involved in the multi-language sign recognition feature. The application supports:
- Tamil character recognition (248 characters)
- Arabic character recognition (31 characters)
- English character recognition (68 characters)
- Word suggestions based on detected characters
- Language switching in the Character Playground 