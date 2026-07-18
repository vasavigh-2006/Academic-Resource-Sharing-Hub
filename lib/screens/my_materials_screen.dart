import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/premium_background.dart';
import 'pdf_viewer_screen.dart';
import '../models/material_model.dart';
import '../services/firestore_service.dart';

class MyMaterialsScreen extends StatelessWidget {
  final String userId;
  final FirestoreService _firestoreService = FirestoreService();

  MyMaterialsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'My Uploaded Materials',
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
          stream: _firestoreService.getAllMaterials(userId),
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
                icon: Icons.cloud_upload_rounded,
                iconColor: Color(0xFF8B5CF6),
                title: 'No uploads yet',
                subtitle: 'Materials you upload\nwill appear here',
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${material.branch} • Sem ${material.semester} • Sec ${material.section}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF0F172A),
                onSelected: (value) {
                  if (value == 'view') _viewMaterial(context, material);
                  else if (value == 'edit') _editMaterial(context, material);
                  else if (value == 'delete') _deleteMaterial(context, material);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.08))),
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(children: [
                      const Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF6366F1)),
                      const SizedBox(width: 10),
                      Text('View', style: GoogleFonts.inter(color: Colors.white)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 10),
                      Text('Edit', style: GoogleFonts.inter(color: Colors.white)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_rounded, size: 18, color: Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: fileColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(fileType, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: fileColor)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.download_outlined, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                '${material.downloadCount} downloads',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                '${material.uploadedAt.day}/${material.uploadedAt.month}/${material.uploadedAt.year}',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
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
    final Uri url = Uri.parse(material.fileUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Could not launch $url: $e');
    }
  }

  void _editMaterial(BuildContext context, MaterialModel material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: _EditMaterialSheet(
            material: material,
            onUpdated: () {},
          ),
        );
      },
    );
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

class _EditMaterialSheet extends StatefulWidget {
  final MaterialModel material;
  final VoidCallback onUpdated;

  const _EditMaterialSheet({
    Key? key,
    required this.material,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<_EditMaterialSheet> createState() => _EditMaterialSheetState();
}

class _EditMaterialSheetState extends State<_EditMaterialSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteContentController;
  String? _selectedBranch;
  String? _selectedSemester;
  String? _selectedSection;
  bool _isSaving = false;

  final List<String> _branches = ['CS', 'IT', 'EC', 'ME', 'AIML', 'AIDS'];
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> _sections = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V'
  ];

  bool get _isAiNote => widget.material.fileName.startsWith('AI_Lecture_Notes_');

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.material.title);
    _descriptionController = TextEditingController(text: widget.material.description);
    _noteContentController = TextEditingController(text: widget.material.fileUrl);
    _selectedBranch = widget.material.branch;
    _selectedSemester = widget.material.semester;
    _selectedSection = widget.material.section;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteContentController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranch == null || _selectedSemester == null || _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select branch, semester, and section', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final firestoreService = FirestoreService();
    bool success = await firestoreService.updateMaterial(
      materialId: widget.material.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      branch: _selectedBranch!,
      semester: _selectedSemester!,
      section: _selectedSection!,
      fileUrl: _isAiNote ? _noteContentController.text : null,
    );
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material updated successfully!', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onUpdated();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update material. Please try again.', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19).withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
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
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Material',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(
                      _isAiNote ? 'AI generated study draft' : widget.material.fileName,
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Material Title *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Unit 3 Notes',
                        prefixIcon: Icon(Icons.title_rounded, color: Color(0xFF94A3B8), size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Description'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Brief description...',
                        prefixIcon: Icon(Icons.notes_rounded, color: Color(0xFF94A3B8), size: 20),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Branch *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBranch,
                      dropdownColor: const Color(0xFF0F172A),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      items: _branches.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (value) => setState(() => _selectedBranch = value),
                      decoration: const InputDecoration(
                        hintText: 'Select branch',
                        prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF94A3B8), size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Semester *'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedSemester,
                                dropdownColor: const Color(0xFF0F172A),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                items: _semesters.map((e) => DropdownMenuItem(value: e, child: Text('Sem $e'))).toList(),
                                onChanged: (value) => setState(() => _selectedSemester = value),
                                decoration: const InputDecoration(
                                  hintText: 'Semester',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Section *'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedSection,
                                dropdownColor: const Color(0xFF0F172A),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                items: _sections.map((e) => DropdownMenuItem(value: e, child: Text('Sec $e'))).toList(),
                                onChanged: (value) => setState(() => _selectedSection = value),
                                decoration: const InputDecoration(
                                  hintText: 'Section',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isAiNote) ...[
                      const SizedBox(height: 24),
                      _buildLabel('Note Content (Edit AI text content) *'),
                      const SizedBox(height: 8),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: TextFormField(
                          controller: _noteContentController,
                          maxLines: null,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: false,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Notes content cannot be empty' : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Text('Save Changes', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
    );
  }
}