import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'speech_service.dart';
import 'api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final JKUATAssistant _assistant = JKUATAssistant();
  final SpeechService _speechService = SpeechService();
  List<ChatMessage> _messages = []; // Removed final to allow reassignment
  bool _isLoading = false;
  bool _isDarkMode = false;
  bool _isFirstLoad = true;
  bool _isListening = false;
  bool _isMuted = false;
  String? _currentlySpeakingMessageId;
  int _typingDots = 0;
  String _lastWords = '';

  late AnimationController _listeningAnimationController;
  late Animation<double> _listeningFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _listeningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _listeningFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_listeningAnimationController);
  }

  Future<void> _initializeServices() async {
    await _speechService.init();
    _showWelcomeMessage();
    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isLoading) {
        setState(() => _typingDots = (_typingDots + 1) % 4);
        _startTypingAnimation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _listeningAnimationController.dispose();
    _speechService.stopSpeaking();
    _speechService.stopListening();
    super.dispose();
  }

  void _showWelcomeMessage() {
    if (_isFirstLoad) {
      final welcomeMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Hello! I'm the Information Assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
        isSpeaking: false,
        onToggleSpeech: () => _toggleSpeech(DateTime.now().millisecondsSinceEpoch.toString()),
        isMuted: _isMuted,
      );

      setState(() {
        _messages.add(welcomeMessage);
        _isFirstLoad = false;
      });

      if (!_isMuted) {
        _speak(welcomeMessage.text, welcomeMessage.id);
      }
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      print('Stopping listening...');
      await _speechService.stopListening();
      _listeningAnimationController.reverse();
    } else {
      print('Starting listening...');
      final available = await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _lastWords = text;
            _controller.text = text;
            print('Recognized words: $_lastWords');
          });
        },
        onError: (error) {
          setState(() {
            _lastWords = 'Error: $error';
            print('Speech recognition error: $error');
          });
        },
      );
      if (available) {
        print('Speech recognition available and started.');
        _listeningAnimationController.forward();
      } else {
        print('Speech recognition NOT available or failed to start.');
      }
    }
    setState(() {
      _isListening = !_isListening;
      print('isListening: $_isListening');
      if (!_isListening) {
        _lastWords = '';
      }
    });
  }

  Future<void> _speak(String text, String messageId) async {
    if (text.isEmpty || _isMuted) return;

    if (_currentlySpeakingMessageId != null) {
      await _speechService.stopSpeaking();
    }

    setState(() {
      _currentlySpeakingMessageId = messageId;
      for (int i = 0; i < _messages.length; i++) {
        _messages[i] = _messages[i].copyWith(
          isSpeaking: _messages[i].id == messageId,
        );
      }
    });

    await _speechService.speak(text);

    setState(() {
      if (_currentlySpeakingMessageId == messageId) {
        _currentlySpeakingMessageId = null;
        for (int i = 0; i < _messages.length; i++) {
          _messages[i] = _messages[i].copyWith(isSpeaking: false);
        }
      }
    });
  }

  Future<void> _stopSpeaking() async {
    await _speechService.stopSpeaking();
    setState(() {
      _currentlySpeakingMessageId = null;
      for (int i = 0; i < _messages.length; i++) {
        _messages[i] = _messages[i].copyWith(isSpeaking: false);
      }
    });
  }

  Future<void> _toggleSpeech(String messageId) async {
    if (_currentlySpeakingMessageId == messageId) {
      await _stopSpeaking();
    } else {
      final message = _messages.firstWhere((m) => m.id == messageId);
      await _speak(message.text, messageId);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _stopSpeaking();
      }
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _typingDots = 0;
      _controller.clear();
    });

    _startTypingAnimation();

    try {
      final response = await _assistant.askQuestion(text);
      final responseId = DateTime.now().millisecondsSinceEpoch.toString();
      final assistantMessage = ChatMessage(
        id: responseId,
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        isSpeaking: false,
        onToggleSpeech: () => _toggleSpeech(responseId),
        canSpeak: _speechService.isAvailable,
        isMuted: _isMuted,
      );

      _addAssistantMessage(assistantMessage);
      if (!_isMuted) {
        await _speak(response, responseId);
      }
    } catch (e) {
      final errorMsg = "Sorry, I couldn't process your request. Please try again.";
      final errorId = DateTime.now().millisecondsSinceEpoch.toString();
      final errorMessage = ChatMessage(
        id: errorId,
        text: errorMsg,
        isUser: false,
        timestamp: DateTime.now(),
        isSpeaking: false,
        onToggleSpeech: () => _toggleSpeech(errorId),
        canSpeak: _speechService.isAvailable,
        isMuted: _isMuted,
      );

      _addAssistantMessage(errorMessage);
      if (!_isMuted) {
        await _speak(errorMsg, errorId);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addAssistantMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
  }

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final typingText = 'Typing${'.' * _typingDots}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(Icons.support_agent, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    typingText,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Information Assistant'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: _toggleMute,
              tooltip: _isMuted ? 'Unmute assistant' : 'Mute assistant',
            ),
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
              tooltip: _isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isListening)
              FadeTransition(
                opacity: _listeningFadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  child: Text(
                    _lastWords.isEmpty ? 'Listening...' : _lastWords,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                reverse: true,
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == 0) {
                    return _buildTypingIndicator();
                  }
                  return _messages.reversed.toList()[index - (_isLoading ? 1 : 0)];
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (_speechService.isAvailable)
                    GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isListening
                            ? const AnimatedMicIcon(key: ValueKey('mic_active'))
                            : Icon(
                          Icons.mic,
                          key: const ValueKey('mic_inactive'),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  if (_speechService.isAvailable) const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedMicIcon extends StatefulWidget {
  const AnimatedMicIcon({super.key});

  @override
  _AnimatedMicIconState createState() => _AnimatedMicIconState();
}

class _AnimatedMicIconState extends State<AnimatedMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(
        Icons.mic,
        color: Colors.green,
        size: 24,
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isSpeaking;
  final bool canSpeak;
  final VoidCallback? onToggleSpeech;
  final bool isMuted;

  const ChatMessage({
    super.key,
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isSpeaking = false,
    this.canSpeak = false,
    this.onToggleSpeech,
    this.isMuted = false,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isSpeaking,
    bool? canSpeak,
    VoidCallback? onToggleSpeech,
    bool? isMuted,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      canSpeak: canSpeak ?? this.canSpeak,
      onToggleSpeech: onToggleSpeech ?? this.onToggleSpeech,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context, String text) {
    final theme = Theme.of(context);
    final urlRegExp = RegExp(
      r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
      caseSensitive: false,
    );

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final match in urlRegExp.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: TextStyle(
            color: isUser
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ));
      }

      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: isUser
              ? Colors.blueAccent
              : Colors.lightBlue,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w500,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchUrl(url.startsWith('http') ? url : 'https://$url'),
      ));

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: TextStyle(
          color: isUser
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ));
    }

    return spans;
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(Icons.support_agent, color: theme.colorScheme.secondary),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isUser ? 12 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 12),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: _buildTextSpans(context, text),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (!isUser && canSpeak && onToggleSpeech != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: onToggleSpeech,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isSpeaking ? Icons.volume_off : Icons.volume_up,
                                    key: ValueKey('$id-${isSpeaking ? 'speaking' : 'not_speaking'}'),
                                    size: 16,
                                    color: isMuted ? Colors.grey : theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.block,
                                size: 12,
                                color: isMuted ? Colors.red : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.person, color: theme.colorScheme.onPrimary),
            ),
        ],
      ),
    );
  }
}