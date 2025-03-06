import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool containsSignLanguage;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.containsSignLanguage = false,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  bool _showSignLanguageOption = false;
  
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Add initial messages
    _messages = [
      ChatMessage(
        text: "Hello! I'm your Sign Language Assistant. How can I help you today?",
        isUser: false,
        time: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleSubmitted(String text) {
    _textController.clear();
    
    if (text.trim().isEmpty) return;
    
    final userMessage = ChatMessage(
      text: text,
      isUser: true, 
      time: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _showSignLanguageOption = false;
    });
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // Add bot response after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      _respondToMessage(text);
    });
  }
  
  void _respondToMessage(String message) {
    String response;
    bool containsSignLanguage = false;
    
    message = message.toLowerCase();
    
    if (message.contains("hello") || message.contains("hi")) {
      response = "👋 Hello! That's a great start. Would you like to learn how to sign 'hello' in sign language?";
      containsSignLanguage = true;
    } else if (message.contains("thank") || message.contains("thanks")) {
      response = "You're welcome! The sign for 'thank you' is performed by touching your lips with your fingertips and moving your hand forward.";
      containsSignLanguage = true;
    } else if (message.contains("learn") || message.contains("teach") || message.contains("how to")) {
      response = "I can help you learn sign language! What specific signs or phrases are you interested in practicing?";
    } else if (message.contains("practice")) {
      response = "Great! You can use our practice feature to work on specific signs with feedback. Would you like to try that now?";
    } else if (message.contains("sign for")) {
      response = "To learn that specific sign, I recommend checking our dictionary or starting a practice session focusing on that category.";
    } else {
      response = "I'm here to help you with sign language! You can ask me about specific signs, how to practice, or general questions about sign language.";
    }
    
    final botMessage = ChatMessage(
      text: response,
      isUser: false, 
      time: DateTime.now(),
      containsSignLanguage: containsSignLanguage,
    );
    
    setState(() {
      _messages.add(botMessage);
      if (containsSignLanguage) {
        _showSignLanguageOption = true;
      }
    });
    
    // Scroll to bottom again after adding the response
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get available safe area to avoid overlapping with system UI
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    
    return Container(
      color: RiveAppTheme.background,
      child: Column(
        children: [
          // Extra spacing at the top to avoid menu button from home.dart
          SizedBox(height: topPadding + 60),
          
          // Custom title - centered with no conflicting buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Sign Language Assistant',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          
          // Chat assistant status indicator - more subtle
          Container(
            margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Date indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Today',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(message, index);
              },
            ),
          ),
          
          // Sign language visualization card
          if (_showSignLanguageOption)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RiveAppTheme.accentColor.withOpacity(0.05),
                    Colors.blue.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: RiveAppTheme.accentColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: RiveAppTheme.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sign_language,
                      color: RiveAppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Watch Sign Demonstration',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'See how this sign is performed',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Watch'),
                    onPressed: () {
                      // Would open sign language video
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RiveAppTheme.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Bottom margin for tab bar
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Voice input button
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(Icons.mic, color: Colors.grey[500], size: 22),
                    onPressed: () {
                      // Voice input functionality would go here
                    },
                  ),
                ),
                
                // Text input field
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                ),
                
                // Attachment button
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(Icons.image_outlined, color: Colors.grey[500], size: 22),
                    onPressed: () {
                      // Image attachment functionality
                    },
                  ),
                ),
                
                // Camera button
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(Icons.camera_alt_outlined, color: Colors.grey[500], size: 22),
                    onPressed: () {
                      // Camera functionality
                    },
                  ),
                ),
                
                // Send button with container for better touch target and visual
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: Material(
                    color: RiveAppTheme.accentColor,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _handleSubmitted(_textController.text),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message, int index) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: message.isUser ? 50 : 0,
        right: message.isUser ? 0 : 50,
      ),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RiveAppTheme.accentColor.withOpacity(0.7),
                    RiveAppTheme.accentColor.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: RiveAppTheme.accentColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
              ),
            ),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? RiveAppTheme.accentColor
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 0),
                      bottomRight: Radius.circular(message.isUser ? 0 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser
                            ? RiveAppTheme.accentColor.withOpacity(0.25)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.only(
                    top: 6,
                    left: message.isUser ? 0 : 8,
                    right: message.isUser ? 8 : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.time),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (message.isUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Colors.blue[400],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    // Using 24-hour format for cleaner appearance
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}