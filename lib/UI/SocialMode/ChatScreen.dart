import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String miUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
  
  // Variables del temporizador y estado
  Timer? _timer;
  int _secondsLeft = 300; // 5 minutos = 300 segundos
  bool _isPermanent = false;
  bool _iLiked = false;
  StreamSubscription<DocumentSnapshot>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningToChatDoc();
    
    // Temporizador local que actualiza la UI cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPermanent && _secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
        if (_secondsLeft == 0) {
          _handleTimeUp();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  // Escuchar el documento principal del chat para sincronizar el timer y los likes
  void _startListeningToChatDoc() {
    final docRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    
    _chatSubscription = docRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        // Si el documento se borró (quizás por el otro usuario), salimos.
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        return;
      }
      
      final data = snapshot.data() as Map<String, dynamic>;
      
      // Leer estado
      final isPerm = data['isPermanent'] ?? false;
      final likes = data['likes'] ?? {};
      final myLikeStatus = likes[miUserId] ?? false;
      
      // Sincronizar temporizador con la hora real de creación de la base de datos
      final createdAtEpoch = data['createdAtEpoch'];
      if (createdAtEpoch != null && !isPerm) {
        final nowEpoch = DateTime.now().millisecondsSinceEpoch;
        final diffSeconds = ((nowEpoch - createdAtEpoch) / 1000).floor();
        final remaining = 300 - diffSeconds;
        
        if (remaining <= 0 && !_isPermanent) {
           _secondsLeft = 0;
           _handleTimeUp();
        } else {
           _secondsLeft = remaining;
        }
      }

      // SOLO reconstruimos la pantalla si algo importante cambió
      // (evita el parpadeo al enviar mensajes)
      if (mounted && (_isPermanent != isPerm || _iLiked != myLikeStatus)) {
        setState(() {
          _isPermanent = isPerm;
          _iLiked = myLikeStatus;
        });
      }
    });
  }

  // Función al pulsar el botón de Like
  void _toggleLike() async {
    if (_iLiked) return; // Ya le has dado like

    final docRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    
    // 1. Guardamos nuestro like usando merge para no pisar el del otro
    await docRef.set({
      'likes': {
        miUserId: true,
      }
    }, SetOptions(merge: true));
    
    // 2. Verificamos inmediatamente si el otro también ha dado like
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final likes = docSnap.data()?['likes'] ?? {};
      
      // Comprobamos que todos los valores del mapa 'likes' sean true y haya 2 usuarios
      bool bothLiked = true;
      if (likes.length < 2) bothLiked = false; 
      likes.forEach((key, value) {
        if (value == false) bothLiked = false;
      });
      
      // 3. Si ambos han dado like, hacemos el chat permanente
      if (bothLiked) {
        await docRef.update({
          'isPermanent': true,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡Habéis conectado! El chat ahora es permanente. 🎉"),
              backgroundColor: Color(0xFF8B5CF6),
            )
          );
        }
      } else {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Le has dado like. Esperando a la otra persona..."),
              backgroundColor: Colors.white.withOpacity(0.2),
            )
          );
        }
      }
    }
  }

  // Función de muerte súbita
  void _handleTimeUp() async {
    if (_isPermanent) return;
    _timer?.cancel();
    
    try {
      final docRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      
      // Borrar todos los mensajes primero (necesario en Firestore para no dejar huérfanos)
      final messages = await docRef.collection('messages').get();
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }
      
      // Borrar el chat principal
      await docRef.delete();
    } catch(e) {
      print("Error borrando chat: $e");
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El tiempo se agotó. La conexión se ha perdido."),
          backgroundColor: Colors.redAccent,
        )
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    final docRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    
    await docRef.collection('messages').add({
      'senderId': miUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    await docRef.update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Helper para formatear los minutos
  String get _formattedTime {
    if (_secondsLeft <= 0) return "00:00";
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    // Si quedan menos de 60 segundos, el texto se pone rojo para dar urgencia
    final bool isUrgent = _secondsLeft <= 60 && !_isPermanent;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            const Expanded(
              child: Text(
                "Chat a Ciegas",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // TEMPORIZADOR
            if (!_isPermanent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isUrgent ? Colors.redAccent : Colors.transparent,
                    width: 1,
                  )
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 16, color: isUrgent ? Colors.redAccent : Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      _formattedTime,
                      style: TextStyle(
                        color: isUrgent ? Colors.redAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // BOTÓN DE LIKE
          if (!_isPermanent)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(
                  _iLiked ? Icons.favorite : Icons.favorite_border,
                  color: _iLiked ? Colors.pinkAccent : Colors.white70,
                  size: 28,
                ),
                onPressed: _toggleLike,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // MENSAJE DE CELEBRACIÓN (Cuando es permanente)
            if (_isPermanent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                child: const Center(
                  child: Text(
                    "¡Habéis conectado! El chat es permanente ✨",
                    style: TextStyle(color: Color(0xFFD946EF), fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // ÁREA DE MENSAJES (Firebase Firestore en Tiempo Real)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "¡Di hola! El tiempo corre... ⏳",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  
                  return ListView.builder(
                    reverse: true,
                    itemCount: docs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == miUserId;
                      final text = data['text'] ?? '';
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF6366F1) : const Color(0xFF334155),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 20),
                            ),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.3),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // ÁREA DE ESCRIBIR EL MENSAJE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Escribe un mensaje...",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFD946EF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
