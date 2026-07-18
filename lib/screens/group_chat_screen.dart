import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../models/user_model.dart';
import '../models/group_chat_model.dart';
import '../models/material_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/premium_background.dart';
import 'pdf_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupChatScreen extends StatefulWidget {
  final UserModel user;

  const GroupChatScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedTab = 0;
  String? _filterSemester;
  String? _filterSection;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.user.role == 'faculty' ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Group Study',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          bottom: widget.user.role == 'faculty'
              ? TabBar(
                  onTap: (index) => setState(() => _selectedTab = index),
                  labelColor: const Color(0xFF6366F1),
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  indicatorColor: const Color(0xFF6366F1),
                  tabs: const [
                    Tab(text: 'My Groups'),
                    Tab(text: 'Create'),
                  ],
                )
              : null,
        ),
        body: PremiumBackground(
          child: widget.user.role == 'faculty'
              ? (_selectedTab == 0 ? _buildGroupsList() : _buildCreateGroup())
              : _buildGroupsList(),
        ),
      ),
    );
  }

  Widget _buildGroupsList() {
    return StreamBuilder<List<GroupChatModel>>(
      stream: _firestoreService.getUserGroupChats(widget.user.uid),
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
                  child: const Icon(Icons.groups_rounded, color: Color(0xFFE11D48), size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'No groups yet',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.user.role == 'faculty'
                      ? 'Create a group from the Create tab'
                      : 'Your teacher will add you to groups',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        List<GroupChatModel> groups = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            GroupChatModel group = groups[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupChatDetailScreen(group: group, currentUser: widget.user),
                ),
              ),
              child: GlassCard(
                glowColor: const Color(0xFFE11D48),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFE11D48).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE11D48).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${group.memberIds.length} members',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFFF859B)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: const Color(0xFF0F172A),
                      onSelected: (value) {
                        if (value == 'members') _showMembers(context, group);
                        else if (value == 'leave') _leaveGroup(context, group);
                        else if (value == 'delete') _deleteGroup(context, group);
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.08))),
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'members',
                          child: Row(children: [
                            const Icon(Icons.people_outline_rounded, size: 18, color: Color(0xFF6366F1)),
                            const SizedBox(width: 10),
                            Text('View Members', style: GoogleFonts.inter(color: Colors.white)),
                          ]),
                        ),
                        if (group.createdBy == widget.user.uid)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                              const SizedBox(width: 10),
                              Text('Delete Group', style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
                            ]),
                          )
                        else
                          PopupMenuItem(
                            value: 'leave',
                            child: Row(children: [
                              const Icon(Icons.exit_to_app_rounded, size: 18, color: Color(0xFFEF4444)),
                              const SizedBox(width: 10),
                              Text('Leave Group', style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
                            ]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateGroup() {
    final groupNameController = TextEditingController();
    final descriptionController = TextEditingController();
    List<String> selectedMembers = [];

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Group Details', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 14),
              TextField(
                controller: groupNameController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  prefixIcon: Icon(Icons.groups_rounded, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description_outlined, color: Color(0xFF94A3B8)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Text('Add Members', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 12),
              Row(
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
                      onChanged: (val) {
                        setState(() => _filterSemester = val);
                        setLocalState(() {});
                      },
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
                      onChanged: (val) {
                        setState(() => _filterSection = val);
                        setLocalState(() {});
                      },
                      decoration: const InputDecoration(labelText: 'Section', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: () {
                  Query query = FirebaseFirestore.instance
                      .collection('users')
                      .where('branch', isEqualTo: widget.user.branch);
                  if (_filterSemester != null) query = query.where('semester', isEqualTo: _filterSemester);
                  if (_filterSection != null) query = query.where('section', isEqualTo: _filterSection);
                  return query.snapshots();
                }(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red)),
                    ));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                    ));
                  }
                  
                  List<UserModel> users = [];
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    users = snapshot.data!.docs
                        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
                        .where((u) => u.uid != widget.user.uid)
                        .toList();
                  }

                  if (users.isEmpty) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No students found in this class', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 15)),
                    ));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      UserModel u = users[index];
                      bool isSelected = selectedMembers.contains(u.uid);
                      return GestureDetector(
                        onTap: () {
                          setLocalState(() {
                            if (isSelected) selectedMembers.remove(u.uid);
                            else selectedMembers.add(u.uid);
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.12) : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.08),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.08),
                                child: Text(
                                  u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                                  style: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                                    Text(u.email, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1), size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _createGroup(groupNameController.text, descriptionController.text, selectedMembers),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text('Create Group', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _createGroup(String groupName, String description, List<String> memberIds) async {
    if (groupName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid group name', style: GoogleFonts.inter()), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
      return;
    }
    if (memberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one member', style: GoogleFonts.inter()), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
      return;
    }

    List<String> finalMemberIds = [widget.user.uid];
    List<String> finalMemberNames = [widget.user.name];

    for (String memberId in memberIds) {
      if (memberId != widget.user.uid) {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(memberId).get();
        if (doc.exists) {
          finalMemberIds.add(memberId);
          finalMemberNames.add(doc['name'] ?? 'Unknown');
        }
      }
    }

    String? groupId = await _firestoreService.createGroupChat(
      groupName: groupName,
      memberIds: finalMemberIds,
      memberNames: finalMemberNames,
      createdBy: widget.user.uid,
      description: description,
    );

    if (groupId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created successfully!', style: GoogleFonts.inter()), backgroundColor: const Color(0xFF0D9488), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
      setState(() => _selectedTab = 0);
    }
  }

  void _showMembers(BuildContext context, GroupChatModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: Text('Group Members', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: group.memberIds.length,
            itemBuilder: (context, index) {
              final name = group.memberNames.length > index ? group.memberNames[index] : 'Unknown';
              final isAdmin = group.createdBy == group.memberIds[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white))),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text('Admin', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6366F1))),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: Text('Close', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _leaveGroup(BuildContext parentContext, GroupChatModel group) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: Text('Leave Group', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text('Are you sure you want to leave "${group.name}"?', style: GoogleFonts.inter(color: const Color(0xFFCBD5E1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
           ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              bool success = await _firestoreService.leaveGroup(group.id, widget.user.uid, widget.user.name);
              if (parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text(success ? 'Left group successfully' : 'Failed to leave group', style: GoogleFonts.inter()), backgroundColor: success ? const Color(0xFF0D9488) : const Color(0xFFEF4444), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Leave', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(BuildContext parentContext, GroupChatModel group) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: Text('Delete Group', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text('Are you sure you want to permanently delete "${group.name}"? This will delete all messages for everyone.', style: GoogleFonts.inter(color: const Color(0xFFCBD5E1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              bool success = await _firestoreService.deleteGroup(group.id);
              if (parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text(success ? 'Group deleted successfully' : 'Failed to delete group', style: GoogleFonts.inter()), backgroundColor: success ? const Color(0xFF0D9488) : const Color(0xFFEF4444), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class GroupChatDetailScreen extends StatefulWidget {
  final GroupChatModel group;
  final UserModel currentUser;

  const GroupChatDetailScreen({Key? key, required this.group, required this.currentUser}) : super(key: key);

  @override
  State<GroupChatDetailScreen> createState() => _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends State<GroupChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;

  final AIService _aiService = AIService();
  List<Map<String, dynamic>> _currentMessages = [];

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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE11D48).withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.group.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                Text('${widget.group.memberIds.length} members', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1))),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _showChatSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                elevation: 0,
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 14),
              label: Text(
                'AI SUMMARY',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF0F172A),
            onSelected: (value) {
              if (value == 'members') _showMembers(context, widget.group);
              else if (value == 'leave') _leaveGroup(context, widget.group);
              else if (value == 'delete') _deleteGroup(context, widget.group);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.08))),
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'members',
                child: Row(children: [
                  const Icon(Icons.people_outline_rounded, size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Text('View Members', style: GoogleFonts.inter(color: Colors.white)),
                ]),
              ),
              if (widget.group.createdBy == widget.currentUser.uid)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 10),
                    Text('Delete Group', style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
                  ]),
                )
              else
                PopupMenuItem(
                  value: 'leave',
                  child: Row(children: [
                    const Icon(Icons.exit_to_app_rounded, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 10),
                    Text('Leave Group', style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
                  ]),
                ),
            ],
          ),
        ],
      ),
      body: PremiumBackground(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.getGroupMessages(widget.group.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
                  }

                  List<Map<String, dynamic>> messages = snapshot.data!;
                  _currentMessages = messages;
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
                      child: Text('No messages yet. Say hello! 👋', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 15)),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      bool isMe = message['senderId'] == widget.currentUser.uid;
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

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final hasAttachment = message['fileUrl'] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  message['senderName'] ?? 'Unknown',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF38BDF8)),
                ),
              ),
            GestureDetector(
              onLongPress: isMe ? () => _showDeleteConfirmationDialog(message['id'] ?? '') : null,
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
                  if (message['message'] != null && message['message'].toString().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: hasAttachment ? 4.0 : 0.0),
                      child: Text(
                        message['message'] ?? '',
                        style: GoogleFonts.inter(color: isMe ? Colors.white : const Color(0xFFF8FAFC), fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('HH:mm').format(DateTime.parse(message['timestamp'])),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAttachment(Map<String, dynamic> message, bool isMe) {
    final fileUrl = message['fileUrl'] as String;
    final fileName = message['fileName'] as String? ?? 'Attachment';
    final fileType = message['fileType'] as String? ?? 'document';

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
              id: message['id'] ?? '',
              title: fileName,
              description: '',
              branch: '',
              semester: '',
              section: '',
              fileUrl: fileUrl,
              fileName: fileName,
              uploadedBy: message['senderId'] ?? '',
              uploaderName: message['senderName'] ?? '',
              uploadedAt: message['timestamp'] ?? '',
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
        SnackBar(content: Text('Error opening link: $e', style: GoogleFonts.inter()), backgroundColor: const Color(0xFFEF4444)),
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
                hintText: 'Message the group...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
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

  void _pickAndUploadAttachment() async {
    setState(() => _isUploading = true);
    final result = await _storageService.uploadChatAttachment(widget.currentUser.uid);
    setState(() => _isUploading = false);

    if (result != null) {
      await _firestoreService.sendGroupMessage(
        groupId: widget.group.id,
        senderId: widget.currentUser.uid,
        senderName: widget.currentUser.name,
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
    await _firestoreService.sendGroupMessage(
      groupId: widget.group.id,
      senderId: widget.currentUser.uid,
      senderName: widget.currentUser.name,
      message: text,
    );
  }

  void _showMembers(BuildContext context, GroupChatModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: Text('Group Members', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: group.memberIds.length,
            itemBuilder: (context, index) {
              final name = group.memberNames.length > index ? group.memberNames[index] : 'Unknown';
              final isAdmin = group.createdBy == group.memberIds[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white))),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text('Admin', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6366F1))),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: Text('Close', style: GoogleFonts.inter(color: Colors.white)),
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
                bool success = await _firestoreService.deleteGroupMessage(
                  groupId: widget.group.id,
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

  void _leaveGroup(BuildContext parentContext, GroupChatModel group) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: Text('Leave Group', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text('Are you sure you want to leave "${group.name}"?', style: GoogleFonts.inter(color: const Color(0xFFCBD5E1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              bool success = await _firestoreService.leaveGroup(group.id, widget.currentUser.uid, widget.currentUser.name);
              if (parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text(success ? 'Left group successfully' : 'Failed to leave group', style: GoogleFonts.inter()), backgroundColor: success ? const Color(0xFF0D9488) : const Color(0xFFEF4444), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                );
                if (success) {
                  Navigator.pop(parentContext); // Pop the detail screen
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Leave', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(BuildContext parentContext, GroupChatModel group) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: Text('Delete Group', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text('Are you sure you want to permanently delete "${group.name}"? This will delete all messages for everyone.', style: GoogleFonts.inter(color: const Color(0xFFCBD5E1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              bool success = await _firestoreService.deleteGroup(group.id);
              if (parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text(success ? 'Group deleted successfully' : 'Failed to delete group', style: GoogleFonts.inter()), backgroundColor: success ? const Color(0xFF0D9488) : const Color(0xFFEF4444), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                );
                if (success) {
                  Navigator.pop(parentContext); // Pop the detail screen
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
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

  void _showChatSummary() {
    if (_currentMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No messages to summarize yet!', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: FutureBuilder<String>(
                future: _generateSummaryFuture(),
                builder: (context, snapshot) {
                  final isLoading = snapshot.connectionState == ConnectionState.waiting;
                  final hasError = snapshot.hasError;
                  final rawSummary = snapshot.data ?? '';
                  final summary = _cleanMarkdown(rawSummary);

                  return Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F19).withOpacity(0.92),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Chat Summarizer',
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                Text(
                                  'AI smart study insights',
                                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        Expanded(
                          child: isLoading
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF6366F1)),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Analyzing conversation topics...',
                                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Identifying action items & key decisions',
                                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                )
                              : hasError
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Failed to generate summary',
                                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Please check your connection and try again.',
                                            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Scrollbar(
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.02),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                                          ),
                                          child: Text(
                                            summary,
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFFE2E8F0),
                                              fontSize: 14,
                                              height: 1.55,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                        ),
                        if (!isLoading && !hasError) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: summary));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Summary copied to clipboard!', style: GoogleFonts.inter()),
                                          backgroundColor: const Color(0xFF0D9488),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                                    label: Text('Copy to Clipboard', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      _postSummaryToChat(summary);
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                    label: Text('Post to Chat', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _generateSummaryFuture() {
    List<Map<String, dynamic>> chatMessages = _currentMessages.map((m) {
      return {
        'senderName': m['senderName'] ?? 'Student',
        'message': m['message'] ?? '',
      };
    }).toList();
    return _aiService.generateGroupChatSummary(chatMessages);
  }

  void _postSummaryToChat(String summary) {
    final systemMessage = '✨ **AI Study Summarizer Insights** ✨\n\n$summary';
    _firestoreService.sendGroupMessage(
      groupId: widget.group.id,
      senderId: widget.currentUser.uid,
      senderName: '${widget.currentUser.name} (AI Summarizer)',
      message: systemMessage,
    );
  }

  String _cleanMarkdown(String text) {
    return text
        // Remove markdown headers (e.g. ###, ##, #)
        .replaceAll(RegExp(r'#+\s*'), '')
        // Remove bold formatting tags (e.g. **)
        .replaceAll(RegExp(r'\*\*'), '');
  }
}