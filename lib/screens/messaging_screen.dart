import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/material_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/premium_background.dart';
import 'pdf_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MessagingScreen extends StatefulWidget {
  final UserModel user;

  const MessagingScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  String? _filterSemester;
  String? _filterSection;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Messages',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'People'),
          ],
        ),
      ),
      body: PremiumBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildChatsList(),
            _buildUsersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getChatList(widget.user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF6366F1), size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start a conversation from People tab',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> chats = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index];
            String otherUserId = (chat['participants'] as List)
                .firstWhere((id) => id != widget.user.uid);

            return FutureBuilder<UserModel?>(
              future: _getUser(otherUserId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox.shrink();

                UserModel otherUser = userSnapshot.data!;
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatDetailScreen(
                      currentUser: widget.user,
                      otherUser: otherUser,
                    )),
                  ),
                  child: GlassCard(
                    glowColor: const Color(0xFF6366F1),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
                          child: Text(
                            otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6366F1),
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                otherUser.name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chat['lastMessage'] ?? 'No messages yet',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFFCBD5E1),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUsersList() {
    return Column(
      children: [
        if (widget.user.role == 'faculty')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterSemester,
                    dropdownColor: const Color(0xFF0F172A),
                    style: GoogleFonts.inter(color: Colors.white),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Sem')),
                      ...widget.user.semester.split(', ').map((s) => DropdownMenuItem(value: s, child: Text('Sem $s'))),
                    ],
                    onChanged: (val) => setState(() => _filterSemester = val),
                    decoration: const InputDecoration(labelText: 'Semester', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterSection,
                    dropdownColor: const Color(0xFF0F172A),
                    style: GoogleFonts.inter(color: Colors.white),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Sec')),
                      ...widget.user.section.split(', ').map((s) => DropdownMenuItem(value: s, child: Text('Sec $s'))),
                    ],
                    onChanged: (val) => setState(() => _filterSection = val),
                    decoration: const InputDecoration(labelText: 'Section', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('branch', isEqualTo: widget.user.branch)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: 6,
                  itemBuilder: (_, __) => ShimmerCard(
                    height: 68,
                    margin: const EdgeInsets.only(bottom: 10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: 6,
                  itemBuilder: (_, __) => ShimmerCard(
                    height: 68,
                    margin: const EdgeInsets.only(bottom: 10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                );
              }

              List<UserModel> users = snapshot.data!.docs
                  .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
                  .where((u) => u.uid != widget.user.uid) // Exclude current user
                  .toList();

              if (widget.user.role == 'student') {
                users = users.where((u) {
                  if (u.role == 'faculty') {
                    final teacherSems = u.semester.split(', ');
                    final teacherSecs = u.section.split(', ');
                    return teacherSems.contains(widget.user.semester) && teacherSecs.contains(widget.user.section);
                  } else if (u.role == 'student') {
                    return u.semester == widget.user.semester && u.section == widget.user.section;
                  }
                  return false;
                }).toList();
              } else if (widget.user.role == 'faculty') {
                users = users.where((u) {
                  if (u.role == 'faculty') {
                    return true;
                  } else if (u.role == 'student') {
                    if (_filterSemester != null && u.semester != _filterSemester) return false;
                    if (_filterSection != null && u.section != _filterSection) return false;
                    return true;
                  }
                  return false;
                }).toList();
              }

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 64, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text(
                        'No users found',
                        style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  UserModel otherUser = users[index];
                  final isOtherFaculty = otherUser.role == 'faculty';
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatDetailScreen(
                        currentUser: widget.user,
                        otherUser: otherUser,
                      )),
                    ),
                    child: GlassCard(
                      glowColor: isOtherFaculty ? const Color(0xFF6366F1) : const Color(0xFF0D9488),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: (isOtherFaculty ? const Color(0xFF6366F1) : const Color(0xFF0D9488)).withOpacity(0.12),
                            child: Text(
                              otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(
                                color: isOtherFaculty ? const Color(0xFF6366F1) : const Color(0xFF0D9488),
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherUser.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  otherUser.email,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isOtherFaculty ? const Color(0xFF6366F1) : const Color(0xFF0D9488)).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              otherUser.role.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isOtherFaculty ? const Color(0xFF6366F1) : const Color(0xFF0D9488),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<UserModel?> _getUser(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    return null;
  }
}

class ChatDetailScreen extends StatefulWidget {
  final UserModel currentUser;
  final UserModel otherUser;

  const ChatDetailScreen({Key? key, required this.currentUser, required this.otherUser}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
              child: Text(
                widget.otherUser.name.isNotEmpty ? widget.otherUser.name[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.otherUser.role.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: PremiumBackground(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _firestoreService.getMessages(widget.currentUser.uid, widget.otherUser.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
                  }

                  List<MessageModel> messages = snapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Say hello! 👋',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      MessageModel message = messages[index];
                      bool isMe = message.senderId == widget.currentUser.uid;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final hasAttachment = message.fileUrl != null && message.fileUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: isMe ? () => _showDeleteConfirmationDialog(message.id) : null,
          child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isMe ? null : const Color(0xFF0F172A).withOpacity(0.65),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
            border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: isMe ? const Color(0xFF6366F1).withOpacity(0.18) : Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasAttachment)
                _buildAttachment(message, isMe),
              if (message.message.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: hasAttachment ? 4.0 : 0.0),
                  child: Text(
                    message.message,
                    style: GoogleFonts.inter(
                      color: isMe ? Colors.white : const Color(0xFFF8FAFC),
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildAttachment(MessageModel message, bool isMe) {
    final fileUrl = message.fileUrl as String;
    final fileName = message.fileName ?? 'Attachment';
    final fileType = message.fileType ?? 'document';

    if (fileType == 'image') {
      return GestureDetector(
        onTap: () => _openImagePreview(fileUrl, fileName),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: const BoxConstraints(maxHeight: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fileUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 120,
                  color: Colors.white.withOpacity(0.03),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: Colors.white.withOpacity(0.05),
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: Color(0xFFEF4444), size: 36),
                  ),
                );
              },
            ),
          ),
        ),
      );
    } else {
      // Document
      final isPdf = fileName.toLowerCase().endsWith('.pdf');
      return GestureDetector(
        onTap: () {
          if (isPdf) {
            final syntheticMaterial = MaterialModel(
              id: message.id,
              title: fileName,
              description: '',
              branch: '',
              semester: '',
              section: '',
              fileUrl: fileUrl,
              fileName: fileName,
              uploadedBy: message.senderId,
              uploaderName: message.senderName,
              uploadedAt: message.timestamp,
              downloadCount: 0,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PDFViewerScreen(material: syntheticMaterial),
              ),
            );
          } else {
            _launchURL(fileUrl);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (isPdf ? const Color(0xFFEF4444) : const Color(0xFF6366F1)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                  color: isPdf ? const Color(0xFFF87171) : const Color(0xFF818CF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPdf ? 'Tap to view PDF' : 'Tap to open document',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: Colors.white.withOpacity(0.6), size: 16),
            ],
          ),
        ),
      );
    }
  }

  void _openImagePreview(String url, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.6),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file link', style: GoogleFonts.inter()), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file link', style: GoogleFonts.inter()), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF090D1A).withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.2)),
      ),
      child: Row(
        children: [
          // Attachment Plus Button / Loading Indicator
          _isUploading
              ? Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(12),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF6366F1),
                  ),
                )
              : Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    onPressed: _pickAndUploadAttachment,
                  ),
                ),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
                filled: true,
                fillColor: const Color(0xFF0F172A).withOpacity(0.8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String messageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.2),
          ),
          title: Text(
            'Delete Message?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete this message for everyone?',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                bool success = await _firestoreService.deleteMessage(
                  senderId: widget.currentUser.uid,
                  receiverId: widget.otherUser.uid,
                  messageId: messageId,
                );
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message deleted for everyone', style: GoogleFonts.inter(color: Colors.white)),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete message', style: GoogleFonts.inter(color: Colors.white)),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _pickAndUploadAttachment() async {
    setState(() => _isUploading = true);
    final result = await _storageService.uploadChatAttachment(widget.currentUser.uid);
    setState(() => _isUploading = false);

    if (result != null) {
      await _firestoreService.sendMessage(
        senderId: widget.currentUser.uid,
        senderName: widget.currentUser.name,
        receiverId: widget.otherUser.uid,
        message: '',
        fileUrl: result['url'],
        fileName: result['fileName'],
        fileType: result['fileType'],
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text.trim();
    _messageController.clear();
    await _firestoreService.sendMessage(
      senderId: widget.currentUser.uid,
      senderName: widget.currentUser.name,
      receiverId: widget.otherUser.uid,
      message: text,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}