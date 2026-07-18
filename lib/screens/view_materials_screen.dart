import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../models/material_model.dart';
import '../services/firestore_service.dart';
import '../widgets/premium_background.dart';
import 'pdf_viewer_screen.dart';

class ViewMaterialsScreen extends StatelessWidget {
  final UserModel user;
  final FirestoreService _firestoreService = FirestoreService();

  ViewMaterialsScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Study Materials',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: PremiumBackground(
        child: StreamBuilder<List<MaterialModel>>(
          stream: user.role == 'faculty'
              ? _firestoreService.getMaterialsByBranch(user.branch)
              : _firestoreService.getMaterials(user.branch, user.semester, user.section),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (_, __) => ShimmerCard(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 12),
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const PremiumEmptyState(
                icon: Icons.folder_open_rounded,
                iconColor: Color(0xFF6366F1),
                title: 'No materials yet',
                subtitle: 'Materials will appear here\nonce uploaded by faculty',
              );
            }

            List<MaterialModel> materials = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: materials.length,
              itemBuilder: (context, index) {
                return _buildMaterialCard(context, materials[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, MaterialModel material) {
    final fileType = _getFileType(material.fileName);
    final fileColor = _getFileColor(fileType);
    final fileIcon = _getFileIcon(fileType);

    return GlassCard(
      glowColor: fileColor,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: fileColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(fileIcon, color: fileColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${material.uploaderName}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: fileColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fileType,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: fileColor),
                ),
              ),
              if (material.uploadedBy == user.uid) ...[
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  onPressed: () => _deleteMaterial(context, material),
                ),
              ],
            ],
          ),
          if (material.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              material.description,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                '${material.uploadedAt.day}/${material.uploadedAt.month}/${material.uploadedAt.year}',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
              const Spacer(),
              const Icon(Icons.download_outlined, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                '${material.downloadCount} downloads',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewMaterial(context, material),
                    icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
                    label: Text('View', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: material.fileName.startsWith('AI_Lecture_Notes_')
                      ? ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: material.fileUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Notes copied to clipboard!', style: GoogleFonts.inter()),
                                backgroundColor: const Color(0xFF0D9488),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                          label: Text('Copy Text', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _downloadMaterial(material),
                          icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                          label: Text('Download', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewMaterial(BuildContext context, MaterialModel material) {
    final fileNameLower = material.fileName.toLowerCase();
    final urlLower = material.fileUrl.toLowerCase();
    final isPdf = fileNameLower.endsWith('.pdf') || urlLower.contains('.pdf');
    final isAiNote = material.fileName.startsWith('AI_Lecture_Notes_') || fileNameLower.endsWith('.txt');

    if (isPdf || isAiNote) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PDFViewerScreen(material: material)),
      );
    } else {
      _downloadMaterial(material);
    }
  }

  void _downloadMaterial(MaterialModel material) async {
    _firestoreService.incrementDownloadCount(material.id);
    final Uri url = Uri.parse(material.fileUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Could not launch $url: $e');
    }
  }

  void _deleteMaterial(BuildContext parentContext, MaterialModel material) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: Text('Delete Material', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text('Are you sure you want to delete "${material.title}"?', style: GoogleFonts.inter(color: const Color(0xFFCBD5E1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              bool success = await _firestoreService.deleteMaterial(material.id);
              if (parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Material deleted' : 'Failed to delete material', style: GoogleFonts.inter()),
                    backgroundColor: success ? const Color(0xFF0D9488) : const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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

  String _getFileType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF';
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) return 'PPT';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'DOC';
    return 'FILE';
  }

  Color _getFileColor(String fileType) {
    switch (fileType) {
      case 'PDF': return const Color(0xFFEF4444);
      case 'PPT': return const Color(0xFF8B5CF6);
      case 'DOC': return const Color(0xFF3B82F6);
      default: return const Color(0xFF0D9488);
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'PDF': return Icons.picture_as_pdf_rounded;
      case 'PPT': return Icons.slideshow_rounded;
      case 'DOC': return Icons.description_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }
}