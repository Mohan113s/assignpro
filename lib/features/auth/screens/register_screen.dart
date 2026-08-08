import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../models/user_model.dart';

const _kAdminSecurityKey = '707586';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // Step 0: role selection, Step 1: form
  int _step = 0;
  UserRole? _selectedRole;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
      _step = 1;
    });
    _animCtrl.forward(from: 0);
  }

  void _backToRoleSelect() {
    setState(() => _step = 0);
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    if (_step == 0) _buildRoleSelection(),
                    if (_step == 1 && _selectedRole != null)
                      _RegisterForm(
                        role: _selectedRole!,
                        onBack: _backToRoleSelect,
                      ),
                    const SizedBox(height: 24),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.assignment_ind_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _step == 0
              ? 'Select your account type to get started'
              : 'Fill in your details below',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Account Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose the role that best describes you',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                icon: Icons.person_rounded,
                title: 'User',
                subtitle: 'Sales representative with assigned leads',
                color: AppTheme.primaryBlue,
                onTap: () => _selectRole(UserRole.user),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin',
                subtitle: 'Full access: manage users, leads & settings',
                color: const Color(0xFF7C3AED),
                requiresKey: true,
                onTap: () => _selectRole(UserRole.admin),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRouter.login),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Role card ─────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool requiresKey;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.requiresKey = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (requiresKey) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFFD770)),
                          ),
                          child: const Text(
                            'Key Required',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF996600),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: color.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Registration form ─────────────────────────────────────────────────────────
class _RegisterForm extends StatefulWidget {
  final UserRole role;
  final VoidCallback onBack;

  const _RegisterForm({required this.role, required this.onBack});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _secKeyCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _obscureKey = true;
  bool _isLoading = false;

  bool get _isAdmin => widget.role == UserRole.admin;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _secKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();
    final error = await provider.register(
      name: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: widget.role,
      securityKey: _isAdmin ? _secKeyCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
      return;
    }

    final user = provider.currentUser!;
    Navigator.pushReplacementNamed(
      context,
      user.role == UserRole.admin
          ? AppRouter.adminDashboard
          : AppRouter.userDashboard,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _isAdmin ? const Color(0xFF7C3AED) : AppTheme.primaryBlue;
    final roleLabel = _isAdmin ? 'Admin' : 'User';

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$roleLabel Registration',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Fill in your details below',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (v.trim().length < 2) return 'Name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Mobile Number
              TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '10-digit mobile number',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Mobile number is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Enter a valid mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'you@company.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirm Password
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                textInputAction: _isAdmin
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: _isAdmin ? null : (_) => _register(),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              // ── Admin Security Key ──
              if (_isAdmin) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 16,
                        color: Color(0xFF7C3AED),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Admin accounts require a 6-digit Security Key to register',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5B21B6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _secKeyCtrl,
                  obscureText: _obscureKey,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Security Key',
                    hintText: '6-digit key',
                    prefixIcon: const Icon(
                      Icons.vpn_key_rounded,
                      size: 20,
                      color: Color(0xFF7C3AED),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFDDD6FE),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF7C3AED),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (!_isAdmin) return null;
                    if (v == null || v.isEmpty) {
                      return 'Security Key is required for Admin registration';
                    }
                    if (v.trim() != _kAdminSecurityKey) {
                      return 'Invalid Security Key. Access denied.';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roleColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Create ${_isAdmin ? 'Admin' : ''} Account',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
