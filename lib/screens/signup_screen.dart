import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_background.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  String? _selectedRole;
  String? _selectedBranch;
  String? _selectedSemester;
  String? _selectedSection;
  final List<String> _selectedSemestersList = [];
  final List<String> _selectedSectionsList = [];

  final List<String> _roles = ['Faculty', 'Student'];
  final List<String> _branches = ['CS', 'IT', 'EC', 'ME', 'AIML', 'AIDS'];
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> _sections = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Premium Hero Header with Image
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 70, 24, 36),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=2070&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Color(0xDD090D1A), BlendMode.multiply),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        Text(
                          'Join your academic workspace',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
  
              // Form Section in Glassmorphism Card
              Padding(
                padding: const EdgeInsets.all(20),
                child: GlassCard(
                  glowColor: const Color(0xFF6366F1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildLabel('Full Name'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Email Address'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Create a password',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Role'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        dropdownColor: const Color(0xFF0F172A),
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Select your role',
                          prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF64748B)),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem(value: role, child: Text(role, style: GoogleFonts.inter(color: Colors.white)));
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedRole = value),
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Branch / Department'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedBranch,
                        dropdownColor: const Color(0xFF0F172A),
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Select your branch',
                          prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF64748B)),
                        ),
                        items: _branches.map((branch) {
                          return DropdownMenuItem(value: branch, child: Text(branch, style: GoogleFonts.inter(color: Colors.white)));
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedBranch = value),
                      ),
  
                      // Student fields
                      if (_selectedRole == 'Student') ...[
                        const SizedBox(height: 18),
                        _buildLabel('Semester'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedSemester,
                          dropdownColor: const Color(0xFF0F172A),
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Select semester',
                            prefixIcon: Icon(Icons.calendar_today_outlined, color: Color(0xFF64748B)),
                          ),
                          items: _semesters.map((sem) {
                            return DropdownMenuItem(value: sem, child: Text('Semester $sem', style: GoogleFonts.inter(color: Colors.white)));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedSemester = value),
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Section'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedSection,
                          dropdownColor: const Color(0xFF0F172A),
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Select section',
                            prefixIcon: Icon(Icons.group_outlined, color: Color(0xFF64748B)),
                          ),
                          items: _sections.map((section) {
                            return DropdownMenuItem(value: section, child: Text('Section $section', style: GoogleFonts.inter(color: Colors.white)));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedSection = value),
                        ),
                      ],
  
                      // Faculty fields
                      if (_selectedRole == 'Faculty') ...[
                        const SizedBox(height: 24),
                        _buildLabel('Semesters You Teach'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _semesters.map((sem) {
                            final isSelected = _selectedSemestersList.contains(sem);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) _selectedSemestersList.remove(sem);
                                  else _selectedSemestersList.add(sem);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F172A).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.08),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  'Sem $sem',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Sections You Teach'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sections.map((sec) {
                            final isSelected = _selectedSectionsList.contains(sec);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) _selectedSectionsList.remove(sec);
                                  else _selectedSectionsList.add(sec);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF0F172A).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF0D9488) : Colors.white.withOpacity(0.08),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  'Sec $sec',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
  
                      const SizedBox(height: 36),
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            return ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _handleSignUp(context, authProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Already have an account? Sign In',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6366F1),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFE2E8F0),
      ),
    );
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter (A-Z)';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number (0-9)';
    }
    if (!password.contains(RegExp(r'[^a-zA-Z0-9]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  void _handleSignUp(BuildContext context, AuthProvider authProvider) async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _selectedRole == null ||
        _selectedBranch == null) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      _showSnackBar(passwordError);
      return;
    }

    if (_selectedRole == 'Student' && (_selectedSemester == null || _selectedSection == null)) {
      _showSnackBar('Students must select Semester and Section');
      return;
    }

    if (_selectedRole == 'Faculty' && (_selectedSemestersList.isEmpty || _selectedSectionsList.isEmpty)) {
      _showSnackBar('Faculty must select at least one Semester and Section');
      return;
    }

    bool success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text,
      role: _selectedRole!.toLowerCase(),
      branch: _selectedBranch!,
      semester: _selectedRole == 'Faculty' ? _selectedSemestersList.join(', ') : _selectedSemester!,
      section: _selectedRole == 'Faculty' ? _selectedSectionsList.join(', ') : _selectedSection!,
    );

    if (success) {
      if (mounted) {
        _showSnackBar('Account created successfully!', isError: false);
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        final error = authProvider.errorMessage ?? 'Sign up failed. Please try again';
        _showSnackBar(error);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
