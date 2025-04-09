import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service/chat_service.dart';
import 'service/gemini_service.dart';
import 'view/chat_list_screen.dart';
import 'viewmodel/chat_list_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ChatService>(
          create: (_) => ChatService(), // Sadece uyumluluk için tutuluyor
        ),
        Provider<GeminiService>(
          create: (_) => GeminiService(), // Gemini API ana servis olarak kullanılacak
        ),
        ChangeNotifierProxyProvider2<ChatService, GeminiService, ChatListViewModel>(
          create: (context) => ChatListViewModel(
            Provider.of<ChatService>(context, listen: false),
            Provider.of<GeminiService>(context, listen: false),
          ),
          update: (context, chatService, geminiService, viewModel) => 
            viewModel ?? ChatListViewModel(chatService, geminiService),
        ),
      ],
      child: MaterialApp(
        title: 'WhatsApp AI Sohbet',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const ChatListScreen(),
      ),
    );
  }
}
