import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/material_model.dart';
import '../models/message_model.dart';
import '../models/group_chat_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===================== MATERIALS =====================

  Future<bool> uploadMaterial({
    required String userId,
    required String title,
    required String description,
    required String branch,
    required String semester,
    required String section,
    required String fileUrl,
    required String fileName,
    required String uploaderName,
  }) async {
    try {
      String materialId = const Uuid().v4();
      await _firestore.collection('materials').doc(materialId).set({
        'id': materialId,
        'title': title,
        'description': description,
        'branch': branch,
        'semester': semester,
        'section': section,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'uploadedBy': userId,
        'uploaderName': uploaderName,
        'uploadedAt': DateTime.now().toIso8601String(),
        'downloadCount': 0,
      });
      return true;
    } catch (e) {
      print('Upload Material Error: $e');
      return false;
    }
  }

  Stream<List<MaterialModel>> getMaterials(
    String branch,
    String semester,
    String section,
  ) {
    return _firestore
        .collection('materials')
        .where('branch', isEqualTo: branch)
        .where('semester', isEqualTo: semester)
        .where('section', isEqualTo: section)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MaterialModel.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<MaterialModel>> getMaterialsByBranch(String branch) {
    return _firestore
        .collection('materials')
        .where('branch', isEqualTo: branch)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MaterialModel.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<MaterialModel>> getAllMaterials(String userId) {
    return _firestore
        .collection('materials')
        .where('uploadedBy', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MaterialModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<bool> deleteMaterial(String materialId) async {
    try {
      await _firestore.collection('materials').doc(materialId).delete();
      return true;
    } catch (e) {
      print('Delete Material Error: $e');
      return false;
    }
  }

  Future<bool> updateMaterial({
    required String materialId,
    required String title,
    required String description,
    required String branch,
    required String semester,
    required String section,
    String? fileUrl,
  }) async {
    try {
      await _firestore.collection('materials').doc(materialId).update({
        'title': title,
        'description': description,
        'branch': branch,
        'semester': semester,
        'section': section,
        if (fileUrl != null) 'fileUrl': fileUrl,
      });
      return true;
    } catch (e) {
      print('Update Material Error: $e');
      return false;
    }
  }

  Future<void> incrementDownloadCount(String materialId) async {
    try {
      await _firestore.collection('materials').doc(materialId).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Increment Download Error: $e');
    }
  }

  // ===================== 1-1 MESSAGING =====================

  Future<bool> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String message,
    String? fileUrl,
    String? fileName,
    String? fileType,
  }) async {
    try {
      String chatId = _getChatId(senderId, receiverId);
      String messageId = const Uuid().v4();

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set({
        'id': messageId,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileType != null) 'fileType': fileType,
      });

      await _firestore.collection('chats').doc(chatId).set({
        'participants': [senderId, receiverId],
        'lastMessage': fileUrl != null ? '📎 [Attachment] $fileName' : message,
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessageSenderId': senderId,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Send Message Error: $e');
      return false;
    }
  }

  Stream<List<MessageModel>> getMessages(String senderId, String receiverId) {
    String chatId = _getChatId(senderId, receiverId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getChatList(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // ===================== GROUP CHAT =====================

  Future<String?> createGroupChat({
    required String groupName,
    required List<String> memberIds,
    required List<String> memberNames,
    required String createdBy,
    String? description,
  }) async {
    try {
      String groupId = const Uuid().v4();
      await _firestore.collection('groupChats').doc(groupId).set({
        'id': groupId,
        'name': groupName,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'createdBy': createdBy,
        'createdAt': DateTime.now().toIso8601String(),
        'description': description,
      });
      return groupId;
    } catch (e) {
      print('Create Group Chat Error: $e');
      return null;
    }
  }

  Stream<List<GroupChatModel>> getUserGroupChats(String userId) {
    return _firestore
        .collection('groupChats')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GroupChatModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<bool> leaveGroup(String groupId, String userId, String userName) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('groupChats').doc(groupId).get();
      if (!doc.exists) return false;

      List<dynamic> memberIds = List.from(doc['memberIds'] ?? []);
      List<dynamic> memberNames = List.from(doc['memberNames'] ?? []);
      String createdBy = doc['createdBy'] ?? '';

      // If the admin (creator) leaves, or it's the last person, delete the group
      if (userId == createdBy || memberIds.length <= 1) {
        await _firestore.collection('groupChats').doc(groupId).delete();
        // Also clean up messages subcollection (optional but good)
        var messages = await _firestore.collection('groupChats').doc(groupId).collection('messages').get();
        for (var m in messages.docs) {
          await m.reference.delete();
        }
      } else {
        int index = memberIds.indexOf(userId);
        if (index != -1) {
          memberIds.removeAt(index);
          if (index < memberNames.length) {
            memberNames.removeAt(index);
          }
        }
        await _firestore.collection('groupChats').doc(groupId).update({
          'memberIds': memberIds,
          'memberNames': memberNames,
        });
      }
      return true;
    } catch (e) {
      print('Leave Group Error: $e');
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    try {
      await _firestore.collection('groupChats').doc(groupId).delete();
      var messages = await _firestore.collection('groupChats').doc(groupId).collection('messages').get();
      for (var m in messages.docs) {
        await m.reference.delete();
      }
      return true;
    } catch (e) {
      print('Delete Group Error: $e');
      return false;
    }
  }


  Future<bool> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String message,
    String? fileUrl,
    String? fileName,
    String? fileType,
  }) async {
    try {
      String messageId = const Uuid().v4();
      await _firestore
          .collection('groupChats')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .set({
        'id': messageId,
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileType != null) 'fileType': fileType,
      });

      await _firestore.collection('groupChats').doc(groupId).update({
        'lastMessage': fileUrl != null ? '📎 [Attachment] $fileName' : message,
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessageSenderId': senderId,
      });

      return true;
    } catch (e) {
      print('Send Group Message Error: $e');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groupChats')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<bool> deleteMessage({
    required String senderId,
    required String receiverId,
    required String messageId,
  }) async {
    try {
      String chatId = _getChatId(senderId, receiverId);
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      print('Delete Message Error: $e');
      return false;
    }
  }

  Future<bool> deleteGroupMessage({
    required String groupId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('groupChats')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      print('Delete Group Message Error: $e');
      return false;
    }
  }

  String _getChatId(String id1, String id2) {
    return id1.compareTo(id2) < 0 ? '${id1}_$id2' : '${id2}_$id1';
  }
}