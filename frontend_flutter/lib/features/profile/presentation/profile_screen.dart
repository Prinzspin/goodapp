import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';
import 'package:frontend_flutter/features/profile/data/profile_repository.dart';
import 'package:frontend_flutter/core/network/pb_client.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
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
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header avec Dégradé et Avatar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.deepPurple,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.deepPurple, Color(0xFF673AB7)],
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
                          ? const Icon(Icons.person, size: 50, color: Colors.deepPurple)
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
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => ref.read(profileRepositoryProvider).logout(),
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
                        _buildStatCard("Rejoints", stats["joined"].toString(), Icons.event_available),
                        const SizedBox(width: 16),
                        _buildStatCard("Créés", stats["hosted"].toString(), Icons.rocket_launch),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 24),

                  // Informations de Contact
                  _buildSectionHeader("Informations Personnelles"),
                  const SizedBox(height: 12),
                  _buildProfileCard([
                    _buildInfoRow(Icons.account_circle_outlined, "Nom/Pseudo", user.getStringValue('name')),
                    const Divider(),
                    _buildInfoRow(Icons.email_outlined, "Email", user.getStringValue('email')),
                    const Divider(),
                    _buildInfoRow(Icons.calendar_month_outlined, "Inscription", memberSince),
                  ]),

                  if (user.getStringValue('bio').isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader("Biographie"),
                    const SizedBox(height: 12),
                    _buildProfileCard([
                      Text(user.getStringValue('bio'), style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                    ]),
                  ],

                  const SizedBox(height: 24),

                  // My Events
                  _buildSectionHeader("Mes Événements"),
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

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple.shade300),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value.isNotEmpty ? value : "N/A", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildMiniEventCard(BuildContext context, dynamic event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.event, color: Colors.deepPurple),
        title: Text(event.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('dd MMM yyyy').format(event.startDate), style: const TextStyle(fontSize: 12)),
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
            const Text('Modifier mon profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _bioController, decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder())),
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
