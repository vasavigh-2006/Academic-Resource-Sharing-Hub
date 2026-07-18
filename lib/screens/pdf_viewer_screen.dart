import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:pdfx/pdfx.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/material_model.dart';
import '../services/firestore_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/ai_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class PDFViewerScreen extends StatefulWidget {
  final MaterialModel material;

  const PDFViewerScreen({Key? key, required this.material}) : super(key: key);

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PdfControllerPinch? _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _hasError = false;
  final FirestoreService _firestoreService = FirestoreService();

  // AI Study Buddy variables
  final AIService _aiService = AIService();
  final List<Map<String, String>> _docuChatHistory = [];
  final TextEditingController _docuChatController = TextEditingController();
  bool _isDocuChatResponding = false;
  String _extractedPdfText = ''; // Extracted full text from PDF

  bool get _isAiNote => widget.material.fileName.startsWith('AI_Lecture_Notes_');

  @override
  void initState() {
    super.initState();
    _firestoreService.incrementDownloadCount(widget.material.id);
    if (_isAiNote) {
      _isLoading = false;
    } else {
      _initializePDF();
    }
  }

  void _initializePDF() async {
    try {
      final response = await http.get(Uri.parse(widget.material.fileUrl));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.material.id}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        _pdfController = PdfControllerPinch(
          initialPage: 1,
          document: PdfDocument.openFile(file.path),
        );

        final document = await PdfDocument.openFile(file.path);

        // Extract text from PDF for AI context
        try {
          final sfDoc = sf.PdfDocument(inputBytes: response.bodyBytes);
          final extractor = sf.PdfTextExtractor(sfDoc);
          _extractedPdfText = extractor.extractText().trim();
          sfDoc.dispose();
          print('PDF text extracted: ${_extractedPdfText.length} characters');
        } catch (textErr) {
          print('Text extraction failed (scanned PDF?): $textErr');
          _extractedPdfText = '';
        }

        if (mounted) {
          setState(() {
            _totalPages = document.pagesCount;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.material.title,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.material.fileName,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6366F1)),
                  const SizedBox(height: 16),
                  Text('Loading PDF...', style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 56),
                      const SizedBox(height: 16),
                      Text('Failed to load PDF', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Please check your connection and try again.', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                )
              : _isAiNote
                  ? _buildAiNoteView()
                  : Stack(
                      children: [
                        PdfViewPinch(
                          controller: _pdfController!,
                          onDocumentLoaded: (document) {
                            setState(() => _totalPages = document.pagesCount);
                          },
                          onPageChanged: (page) {
                            setState(() => _currentPage = page);
                          },
                        ),

                        // Glassmorphism floating pagination pill
                        Positioned(
                          bottom: 28,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                                        onPressed: _currentPage > 1
                                            ? () => _pdfController!.previousPage(
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                )
                                            : null,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$_currentPage / $_totalPages',
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                                        onPressed: _currentPage < _totalPages
                                            ? () => _pdfController!.nextPage(
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                )
                                            : null,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF6366F1),
          onPressed: _openDocuChat,
          icon: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
          label: Text(
            'DOCUCHAT AI',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _docuChatController.dispose();
    super.dispose();
  }

  Widget _buildAiNoteView() {
    final text = widget.material.fileUrl;
    final lines = text.split('\n');
    
    return Container(
      color: const Color(0xFF020617),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map<Widget>((line) => _renderMarkdownLine(line)).toList(),
        ),
      ),
    );
  }

  Widget _renderMarkdownLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return const SizedBox(height: 8);

    // Headers
    if (trimmed.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          trimmed.substring(2),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.6,
          ),
        ),
      );
    }
    if (trimmed.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 6),
        child: Text(
          trimmed.substring(3),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF8B5CF6),
            letterSpacing: -0.4,
          ),
        ),
      );
    }
    if (trimmed.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          trimmed.substring(4),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF38BDF8),
          ),
        ),
      );
    }

    // List items
    if (trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7, right: 10),
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                trimmed.substring(2),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (trimmed.startsWith('```')) {
      return const SizedBox(height: 4);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        line,
        style: GoogleFonts.inter(
          fontSize: 14.5,
          height: 1.6,
          color: const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  void _openDocuChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F19).withOpacity(0.92),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                            ),
                            child: const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DocuChat AI',
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              Text(
                                'Your interactive study buddy',
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
                    ),
                    const Divider(color: Colors.white10),
                    Expanded(
                      child: _docuChatHistory.isEmpty
                          ? _buildEmptyChatState(setModalState)
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _docuChatHistory.length,
                              itemBuilder: (context, index) {
                                final msg = _docuChatHistory[index];
                                final isMe = msg['sender'] == 'me';
                                return _buildChatBubble(msg['text'] ?? '', isMe);
                              },
                            ),
                    ),
                    if (_isDocuChatResponding)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                            ),
                            const SizedBox(width: 8),
                            Text('AI is thinking...', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                    if (_docuChatHistory.isEmpty)
                      Container(
                        height: 40,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildSuggestPill('Summarize this', setModalState),
                            _buildSuggestPill('Quiz me', setModalState),
                            _buildSuggestPill('Key terms', setModalState),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _docuChatController,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Ask your study buddy...',
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                                fillColor: Colors.white.withOpacity(0.04),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _sendDocuChatQuery(setModalState),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFF6366F1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildEmptyChatState(StateSetter setModalState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined, color: Color(0xFF6366F1), size: 48),
            const SizedBox(height: 12),
            Text(
              'Ask anything about this document!',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Get direct summaries, quick quizzes, or detailed explanations instantly from our AI.',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestPill(String label, StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: const Color(0xFF1E293B),
        label: Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.06))),
        onPressed: () {
          _docuChatController.text = label;
          _sendDocuChatQuery(setModalState);
        },
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, height: 1.4),
        ),
      ),
    );
  }

  void _sendDocuChatQuery(StateSetter setModalState) async {
    final query = _docuChatController.text.trim();
    if (query.isEmpty) return;

    _docuChatController.clear();
    setModalState(() {
      _docuChatHistory.add({'sender': 'me', 'text': query});
      _isDocuChatResponding = true;
    });

    try {
      // Build context: use extracted PDF text if available, else fallback to description
      String context;
      if (_isAiNote) {
        context = 'Full Document Text Content:\n\n${widget.material.fileUrl}';
      } else if (_extractedPdfText.isNotEmpty) {
        // Limit to first 6000 chars to stay within token limits
        final truncated = _extractedPdfText.length > 6000
            ? '${_extractedPdfText.substring(0, 6000)}\n\n[Document continues...]'
            : _extractedPdfText;
        context = 'Full PDF Content:\n\n$truncated';
      } else {
        context = widget.material.description.isNotEmpty
            ? widget.material.description
            : 'No description available. Please answer based on the document title.';
      }

      String response = await _aiService.askStudyBuddy(
        materialTitle: widget.material.title,
        materialDescription: context,
        userQuestion: query,
        chatHistory: _docuChatHistory,
      );

      setModalState(() {
        _docuChatHistory.add({'sender': 'ai', 'text': response});
      });
    } catch (e) {
      setModalState(() {
        _docuChatHistory.add({'sender': 'ai', 'text': 'Sorry, I encountered an issue. Please try again.'});
      });
    } finally {
      setModalState(() {
        _isDocuChatResponding = false;
      });
    }
  }



}