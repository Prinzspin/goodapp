import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';
import 'package:frontend_flutter/features/profile/data/profile_repository.dart';
import 'package:frontend_flutter/core/network/pb_client.dart';
import 'package:frontend_flutter/shared/providers/accessibility_provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider);
    _nameController = TextEditingController(text: user?.getStringValue('name') ?? '');
    _bioController = TextEditingController(text: user?.getStringValue('bio') ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final statsAsync = ref.watch(profileStatsProvider);
    final myEventsAsync = ref.watch(myEventsProvider);
    final pb = ref.watch(pocketBaseProvider);

    final avatarUrl = user.getStringValue('avatar').isNotEmpty
        ? pb.getFileUrl(user, user.getStringValue('avatar')).toString()
        : null;

    String memberSince;
    try {
      memberSince = DateFormat('MMMM yyyy').format(DateTime.parse(user.created));
    } catch (_) {
      memberSince = 'Récemment';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header avec Dégradé et Avatar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      Color.lerp(theme.colorScheme.primary, Colors.black, 0.1) ?? theme.colorScheme.primary,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null 
                          ? Icon(Icons.person, size: 50, color: theme.colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.getStringValue('name').isNotEmpty ? user.getStringValue('name') : 'User',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Membre depuis $memberSince',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Semantics(
                button: true,
                label: 'Réglages accessibilité',
                child: IconButton(
                  icon: const Icon(Icons.accessibility_new, color: Colors.white),
                  tooltip: 'Réglages accessibilité',
                  onPressed: () => _showAccessibilitySettings(context),
                ),
              ),
              Semantics(
                button: true,
                label: 'Se déconnecter',
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Se déconnecter',
                  onPressed: () => ref.read(profileRepositoryProvider).logout(),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Section Stats
                  statsAsync.when(
                    data: (stats) => Row(
                      children: [
                        _buildStatCard(context, "Rejoints", stats["joined"].toString(), Icons.event_available),
                        const SizedBox(width: 16),
                        _buildStatCard(context, "Créés", stats["hosted"].toString(), Icons.rocket_launch),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 24),

                  // Informations de Contact
                  _buildSectionHeader(context, "Informations Personnelles"),
                  const SizedBox(height: 12),
                  _buildProfileCard(context, [
                    _buildInfoRow(context, Icons.account_circle_outlined, "Nom/Pseudo", user.getStringValue('name')),
                    const Divider(),
                    _buildInfoRow(context, Icons.email_outlined, "Email", user.getStringValue('email')),
                    const Divider(),
                    _buildInfoRow(context, Icons.calendar_month_outlined, "Inscription", memberSince),
                  ]),

                  if (user.getStringValue('bio').isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, "Biographie"),
                    const SizedBox(height: 12),
                    _buildProfileCard(context, [
                      Text(user.getStringValue('bio'), style: theme.textTheme.bodyMedium),
                    ]),
                  ],

                  const SizedBox(height: 24),

                  // My Events
                  _buildSectionHeader(context, "Mes Événements"),
                  const SizedBox(height: 12),
                  myEventsAsync.when(
                    data: (events) => events.isEmpty 
                      ? const Text('Aucun événement créé.', style: TextStyle(color: Colors.grey))
                      : Column(
                          children: events.map((e) => _buildMiniEventCard(context, e)).toList(),
                        ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 40),

                  // Bouton Modifier
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditDialog(context),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier le profil'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccessibilitySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AccessibilitySettingsSheet(),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.titleLarge),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
              Text(value.isNotEmpty ? value : "N/A", style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.blueGrey,
            letterSpacing: 1.2,
            fontSize: 12,
          )),
        ],
      ),
    );
  }

  Widget _buildMiniEventCard(BuildContext context, dynamic event) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.event, color: theme.colorScheme.primary),
        title: Text(event.title, style: theme.textTheme.titleSmall),
        subtitle: Text(DateFormat('dd MMM yyyy').format(event.startDate), style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => context.push('/event/${event.id}'),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 30, right: 30, top: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Modifier mon profil', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom')),
            const SizedBox(height: 16),
            TextField(controller: _bioController, decoration: const InputDecoration(labelText: 'Bio')),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await ref.read(profileRepositoryProvider).updateProfile(name: _nameController.text, bio: _bioController.text);
                if (mounted) context.pop();
              },
              child: const Text('Enregistrer'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _AccessibilitySettingsSheet extends ConsumerWidget {
  const _AccessibilitySettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final highContrast = ref.watch(highContrastProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.accessibility_new, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Réglages accessibilité',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(24),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(Icons.contrast, color: theme.colorScheme.primary),
                    title: Text('Contraste élevé', style: theme.textTheme.titleMedium),
                    subtitle: Text(
                      'Renforce les couleurs pour une meilleure lisibilité',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: highContrast,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (v) => ref.read(highContrastProvider.notifier).state = v,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lecteur d\'écran', style: theme.textTheme.titleSmall),
                              const SizedBox(height: 4),
                              Text(
                                'L\'application est optimisée pour TalkBack (Android) et VoiceOver (iOS).',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
