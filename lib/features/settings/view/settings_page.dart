import 'package:expence_flow_pro/features/settings/controller/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/widgets/app_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Settings', size: 18, weight: FontWeight.w600),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _profileCard(),
          const SizedBox(height: 24),
          _sectionLabel('Preferences'),
          _currencyTile(),
          const SizedBox(height: 24),
          _sectionLabel('Account'),
          _logoutTile(context),
        ],
      ),
    );
  }

  // ─── Profile ───────────────────────────────────────────────────────────────

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withAlpha(51),
            child: AppText(
              StorageService.userName.isNotEmpty
                  ? StorageService.userName[0].toUpperCase()
                  : '?',
              size: 22,
              weight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  StorageService.userName,
                  size: 16,
                  weight: FontWeight.w600,
                ),
                AppText(
                  StorageService.userEmail,
                  size: 13,
                  color: AppColors.grey,
                  top: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Currency ──────────────────────────────────────────────────────────────

  Widget _currencyTile() {
    final currencies = ['USD', 'EUR', 'GBP', 'BDT', 'INR', 'JPY'];

    return GetBuilder<SettingsController>(
      init: SettingsController(),
      builder: (controller) {
        return _SettingsTile(
          icon: Icons.attach_money,
          label: 'Currency',
          trailing: DropdownButton<String>(
            value: controller.currency,
            dropdownColor: AppColors.surfaceLight,
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: AppColors.white, fontSize: 13),
            items: currencies
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.setCurrency(value);
            },
          ),
        );
      },
    );
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  Widget _logoutTile(BuildContext context) {
    return _SettingsTile(
      icon: Icons.logout,
      label: 'Log Out',
      iconColor: AppColors.red,
      labelColor: AppColors.red,
      onTap: () => _confirmLogout(context),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const AppText('Log Out', size: 16, weight: FontWeight.w600),
        content: const AppText(
          'Are you sure you want to log out?',
          size: 14,
          color: AppColors.grey,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const AppText('Cancel', color: AppColors.grey),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<AuthController>().signOut();
            },
            child: const AppText('Log Out', color: AppColors.red),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppText(label, size: 13, color: AppColors.grey),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.iconColor,
    this.labelColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.grey, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: AppText(
                label,
                size: 14,
                color: labelColor ?? AppColors.white,
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

