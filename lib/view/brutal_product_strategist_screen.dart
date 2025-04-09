import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../model/product_idea_model.dart';
import '../service/brutal_product_strategist_service.dart';

class BrutalProductStrategistScreen extends StatefulWidget {
  const BrutalProductStrategistScreen({super.key});

  @override
  _BrutalProductStrategistScreenState createState() => _BrutalProductStrategistScreenState();
}

class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ProductIdea? evaluation;
  final bool isForm;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.evaluation,
    this.isForm = false,
  });
}

class _BrutalProductStrategistScreenState extends State<BrutalProductStrategistScreen> {
  final BrutalProductStrategistService _strategistService = BrutalProductStrategistService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  String _initialPrompt = "Ürünün ne? Bana tek satırlık tanıtımı, kullanıcıyı ve nasıl para kazandığını ver. Romantikleştirme.";
  final Uuid _uuid = Uuid();
  List<Message> _messages = [];
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPrompt();
  }

  Future<void> _loadInitialPrompt() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final prompt = await _strategistService.getInitialPrompt();
      setState(() {
        _initialPrompt = prompt;
        _isLoading = false;
        _addSystemMessage(prompt);
        _addFormExample();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _addFormExample() {
    setState(() {
      _messages.add(
        Message(
          id: _uuid.v4(),
          content: "Örnek Form",
          isUser: false,
          timestamp: DateTime.now(),
          isForm: true,
        ),
      );
    });
  }

  void _addSystemMessage(String message, {ProductIdea? evaluation}) {
    setState(() {
      _messages.add(
        Message(
          id: _uuid.v4(),
          content: message,
          isUser: false,
          timestamp: DateTime.now(),
          evaluation: evaluation,
        ),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(
        Message(
          id: _uuid.v4(),
          content: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addUserMessage(message);
    _messageController.clear();

    setState(() {
      _isSendingMessage = true;
    });

    try {
      // Parse the user input and determine what to do
      if (_messages.length == 3) { // After initial system message, form example, and first user response
        _addSystemMessage("Ürün fikriniz hakkında biraz daha detay verebilir misiniz? Çözdüğü problem nedir?");
      } else if (_messages.length == 5) {
        _addSystemMessage("Hedef kullanıcılarınız kimler?");
      } else if (_messages.length == 7) {
        _addSystemMessage("Gelir modeliniz nasıl olacak?");
      } else if (_messages.length == 9) {
        // Extract product details from conversation
        final userMessages = _messages.where((m) => m.isUser).toList();
        
        final description = userMessages[0].content;
        final problem = userMessages[1].content;
        final users = userMessages[2].content;
        final monetization = userMessages[3].content;
        
        // Evaluate the product idea
        final result = await _strategistService.evaluateProductIdea(
          description,
          problem,
          users,
          monetization,
        );
        
        String evaluationMessage = "Değerlendirmem: ${result.judgment}\n\nNEDEN: ${result.reason}\n\nSONRAKİ ADIM: ${result.nextStep}";
        _addSystemMessage(evaluationMessage, evaluation: result);
        
        _addSystemMessage("Başka bir ürün fikrinizi değerlendirmemi ister misiniz?");
      } else {
        // For any other message, give a generic response
        _addSystemMessage("Yeni bir ürün fikrini değerlendirmek için bana fikrini anlatabilirsin. Tek cümlede ürününü tanıt.");
      }
    } catch (e) {
      _addSystemMessage("Üzgünüm, bir hata oluştu: $e");
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fikir AI'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 1,
        titleSpacing: 8.0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            )
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      if (message.isForm) {
                        return _buildFormExample(isDarkMode);
                      }
                      return _buildMessageBubble(message, isDarkMode);
                    },
                  ),
                ),
                
                // Message input
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.white,
                    border: Border(
                      top: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Mesaj',
                              hintStyle: TextStyle(
                                color: isDarkMode ? Colors.white38 : Colors.grey,
                              ),
                              border: InputBorder.none,
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      FloatingActionButton(
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[800],
                        mini: true,
                        elevation: 4,
                        child: _isSendingMessage
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: isDarkMode ? Colors.white : Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: isDarkMode ? Colors.white : Colors.white,
                                size: 20,
                              ),
                        onPressed: _isSendingMessage ? null : _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFormExample(bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ürün Fikri Nasıl Paylaşılır",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildFormField(
              "Ürün Açıklaması:", 
              "Kullanıcıların fotoğraflarını AI ile iyileştiren bir mobil uygulama",
              isDarkMode,
            ),
            _buildFormField(
              "Çözdüğü Problem:", 
              "İnsanlar sosyal medya için düşük kalitede çektikleri fotoğrafları profesyonel görünümlü hale getirmek istiyorlar",
              isDarkMode,
            ),
            _buildFormField(
              "Hedef Kullanıcılar:", 
              "18-34 yaş arası, sosyal medyayı aktif kullanan kişiler",
              isDarkMode,
            ),
            _buildFormField(
              "Gelir Modeli:", 
              "Freemium model: temel özellikler ücretsiz, gelişmiş filtreler ve özellikler için aylık abonelik",
              isDarkMode,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Yukarıdaki örnek gibi ürün fikrinizi adım adım paylaşın",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, String example, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Text(
              example,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isDarkMode) {
    final isUserMessage = message.isUser;
    final bubbleColor = isUserMessage 
        ? (isDarkMode ? Colors.grey[800] : Colors.grey[300]) 
        : (isDarkMode ? Colors.grey[900] : Colors.white);
    
    Widget messageContent;
    if (message.evaluation != null) {
      final evaluation = message.evaluation!;
      final Color judgmentColor = evaluation.judgment == "DEVAM"
          ? Colors.green
          : evaluation.judgment == "PİVOT"
              ? Colors.amber
              : Colors.red;
              
      messageContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: judgmentColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              evaluation.judgment,
              style: TextStyle(
                color: judgmentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else {
      messageContent = Text(
        message.content,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 15.0,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUserMessage)
            CircleAvatar(
              backgroundColor: Colors.teal,
              radius: 16,
              child: const Text('AI', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 1.0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: messageContent,
            ),
          ),
          const SizedBox(width: 8.0),
          if (isUserMessage)
            const CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 