import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_samples/rive_app/screens/sign_detection_screen.dart';

class SignItem {
  final String name;
  final String description;
  final String category;
  final bool favorite;
  final String difficulty;
  
  SignItem({
    required this.name,
    required this.description,
    required this.category,
    this.favorite = false,
    required this.difficulty,
  });
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";
  bool _showFavoritesOnly = false;
  
  // Mock data
  final List<SignItem> _allSigns = [
    SignItem(
      name: "Hello",
      description: "A common greeting",
      category: "Greetings",
      difficulty: "Easy",
    ),
    SignItem(
      name: "Thank You",
      description: "Express gratitude",
      category: "Phrases",
      difficulty: "Easy",
    ),
    SignItem(
      name: "Please",
      description: "Make a polite request",
      category: "Phrases",
      difficulty: "Easy",
      favorite: true,
    ),
    SignItem(
      name: "Family",
      description: "Referring to family members",
      category: "Relationships",
      difficulty: "Medium",
    ),
    SignItem(
      name: "Friend",
      description: "Referring to a friend",
      category: "Relationships",
      difficulty: "Easy",
      favorite: true,
    ),
    SignItem(
      name: "Help",
      description: "Request assistance",
      category: "Emergency",
      difficulty: "Medium",
    ),
    SignItem(
      name: "Water",
      description: "Indicating water or thirst",
      category: "Food & Drink",
      difficulty: "Easy",
    ),
    SignItem(
      name: "Understand",
      description: "Expressing comprehension",
      category: "Communication",
      difficulty: "Hard",
    ),
    SignItem(
      name: "Time",
      description: "Referring to time",
      category: "Concepts",
      difficulty: "Medium",
      favorite: true,
    ),
    SignItem(
      name: "Where",
      description: "Asking about location",
      category: "Questions",
      difficulty: "Medium",
    ),
  ];
  
  List<SignItem> _filteredSigns = [];
  final List<String> _categories = ["All", "Greetings", "Phrases", "Relationships", "Emergency", "Food & Drink", "Communication", "Concepts", "Questions"];
  
  @override
  void initState() {
    super.initState();
    _filteredSigns = _allSigns;
    _searchController.addListener(_filterSigns);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_filterSigns);
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterSigns() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      
      _filteredSigns = _allSigns.where((sign) {
        // Apply category filter
        final matchesCategory = _selectedCategory == "All" || sign.category == _selectedCategory;
        
        // Apply favorites filter
        final matchesFavorite = !_showFavoritesOnly || sign.favorite;
        
        // Apply search query
        final matchesQuery = query.isEmpty || 
                            sign.name.toLowerCase().contains(query) || 
                            sign.description.toLowerCase().contains(query);
        
        return matchesCategory && matchesFavorite && matchesQuery;
      }).toList();
    });
  }
  
  void _toggleFavorite(int index) {
    // In a real app, you would update a database
    // This is just for UI demonstration
    final sign = _filteredSigns[index];
    final allSignIndex = _allSigns.indexWhere((s) => s.name == sign.name);
    
    if (allSignIndex != -1) {
      setState(() {
        _allSigns[allSignIndex] = SignItem(
          name: sign.name,
          description: sign.description,
          category: sign.category,
          difficulty: sign.difficulty,
          favorite: !sign.favorite,
        );
        
        _filterSigns();
      });
    }
  }
  
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterSigns();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Get available safe area to avoid overlapping with system UI
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;
    
    // Get theme provider to access dark mode state
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: RiveAppTheme.getBackgroundColor(isDarkMode),
      body: Container(
        padding: EdgeInsets.only(
          top: safePadding.top + 16, // Extra padding to avoid top menu button
          bottom: safePadding.bottom,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(0,50,40,10),
                  child: Row(
                    children: [
                      const SizedBox(width: 40), // Space for the menu button
                      Expanded(
                        child: Center(
                          child: Text(
                            'Sign Dictionary',
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              color: RiveAppTheme.getTextColor(isDarkMode),
                            ),
                          ),
                        ),
                      ),
                      Switch(
                        value: _showFavoritesOnly,
                        onChanged: (value) {
                          setState(() {
                            _showFavoritesOnly = value;
                            _filterSigns();
                          });
                        },
                        activeColor: RiveAppTheme.accentColor,
                        activeTrackColor: RiveAppTheme.accentColor.withOpacity(0.3),
                      ),
                      Icon(
                        Icons.favorite,
                        color: _showFavoritesOnly ? RiveAppTheme.accentColor : RiveAppTheme.getTextSecondaryColor(isDarkMode),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                
                // Search bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: RiveAppTheme.getInputBackgroundColor(isDarkMode),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search signs...',
                      hintStyle: TextStyle(color: RiveAppTheme.getTextSecondaryColor(isDarkMode).withOpacity(0.6)),
                      prefixIcon: Icon(Icons.search, color: RiveAppTheme.getTextSecondaryColor(isDarkMode)),
                      suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: RiveAppTheme.getTextSecondaryColor(isDarkMode)),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: RiveAppTheme.getTextColor(isDarkMode)),
                  ),
                ),
                
                // Categories
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _selectCategory(category);
                            }
                          },
                          backgroundColor: RiveAppTheme.getCardColor(isDarkMode),
                          selectedColor: RiveAppTheme.accentColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? RiveAppTheme.accentColor : RiveAppTheme.getTextColor(isDarkMode),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? RiveAppTheme.accentColor : RiveAppTheme.getDividerColor(isDarkMode),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Results count
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '${_filteredSigns.length} ${_filteredSigns.length == 1 ? 'sign' : 'signs'} found',
                    style: TextStyle(
                      color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Search results
                Expanded(
                  child: _filteredSigns.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80), // Bottom padding for tab bar
                          itemCount: _filteredSigns.length,
                          itemBuilder: (context, index) {
                            final sign = _filteredSigns[index];
                            return _buildSignItem(sign, index, isDarkMode);
                          },
                        ),
                ),
              ],
            ),
            // Add floating action button for sign detection
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignDetectionScreen(),
                    ),
                  );
                },
                backgroundColor: RiveAppTheme.accentColor,
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: RiveAppTheme.getTextSecondaryColor(isDarkMode).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No signs found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RiveAppTheme.getTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Try selecting a different category'
                : 'Try a different search term',
            style: TextStyle(
              color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSignItem(SignItem sign, int index, bool isDarkMode) {
    Color difficultyColor;
    
    switch (sign.difficulty) {
      case 'Easy':
        difficultyColor = Colors.green;
        break;
      case 'Medium':
        difficultyColor = Colors.orange;
        break;
      default:
        difficultyColor = Colors.red;
    }
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: RiveAppTheme.getCardColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to sign detail
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sign preview placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: RiveAppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.sign_language,
                    color: RiveAppTheme.accentColor,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Sign info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          sign.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: RiveAppTheme.getTextColor(isDarkMode),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: difficultyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            sign.difficulty,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: difficultyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sign.description,
                      style: TextStyle(
                        color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sign.category,
                      style: TextStyle(
                        color: RiveAppTheme.getTextSecondaryColor(isDarkMode).withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Favorite button
              IconButton(
                icon: Icon(
                  sign.favorite ? Icons.favorite : Icons.favorite_border,
                  color: sign.favorite ? Colors.red : RiveAppTheme.getTextSecondaryColor(isDarkMode).withOpacity(0.5),
                ),
                onPressed: () => _toggleFavorite(index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}