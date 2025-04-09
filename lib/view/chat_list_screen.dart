import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../model/chat_list_model.dart';
import '../viewmodel/chat_list_viewmodel.dart';
import 'chat_screen.dart';
import 'import_dialog.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
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

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Sohbet listesini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ChatListViewModel>(context, listen: false);
      viewModel.loadChatList();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Color _getAvatarColor(String id) {
    final index = id.hashCode % _avatarColors.length;
    return _avatarColors[index.abs()];
  }

  String _getAIProviderIcon(AIProvider provider) {
    return provider == AIProvider.openai ? '🧠' : '🤖';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return DefaultTabController(
      length: 1,
      child: Consumer<ChatListViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: isDarkMode ? Color(0xFF121212) : Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
              elevation: 0,
              title: Text(
                'Mesaj AI',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Color(0xFF2D3748),
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              bottom: TabBar(
                indicatorColor: isDarkMode ? Color(0xFF6B8CFF) : Color(0xFF3B82F6),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline, 
                          color: isDarkMode ? Color(0xFF6B8CFF) : Color(0xFF3B82F6), 
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'SOHBETLER',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDarkMode ? Color(0xFF6B8CFF) : Color(0xFF3B82F6),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (viewModel.contacts.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Color(0xFF6B8CFF) : Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${viewModel.contacts.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildChatList(viewModel, isDarkMode),
              ],
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _fabAnimationController.forward(from: 0.0);
                    _showImportDialog(context, viewModel);
                  },
                  backgroundColor: isDarkMode ? Color(0xFF6B8CFF) : Color(0xFF3B82F6),
                  elevation: 4,
                  child: AnimatedBuilder(
                    animation: _fabAnimationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _fabAnimationController.value * math.pi * 2.0 / 8,
                        child: Icon(
                          Icons.add_comment, 
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: "brutalStrategist",
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.red,
                  onPressed: () {
                    Navigator.pushNamed(context, '/brutal_strategist');
                  },
                  child: const Icon(Icons.business),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatList(ChatListViewModel viewModel, bool isDarkMode) {
    // Hata durumunu kontrol et
    if (viewModel.error.isNotEmpty) {
      return _buildErrorPage(viewModel.error, isDarkMode);
    }
    
    return viewModel.contacts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: isDarkMode ? Color(0xFF6B8CFF) : Color(0xFF3B82F6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz sohbetiniz yok',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yeni bir sohbet başlatmak için + butonuna tıklayın',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white54 : Colors.black38,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
      itemCount: viewModel.contacts.length,
      itemBuilder: (context, index) {
        final contact = viewModel.contacts[index];
        final Color avatarColor = _getAvatarColor(contact.id);
        return Dismissible(
          key: Key(contact.id),
          background: Container(
            color: Colors.red[400],
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteDialog(context, viewModel, contact);
          },
          child: Hero(
            tag: 'avatar-${contact.id}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(contactId: contact.id),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.black12 : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: avatarColor,
                        child: Text(
                          contact.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      contact.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? Color(0xFF2D3748) : Color(0xFFEDF2F7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getAIProviderIcon(contact.aiProvider),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  DateFormat('HH:mm').format(contact.lastMessageTime),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white54 : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    contact.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (math.Random().nextBool())
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Color(0xFF6B8CFF) : Color(0xFF3B82F6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        math.Random().nextInt(5).toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImportDialog(BuildContext context, ChatListViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => ImportDialog(viewModel: viewModel),
    );
  }

  Future<bool> _showDeleteDialog(
    BuildContext context,
    ChatListViewModel viewModel,
    ChatContact contact,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sohbeti Sil',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '${contact.name} ile olan sohbeti silmek istediğinize emin misiniz?',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                viewModel.deleteContact(contact.id);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Hata sayfası widget'ı
  Widget _buildErrorPage(String errorMessage, bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 70,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF2D3748) : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red[400]!,
                  width: 1,
                ),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.red[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // ViewModel'den yeniden yüklemeyi çağırabiliriz
                final viewModel = Provider.of<ChatListViewModel>(
                  context, 
                  listen: false
                );
                viewModel.loadChatList();
              },
              icon: Icon(Icons.refresh),
              label: Text('Yeniden Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Color(0xFF6B8CFF) : Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 