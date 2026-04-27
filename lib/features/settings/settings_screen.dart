// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070718),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1040),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings',
            style: GoogleFonts.fredoka(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text('Profile not found',
                  style: GoogleFonts.nunito(color: Colors.white)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account section
                Text('Account',
                    style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _SettingSection(
                  children: [
                    _SettingItem(
                      icon: Icons.person_outline,
                      title: 'Profile Information',
                      subtitle: 'View and edit your profile details',
                      onTap: () => context.push('/profile'),
                    ),
                    _SettingItem(
                      icon: Icons.refresh,
                      title: 'Refresh Profile Data',
                      subtitle: 'Reload all profile information',
                      onTap: () {
                        ref.refresh(currentProfileProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Profile data refreshed!',
                              style: GoogleFonts.nunito(color: Colors.white),
                            ),
                            backgroundColor: Colors.green.withOpacity(0.7),
                            duration: const Duration(milliseconds: 1500),
                          ),
                        );
                      },
                    ),
                    _SettingItem(
                      icon: Icons.security_outlined,
                      title: 'Privacy & Security',
                      subtitle: 'Manage your privacy settings',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Game settings section
                Text('Game Settings',
                    style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _SettingSection(
                  children: [
                    _ToggleSettingItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Game invites and results',
                      initialValue: true,
                      onChanged: (value) {},
                    ),
                    _ToggleSettingItem(
                      icon: Icons.volume_up_outlined,
                      title: 'Sound Effects',
                      subtitle: 'Enable sound during gameplay',
                      initialValue: true,
                      onChanged: (value) {},
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Display section
                Text('Display',
                    style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _SettingSection(
                  children: [
                    _SettingItem(
                      icon: Icons.brightness_4_outlined,
                      title: 'Theme',
                      subtitle: 'Dark (current)',
                      onTap: () {},
                    ),
                    _SettingItem(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Support & Legal section
                Text('Support & Legal',
                    style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _SettingSection(
                  children: [
                    _SettingItem(
                      icon: Icons.help_outline,
                      title: 'About QuizBlitz',
                      subtitle: 'App version 1.0.0',
                      onTap: () {},
                    ),
                    _SettingItem(
                      icon: Icons.info_outline,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy terms',
                      onTap: () {},
                    ),
                    _SettingItem(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: 'Read our terms',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Sign out
                if (!profile.isGuest)
                  _SettingSection(
                    children: [
                      _SettingItem(
                        icon: Icons.logout,
                        title: 'Sign Out',
                        subtitle: 'Log out of your account',
                        onTap: () => _showSignOutDialog(context, ref),
                        isDestructive: true,
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border:
                          Border.all(color: Colors.orange.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Guest Session',
                            style: GoogleFonts.fredoka(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'You are playing as a guest. Sign up to save your progress and access more features!',
                          style: GoogleFonts.nunito(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        content: Text('You will be logged out of your account.',
            style: GoogleFonts.nunito(color: Colors.white54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.nunito(color: Colors.white38))),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              child: Text('Sign Out',
                  style: GoogleFonts.nunito(color: Colors.redAccent))),
        ],
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final List<Widget> children;

  const _SettingSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: List.generate(
          children.length,
          (index) => Column(
            children: [
              children[index],
              if (index < children.length - 1)
                Divider(
                  color: Colors.white.withOpacity(0.1),
                  height: 0,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.white70,
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.white38,
      ),
      onTap: onTap,
    );
  }
}

class _ToggleSettingItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const _ToggleSettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_ToggleSettingItem> createState() => _ToggleSettingItemState();
}

class _ToggleSettingItemState extends State<_ToggleSettingItem> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Icon(
        widget.icon,
        color: Colors.white70,
        size: 24,
      ),
      title: Text(
        widget.title,
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        widget.subtitle,
        style: GoogleFonts.nunito(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: _value,
        onChanged: (value) {
          setState(() => _value = value);
          widget.onChanged(value);
        },
        activeColor: const Color(0xFF7C73FF),
      ),
    );
  }
}
