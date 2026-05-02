import 'dart:developer';

import 'package:dextera/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:dextera/core/app_theme.dart';
import 'package:dextera/controllers/user_info_controller.dart';
import 'package:dextera/utils/user_store.dart';
import 'package:dextera/utils/snackbar_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dextera/models/auth_models.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _showPasswordFields = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool isEmailLogin = false;
  User? user;
  late final UserInfoController controller;

  @override
  void initState() {
    super.initState();
    user = null;
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Proper GetX initialization
    controller = Get.put(UserInfoController());

    // Load initial username from UserStore
    _getUserInfo();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _getUserInfo() async {
    try {
      final userFetch = await UserStore.getUser();
      if (userFetch != null && userFetch.name != null) {
        user = userFetch;
        _usernameController.text = user!.name!;
        isEmailLogin = user!.mailLoggedIn ?? false;
        setState(() {});
      }
      log(user!.name!);
    } catch (e) {
      log("Error getting user info: $e");
      CustomSnackBar.showError(context, error: 'Failed to get user info');
    }
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark_mode', isDarkMode);
  }

  Future<void> _updateUsername(UserInfoController controller) async {
    final success = await controller.updateUsername(
      _usernameController.text.trim(),
    );
    if (mounted) {
      if (success) {
        CustomSnackBar.show(
          context,
          message: 'Username updated successfully',
          type: SnackBarType.success,
        );
        // Refresh local UI state if needed
        setState(() {});
      } else {
        CustomSnackBar.showError(
          context,
          error: controller.errorMessage.value ?? 'Failed to update username',
        );
      }
    }
  }

  Future<void> _updatePassword(UserInfoController controller) async {
    if (_passwordController.text != _confirmPasswordController.text) {
      CustomSnackBar.showError(context, error: 'Passwords do not match');
      return;
    }

    final success = await controller.updatePassword(
      _passwordController.text.trim(),
    );
    if (mounted) {
      if (success) {
        CustomSnackBar.show(
          context,
          message: 'Password updated successfully',
          type: SnackBarType.success,
        );
        setState(() {
          _showPasswordFields = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        CustomSnackBar.showError(
          context,
          error: controller.errorMessage.value ?? 'Failed to update password',
        );
      }
    }
  }

  Future<void> _deleteAccount(UserInfoController controller) async {
    final success = await controller.deleteAccount();
    if (mounted) {
      if (success) {
        CustomSnackBar.show(
          context,
          message: 'Account deleted successfully',
          type: SnackBarType.success,
        );
        // Navigate to login screen after snackbar is dismissed
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Get.offAllNamed('/login');
          }
        });
      } else {
        CustomSnackBar.showError(
          context,
          error: controller.errorMessage.value ?? 'Failed to delete account',
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeHelper.primaryClr,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Account?',
            style: TextStyle(
              color: ThemeHelper.whiteClr,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This will permanently delete your account and all associated data. This action cannot be undone.',
            style: TextStyle(
              color: ThemeHelper.whiteClr.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: ThemeHelper.lightBlueClr),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount(controller);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeHelper.isDarkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: ThemeHelper.backgroundClr,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Profile Settings',
              style: TextStyle(
                color: ThemeHelper.whiteClr,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            leading: IconButton(
              icon: SvgPicture.asset(
                "assets/icons/drawer.svg",
                // colorFilter: ColorFilter.mode(
                //   // ThemeHelper.whiteClr,
                //   BlendMode.srcIn,
                // ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium Greeting Card
                      _buildGreetingCard(user, isEmailLogin),
                      const SizedBox(height: 32),

                      // Account Settings Section
                      _buildSectionHeader('Account Details'),
                      const SizedBox(height: 16),

                      _buildSettingsCard(
                        child: Column(
                          children: [
                            _buildTextField(
                              label: 'Username',
                              controller: _usernameController,
                              hint: 'Enter your name',
                              icon: Icons.person_outline,
                              errorText: controller.usernameError,
                              onChanged: controller.validateUsername,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: Obx(
                                () => _buildActionButton(
                                  label: 'Update Username',
                                  onPressed: () => _updateUsername(controller)
                                      .then((value) async {
                                        user = await UserStore.getUser();
                                        setState(() {});
                                      }),
                                  isLoading: controller.isUserNameLoading,
                                  color: ThemeHelper.lightBlueClr,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!isEmailLogin) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('Change Password'),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!_showPasswordFields)
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildActionButton(
                                    label: 'Change Password',
                                    onPressed: () => setState(
                                      () => _showPasswordFields = true,
                                    ),
                                    color: ThemeHelper.lightPinkClr,
                                    icon: Icons.lock_outline,
                                  ),
                                )
                              else ...[
                                _buildTextField(
                                  label: 'New Password',
                                  controller: _passwordController,
                                  hint: 'Minimum 6 characters',
                                  icon: Icons.lock_outline,
                                  obscureText: !_showPassword,
                                  toggleObscure: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  onChanged: (v) =>
                                      controller.validatePassword(v),
                                  errorText: controller.passwordError,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Confirm Password',
                                  controller: _confirmPasswordController,
                                  hint: 'Repeat new password',
                                  icon: Icons.lock_reset,
                                  obscureText: !_showConfirmPassword,
                                  toggleObscure: () => setState(
                                    () => _showConfirmPassword =
                                        !_showConfirmPassword,
                                  ),
                                  onChanged: (v) =>
                                      controller.validateConfirmPassword(
                                        _passwordController.text,
                                        v,
                                      ),
                                  errorText: controller.confirmPasswordError,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        label: 'Cancel',
                                        onPressed: () => setState(() {
                                          _showPasswordFields = false;
                                          _passwordController.clear();
                                          _confirmPasswordController.clear();
                                        }),
                                        color: Colors.grey.withOpacity(0.2),
                                        textColor: ThemeHelper.whiteClr,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Obx(
                                        () => _buildActionButton(
                                          label: 'Save',
                                          onPressed: () =>
                                              _updatePassword(controller),
                                          isLoading:
                                              controller.isPasswordLoading,
                                          color: ThemeHelper.lightGreenClr,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      _buildSectionHeader('Appearance'),
                      const SizedBox(height: 16),
                      _buildSettingsCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildThemeOption(
                                    label: 'Light',
                                    icon: Icons.wb_sunny_outlined,
                                    isActive: !isDark,
                                    onTap: () {
                                      ThemeHelper.isDarkModeNotifier.value =
                                          false;
                                      _saveThemePreference(false);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildThemeOption(
                                    label: 'Dark',
                                    icon: Icons.nights_stay_outlined,
                                    isActive: isDark,
                                    onTap: () {
                                      ThemeHelper.isDarkModeNotifier.value =
                                          true;
                                      _saveThemePreference(true);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader('Danger Zone'),
                      const SizedBox(height: 16),
                      _buildSettingsCard(
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Obx(
                                () => _buildActionButton(
                                  label: 'Delete Account',
                                  onPressed: () => _showDeleteConfirmation(),
                                  isLoading: controller.isDeleteLoading,
                                  color: const Color(0xFFEF4444),
                                  icon: Icons.delete_outline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This action cannot be undone. All your data will be permanently deleted.',
                              style: TextStyle(
                                color: ThemeHelper.whiteClr.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreetingCard(User? user, bool isEmailLogin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeHelper.lightBlueClr.withOpacity(0.8),
            ThemeHelper.lightBlueClr.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.lightBlueClr.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEmailLogin ? Icons.mail_outline : Icons.g_mobiledata,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: ThemeHelper.whiteClr.withOpacity(0.5),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        textBaseline: TextBaseline.alphabetic,
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.primaryClr,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeHelper.whiteClr.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    Function(String)? onChanged,
    required Rx<String?> errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ThemeHelper.whiteClr.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            style: TextStyle(color: ThemeHelper.whiteClr),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: ThemeHelper.whiteClr.withOpacity(0.3),
              ),
              prefixIcon: Icon(icon, color: ThemeHelper.lightBlueClr, size: 20),
              suffixIcon: toggleObscure != null
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: ThemeHelper.whiteClr.withOpacity(0.3),
                        size: 20,
                      ),
                      onPressed: toggleObscure,
                    )
                  : null,
              filled: true,
              fillColor: ThemeHelper.backgroundClr.withOpacity(0.5),
              errorText: errorText.value,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeHelper.lightBlueClr.withOpacity(0.5),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    RxBool? isLoading,
    required Color color,
    Color? textColor,
    IconData? icon,
  }) {
    final bool loading = isLoading?.value ?? false;

    return ElevatedButton(
      onPressed: isLoading?.value == true ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor ?? Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading?.value == true
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? ThemeHelper.lightBlueClr
              : ThemeHelper.backgroundClr.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? ThemeHelper.lightBlueClr : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : ThemeHelper.whiteClr.withOpacity(0.3),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : ThemeHelper.whiteClr.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
