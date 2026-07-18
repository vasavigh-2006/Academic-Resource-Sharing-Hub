import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_background.dart';
import '../services/ai_service.dart';

class UploadMaterialScreen extends StatefulWidget {
  final String userId;

  const UploadMaterialScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedBranch, _selectedSemester, _selectedSection;
  Map<String, String>? _uploadedFile;
  bool _isUploading = false;

  // AI note drafting variables
  final AIService _aiService = AIService();
  bool _isAiMode = false;
  bool _isGeneratingAi = false;
  String? _draftedNotes;
  final TextEditingController _aiTopicController = TextEditingController();
  final TextEditingController _draftedNotesController = TextEditingController();

  final List<String> _branches = ['CS', 'IT', 'EC', 'ME', 'AIML', 'AIDS'];
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> _sections = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Upload Material',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: PremiumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload PDFs, PPTs, and Word documents for your students.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mode Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isAiMode = false;
                          _uploadedFile = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isAiMode ? const Color(0xFF6366F1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Local File Upload',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !_isAiMode ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isAiMode = true;
                          _uploadedFile = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isAiMode ? const Color(0xFF6366F1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'AI Draft',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isAiMode ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Material Title *'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Unit 3 - Data Structures Notes',
                  prefixIcon: Icon(Icons.title_rounded, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Description'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Brief description of this material...',
                  prefixIcon: Icon(Icons.notes_rounded, color: Color(0xFF94A3B8)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Branch *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                dropdownColor: const Color(0xFF0F172A),
                style: GoogleFonts.inter(color: Colors.white),
                items: _branches.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => setState(() => _selectedBranch = value),
                decoration: const InputDecoration(
                  hintText: 'Select branch',
                  prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF94A3B8)),
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
                          style: GoogleFonts.inter(color: Colors.white),
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
                          style: GoogleFonts.inter(color: Colors.white),
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
              const SizedBox(height: 28),

              // File upload or AI generation section
              if (!_isAiMode) ...[
                _buildLabel('Upload File *'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _uploadedFile == null ? _pickAndUploadFile : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _uploadedFile != null ? const Color(0xFF0D9488).withOpacity(0.12) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _uploadedFile != null ? const Color(0xFF0D9488) : Colors.white.withOpacity(0.08),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _isUploading
                      ? const Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF6366F1)),
                            SizedBox(height: 12),
                            Text('Uploading file...', style: TextStyle(color: Colors.white70)),
                          ],
                        )
                      : _uploadedFile != null
                          ? Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'File uploaded!',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0D9488)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _uploadedFile!['fileName'] ?? '',
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                                  onPressed: () => setState(() => _uploadedFile = null),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const Icon(Icons.cloud_upload_outlined, color: Color(0xFF94A3B8), size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to select a file',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PDF, PPT, PPTX, DOC, DOCX supported',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                  ),
                ),
                if (_uploadedFile != null && !_uploadedFile!['fileName']!.toLowerCase().endsWith('.pdf')) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFCA5A5), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Notice: Non-PDF files cannot be viewed in-app or summarized by DocuChat AI. We highly recommend converting your file to PDF before uploading.',
                            style: GoogleFonts.inter(color: const Color(0xFFFCA5A5), fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                _buildAiDraftSection(),
              ],
              const SizedBox(height: 32),

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
                  onPressed: _isUploading ? null : _submitMaterial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text('Submit Material', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFFCBD5E1)),
    );
  }

  void _pickAndUploadFile() async {
    if (_selectedBranch == null || _selectedSemester == null || _selectedSection == null) {
      _showSnackBar('Please select branch, semester, and section first');
      return;
    }
    setState(() => _isUploading = true);
    try {
      Map<String, String>? result = await _storageService.uploadMaterial(widget.userId);
      setState(() => _isUploading = false);

      if (result != null) {
        setState(() => _uploadedFile = result);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      String errStr = e.toString();
      if (errStr.startsWith('Exception: ')) {
        errStr = errStr.substring(11); // Remove "Exception: "
      }
      _showSnackBar('Upload failed: $errStr');
    }
  }

  void _submitMaterial() async {
    if (_titleController.text.isEmpty) {
      _showSnackBar('Please enter a title');
      return;
    }
    if (_selectedBranch == null || _selectedSemester == null || _selectedSection == null) {
      _showSnackBar('Please select branch, semester, and section');
      return;
    }
    if (_uploadedFile == null) {
      _showSnackBar(_isAiMode ? 'Please draft AI notes first' : 'Please upload a file first');
      return;
    }

    setState(() => _isUploading = true);
    final currentUser = context.read<AuthProvider>().currentUser;
    bool success = await _firestoreService.uploadMaterial(
      userId: widget.userId,
      title: _titleController.text,
      description: _descriptionController.text,
      branch: _selectedBranch!,
      semester: _selectedSemester!,
      section: _selectedSection!,
      fileUrl: _uploadedFile!['url']!,
      fileName: _uploadedFile!['fileName']!,
      uploaderName: currentUser?.name ?? 'Unknown',
    );
    setState(() => _isUploading = false);

    if (success) {
      _showSnackBar('Material uploaded successfully!', isError: false);
      Navigator.pop(context);
    } else {
      _showSnackBar('Failed to save material. Please try again.');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAiDraftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('AI Note Generation Topic *'),
        const SizedBox(height: 8),
        TextField(
          controller: _aiTopicController,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Introduction to Queue and Stack data structures',
            prefixIcon: Icon(Icons.psychology_rounded, color: Color(0xFF6366F1)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingAi ? null : _generateAiNotes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isGeneratingAi
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                : const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 18),
            label: Text(
              _isGeneratingAi ? 'Drafting with AI...' : 'Draft Lecture Notes with AI',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_draftedNotes != null) ...[
          const SizedBox(height: 24),
          _buildLabel('AI Generated Note Preview (Edit if needed)'),
          const SizedBox(height: 8),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              maxLines: null,
              controller: _draftedNotesController,
              onChanged: (val) {
                _draftedNotes = val;
                if (_uploadedFile != null) {
                  _uploadedFile!['url'] = val;
                }
              },
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _generateAiNotes() async {
    if (_aiTopicController.text.trim().isEmpty) {
      _showSnackBar('Please enter a topic for note generation');
      return;
    }
    if (_selectedBranch == null || _selectedSemester == null) {
      _showSnackBar('Please select branch and semester first to tailor the lecture');
      return;
    }

    setState(() => _isGeneratingAi = true);

    try {
      String notes = await _aiService.generateLectureNotes(
        topic: _aiTopicController.text.trim(),
        branch: _selectedBranch!,
        semester: _selectedSemester!,
      );

      setState(() {
        _draftedNotes = notes;
        _draftedNotesController.text = notes;
        _titleController.text = _aiTopicController.text.trim();
        _descriptionController.text = 'AI-generated detailed study guide on ${_aiTopicController.text.trim()}.';
        _uploadedFile = {
          'url': notes,
          'fileName': 'AI_Lecture_Notes_${_titleController.text.trim().replaceAll(' ', '_')}.txt',
        };
      });
      _showSnackBar('AI Draft complete! Review below and tap Submit.', isError: false);
    } catch (e) {
      _showSnackBar('Failed to draft notes: $e');
    } finally {
      setState(() => _isGeneratingAi = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _aiTopicController.dispose();
    _draftedNotesController.dispose();
    super.dispose();
  }
}