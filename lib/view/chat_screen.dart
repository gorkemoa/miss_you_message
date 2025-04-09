import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../model/message_model.dart';
import '../model/chat_list_model.dart';
import '../viewmodel/chat_list_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  final String contactId;
  
  const ChatScreen({
    Key? key, 
    required this.contactId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AnimationController> _bubbleControllers = [];
  
  final List<Color> _avatarColors = [
    Colors.grey[800]!,
    Colors.grey[700]!,
    Colors.grey[600]!,
    Colors.blueGrey[700]!,
    Colors.blueGrey[800]!,
    Colors.black87,
    Colors.black54,
    Colors.black38,
  ];
  
  Color _getAvatarColor(String id) {
    final index = id.hashCode % _avatarColors.length;
    return _avatarColors[index.abs()];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    for (var controller in _bubbleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<ChatListViewModel>(
      builder: (context, viewModel, child) {
        // Sohbet kişisini bul
        final contactIndex = viewModel.contacts.indexWhere(
          (contact) => contact.id == widget.contactId
        );
        
        if (contactIndex == -1) {
          // Kişi bulunamadı durumu
          return Scaffold(
            appBar: AppBar(
              backgroundColor: isDarkMode ? Colors.black : Colors.white,
              title: Text(
                'Sohbet',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            body: Center(
              child: Text(
                'Kişi bulunamadı',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          );
        }
        
        final contact = viewModel.contacts[contactIndex];
        final Color avatarColor = _getAvatarColor(contact.id);
        
        return Scaffold(
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            titleSpacing: 0,
            elevation: 1,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back, 
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Hero(
                  tag: 'avatar-${contact.id}',
                  child: CircleAvatar(
                    backgroundColor: avatarColor,
                    radius: 20,
                    child: Text(
                      contact.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        viewModel.isLoading 
                            ? 'Yazıyor...' 
                            : 'Çevrimiçi',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white60 : Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
            ),
            child: Column(
              children: [
                if (viewModel.error.isNotEmpty)
                  Container(
                    color: Colors.red[100],
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      viewModel.error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: _buildChatUI(contact.messages, isDarkMode),
                ),
                // Bilge Demir için "Şaşırt Beni" butonu
                if (contact.predefinedPersona == PredefinedPersona.bilgeDemir)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        foregroundColor: isDarkMode ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: viewModel.isLoading 
                        ? null 
                        : () => viewModel.sendSurpriseFactRequest(contact.id),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lightbulb, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Şaşırt Beni!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildInputField(viewModel, isDarkMode),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatUI(List<Message> messages, bool isDarkMode) {
    if (_bubbleControllers.length < messages.length) {
      // Yeni mesajlar için animasyon kontrolcüleri oluştur
      for (int i = _bubbleControllers.length; i < messages.length; i++) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 400),
        );
        _bubbleControllers.add(controller);
        controller.forward();
      }
      
      // Yeni bir mesaj varsa, scroll'u en alta getir
      if (_bubbleControllers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }
    
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Henüz mesaj yok',
          style: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
      );
    }
    
    DateTime? previousDate;
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final controller = index < _bubbleControllers.length 
            ? _bubbleControllers[index] 
            : null;
        
        // Eğer gün değiştiyse tarih göster
        final messageDate = DateTime(
          message.timestamp.year,
          message.timestamp.month,
          message.timestamp.day,
        );
        
        final showDateDivider = previousDate == null || 
            previousDate != messageDate;
        
        previousDate = messageDate;
        
        return Column(
          children: [
            if (showDateDivider)
              _buildDateDivider(messageDate, isDarkMode),
            _buildMessageBubble(message, controller, isDarkMode),
          ],
        );
      },
    );
  }
  
  Widget _buildDateDivider(DateTime date, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.grey[800]!.withOpacity(0.9) 
                  : Colors.grey[300]!.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) {
      return 'Bugün';
    } else if (date == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('d MMMM y', 'tr_TR').format(date);
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('d MMMM', 'tr_TR').format(lastSeen);
    }
  }

  Widget _buildMessageBubble(Message message, AnimationController? controller, bool isDarkMode) {
    final isMe = message.isUser;
    final bubbleColor = isMe 
        ? (isDarkMode ? Colors.grey[800] : Colors.grey[300]) 
        : (isDarkMode ? Colors.grey[900] : Colors.white);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final alignment = isMe 
        ? CrossAxisAlignment.end 
        : CrossAxisAlignment.start;
    final bubblePosition = isMe 
        ? MainAxisAlignment.end 
        : MainAxisAlignment.start;
    
    // Mesajın saati
    final timeWidget = Text(
      DateFormat('HH:mm').format(message.timestamp),
      style: TextStyle(
        fontSize: 11,
        color: isDarkMode ? Colors.white38 : Colors.black38,
      ),
    );
    
    // Okundu işareti (sadece kullanıcı mesajları için)
    final readStatusWidget = isMe 
        ? Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Icon(
              Icons.done_all,
              size: 14,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
          )
        : const SizedBox();
    
    Widget bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 1.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                message.sender,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          Text(
            message.text,
            style: TextStyle(
              fontSize: 15, 
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              timeWidget,
              if (isMe) readStatusWidget,
            ],
          ),
        ],
      ),
    );
    
    // Animasyon ekle
    if (controller != null) {
      bubble = SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isMe ? 1 : -1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        )),
        child: FadeTransition(
          opacity: controller,
          child: bubble,
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: bubblePosition,
            children: [bubble],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(ChatListViewModel viewModel, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      color: isDarkMode ? Colors.black : Colors.white,
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
                onSubmitted: (text) => _sendMessage(viewModel),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[800],
            mini: true,
            elevation: 4,
            child: viewModel.isLoading
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
            onPressed: viewModel.isLoading ? null : () => _sendMessage(viewModel),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ChatListViewModel viewModel) {
    if (_messageController.text.trim().isEmpty) return;
    
    viewModel.sendMessage(widget.contactId, _messageController.text);
    _messageController.clear();
    
    // Mesaj gönderildikten sonra aşağı kaydır
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }
} 