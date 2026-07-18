import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_background.dart';
import 'upload_material_screen.dart';
import 'view_materials_screen.dart';
import 'messaging_screen.dart';
import 'group_chat_screen.dart';
import 'my_materials_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isFaculty = widget.user.role == 'faculty';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Academic Hub',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8)),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PremiumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              _buildWelcomeBanner(isFaculty),
              const SizedBox(height: 28),

              Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Dashboard Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  if (isFaculty)
                    _buildDashboardCard(
                      context,
                      title: 'Upload Material',
                      subtitle: 'Share notes & files',
                      icon: Icons.cloud_upload_rounded,
                      iconColor: const Color(0xFF6366F1),
                      onTap: () => Navigator.push(context, PremiumPageRoute(
                        page: UploadMaterialScreen(userId: widget.user.uid),
                      )),
                    ),
                  if (isFaculty)
                    _buildDashboardCard(
                      context,
                      title: 'My Materials',
                      subtitle: 'Manage uploads',
                      icon: Icons.library_books_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(context, PremiumPageRoute(
                        page: MyMaterialsScreen(userId: widget.user.uid),
                      )),
                    ),
                  _buildDashboardCard(
                    context,
                    title: 'View Materials',
                    subtitle: 'Browse resources',
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF0D9488),
                    onTap: () => Navigator.push(context, PremiumPageRoute(
                      page: ViewMaterialsScreen(user: widget.user),
                    )),
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Messages',
                    subtitle: 'Chat with peers',
                    icon: Icons.chat_bubble_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(context, PremiumPageRoute(
                      page: MessagingScreen(user: widget.user),
                    )),
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Group Study',
                    subtitle: 'Collaborate & learn',
                    icon: Icons.groups_rounded,
                    iconColor: const Color(0xFFE11D48),
                    onTap: () => Navigator.push(context, PremiumPageRoute(
                      page: GroupChatScreen(user: widget.user),
                    )),
                  ),
                  _buildAiPromoCard(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(bool isFaculty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0xDD090D1A), BlendMode.multiply),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.22), blurRadius: 28, offset: const Offset(0, 8)),
          BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.10), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 0)),
        ],
      ),
      child: Row(
        children: [
          // Avatar with glowing ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.5), blurRadius: 14, spreadRadius: 1),
              ],
            ),
            child: CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xFF0F172A),
              child: Text(
                widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${widget.user.name.split(' ').first}!',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Glassmorphic role chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35), width: 1),
                      ),
                      child: Text(
                        isFaculty ? 'FACULTY' : 'STUDENT',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA5B4FC),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.user.branch,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFCBD5E1),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isFaculty
                      ? 'Sem ${widget.user.semester} • Sec ${widget.user.section}'
                      : 'Semester ${widget.user.semester} • Section ${widget.user.section}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return PressScaleWidget(
      onTap: onTap,
      child: GlassCard(
        glowColor: iconColor,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: null,
            borderRadius: BorderRadius.circular(16),
            splashColor: iconColor.withOpacity(0.14),
            highlightColor: iconColor.withOpacity(0.07),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Glowing icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: iconColor.withOpacity(0.28), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.35),
                          blurRadius: 14,
                          spreadRadius: 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFCBD5E1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiPromoCard(BuildContext context) {
    const aiColor = Color(0xFF6366F1);
    return PressScaleWidget(
      onTap: () => _showAiFeaturesDialog(context),
      child: GlassCard(
        glowColor: aiColor,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: null,
            borderRadius: BorderRadius.circular(16),
            splashColor: aiColor.withOpacity(0.14),
            highlightColor: aiColor.withOpacity(0.07),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: aiColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: aiColor.withOpacity(0.28), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: aiColor.withOpacity(0.35),
                              blurRadius: 14,
                              spreadRadius: 0,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: aiColor, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: aiColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: aiColor.withOpacity(0.35), width: 1),
                        ),
                        child: Text(
                          'AI ACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFA5B4FC),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Academic AI Suite',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap to explore features',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFCBD5E1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAiFeaturesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A).withOpacity(0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.25), width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 24),
              const SizedBox(width: 10),
              Text(
                'Academic AI Suite',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This application is powered by advanced AI, delivering zero-latency academic intelligence.',
                style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),
              _buildDialogFeatureRow(
                Icons.psychology_rounded,
                'DocuChat Study Buddy',
                'Ask questions, summarize, or generate instant quizzes directly inside any study document.',
              ),
              const SizedBox(height: 14),
              _buildDialogFeatureRow(
                Icons.auto_awesome,
                'AI Chat Summarizer',
                'Generate professional highlights and actionable study plans from active group channels.',
              ),
              const SizedBox(height: 14),
              _buildDialogFeatureRow(
                Icons.menu_book_rounded,
                'AI Lecture Drafts',
                'Allows faculty to draft structured Markdown guides and revision sets in seconds.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Awesome',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogFeatureRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11.5, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleLogout(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.inter(color: const Color(0xFFCBD5E1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog first
              await parentContext.read<AuthProvider>().signOut();
              if (parentContext.mounted) {
                // Clear the ENTIRE navigation stack and go to AuthWrapper
                Navigator.of(parentContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Logout', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}