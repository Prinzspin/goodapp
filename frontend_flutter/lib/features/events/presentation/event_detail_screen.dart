import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/events/data/events_repository.dart';
import 'package:frontend_flutter/features/events/data/event_model.dart';
import 'package:frontend_flutter/core/network/pb_client.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';
import 'package:frontend_flutter/features/chat/data/chat_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {

  void _refreshAll() {
    ref.invalidate(pendingMembersProvider(widget.eventId));
    ref.invalidate(acceptedMembersProvider(widget.eventId));
    ref.invalidate(eventDetailProvider(widget.eventId));
    ref.invalidate(eventMembershipProvider(widget.eventId));
    ref.invalidate(eventsListProvider);
    ref.invalidate(conversationsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final membershipAsync = ref.watch(eventMembershipProvider(widget.eventId));
    final currentUser = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail Événement')),
      body: eventAsync.when(
        data: (event) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (event.photos.isNotEmpty)
                _buildPhotoGallery(event)
              else
                Container(
                  height: 150,
                  color: Colors.grey.shade100,
                  child: const Center(child: Icon(Icons.photo_outlined, size: 48, color: Colors.grey)),
                ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              event.title, 
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildStatusBadge(context, event),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildIconInfo(context, Icons.access_time_outlined, DateFormat('EEEE d MMMM, HH:mm').format(event.startDate)),
                    if (event.locationName != null) _buildIconInfo(context, Icons.place_outlined, event.locationName!),
                    const Divider(height: 32),
                    
                    Semantics(
                      header: true,
                      child: Text('Description', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.description.isNotEmpty ? event.description : "Pas de description.",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),

                    // Section Membership & Action
                    _buildMembershipSection(event, membershipAsync),

                    // Section Gestion Demandes (visible UNIQUEMENT par le créateur)
                    if (currentUser != null && event.creatorId == currentUser.id) ...[
                      const SizedBox(height: 32),
                      _buildPendingRequestsSection(event),
                      const SizedBox(height: 24),
                      _buildAcceptedMembersSection(event),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  // === PHOTOS ===
  Widget _buildPhotoGallery(EventModel event) {
    final pb = ref.read(pocketBaseProvider);
    final baseUrl = pb.baseUrl;
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: event.photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final imageUrl = "$baseUrl/api/files/events/${event.id}/${event.photos[index]}";
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl, height: 250, width: 300, fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey.shade200),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          );
        },
      ),
    );
  }

  // === MEMBERSHIP SECTION ===
  Widget _buildMembershipSection(EventModel event, AsyncValue<EventMemberModel?> membershipAsync) {
    return membershipAsync.when(
      data: (membership) {
        final isOwner = membership?.role == 'owner';
        final isAccepted = membership?.status == 'accepted';

        if (isOwner || isAccepted) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(isOwner ? 'Vous êtes l\'organisateur' : 'Vous participez à cet événement',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'Accéder à la discussion de l\'événement',
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/chat/${event.id}'),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Accéder à la discussion'),
                ),
              ),
            ],
          );
        }

        if (membership?.status == 'pending') {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(children: [
              Icon(Icons.hourglass_empty, color: Color(0xFFD97706)),
              SizedBox(width: 12),
              Expanded(
                child: Text('Demande envoyée (En attente de validation)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
              ),
            ]),
          );
        }

        if (membership?.status == 'rejected') {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Row(children: [
              Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
              SizedBox(width: 12),
              Expanded(
                child: Text('Votre demande a été refusée', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF991B1B))),
              ),
            ]),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!event.isPublic)
              Semantics(
                label: 'Information : Événement privé',
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [
                    Icon(Icons.privacy_tip_outlined, color: Color(0xFF64748B)),
                    SizedBox(width: 12),
                    Expanded(child: Text('Événement privé. Accès à la discussion après validation.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF475569)))),
                  ]),
                ),
              ),
            Semantics(
              button: true,
              label: event.isPublic ? 'Rejoindre l\'événement' : 'Envoyer une demande pour rejoindre',
              child: ElevatedButton(
                onPressed: () => _joinEvent(event),
                child: Text(event.isPublic ? 'Rejoindre l\'événement' : 'Demander à rejoindre'),
              ),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => const Text('Statut indisponible'),
    );
  }

  // === JOIN ACTION ===
  Future<void> _joinEvent(EventModel event) async {
    try {
      await ref.read(eventsRepositoryProvider).joinEvent(event.id, event.isPublic);
      _refreshAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event.isPublic ? "Vous avez rejoint l'événement !" : "Demande envoyée !")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // === DEMANDES PENDING ===
  Widget _buildPendingRequestsSection(EventModel event) {
    final pendingAsync = ref.watch(pendingMembersProvider(event.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text('Demandes en attente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (pendingAsync.isLoading && !pendingAsync.hasValue)
          const LinearProgressIndicator()
        else if (pendingAsync.valueOrNull?.isEmpty ?? true)
          const Text('Aucune demande en attente.', style: TextStyle(color: Colors.grey))
        else
          Column(
            children: pendingAsync.value!.map((member) => _buildPendingTile(event, member)).toList(),
          ),
      ],
    );
  }

  Future<void> _acceptMember(EventMemberModel member) async {
    // 1. MUTATION OPTIMISTE DU CACHE RIVERPOD
    final pendingList = ref.read(pendingMembersProvider(widget.eventId)).valueOrNull;
    final acceptedList = ref.read(acceptedMembersProvider(widget.eventId)).valueOrNull;

    setState(() {
      pendingList?.removeWhere((m) => m.id == member.id);
      
      if (acceptedList != null && !acceptedList.any((m) => m.id == member.id)) {
        acceptedList.add(EventMemberModel(
          id: member.id, eventId: member.eventId, userId: member.userId,
          status: 'accepted', role: member.role, userName: member.userName,
        ));
      }
    });

    // 2. BACKEND APPEL
    try {
      await ref.read(eventsRepositoryProvider).acceptMember(member.id);
      _refreshAll(); // Resync stat counters in background
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membre accepté !')));
    } catch (e) {
      // Pas de rollback si c'est un hook post-commit, on rafraîchit la vérité PocketBase
      _refreshAll();
    }
  }

  Future<void> _rejectMember(EventMemberModel member) async {
    final pendingList = ref.read(pendingMembersProvider(widget.eventId)).valueOrNull;
    
    setState(() {
      pendingList?.removeWhere((m) => m.id == member.id);
    });

    try {
      await ref.read(eventsRepositoryProvider).rejectMember(member.id);
      _refreshAll(); // Resync
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande refusée.')));
    } catch (e) {
      _refreshAll();
    }
  }

  Widget _buildPendingTile(EventModel event, EventMemberModel member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(member.userName ?? member.userId,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Accepter',
              onPressed: () => _acceptMember(member),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Refuser',
              onPressed: () => _rejectMember(member),
            ),
          ],
        ),
      ),
    );
  }

  // === MEMBRES ACCEPTÉS ===
  Widget _buildAcceptedMembersSection(EventModel event) {
    final acceptedAsync = ref.watch(acceptedMembersProvider(event.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text('Participants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (acceptedAsync.isLoading && !acceptedAsync.hasValue)
          const LinearProgressIndicator()
        else if (acceptedAsync.valueOrNull?.isEmpty ?? true)
          const Text('Aucun participant pour le moment.', style: TextStyle(color: Colors.grey))
        else
          Column(
            children: acceptedAsync.value!.map((member) => _buildMemberTile(member)).toList(),
          ),
      ],
    );
  }

  Widget _buildMemberTile(EventMemberModel member) {
    final isOwner = member.role == 'owner';
    return Semantics(
      label: 'Participant: ${member.userName ?? member.userId}${isOwner ? ", organisateur" : ""}',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: isOwner ? const Color(0xFFEEEAFF) : const Color(0xFFDCFCE7),
          child: Icon(isOwner ? Icons.star : Icons.person,
              color: isOwner ? const Color(0xFF4F46E5) : const Color(0xFF16A34A)),
        ),
        title: Text(member.userName ?? member.userId,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        trailing: isOwner
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Organisateur',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  // === HELPERS ===
  Widget _buildIconInfo(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text, 
              style: const TextStyle(color: Color(0xFF475569), fontSize: 15, fontWeight: FontWeight.w500),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, EventModel event) {
    // Green pour public, Indigo pour privé (mieux que amber!)
    final bgColor = event.isPublic ? const Color(0xFFDCFCE7) : const Color(0xFFE0E7FF);
    final txtColor = event.isPublic ? const Color(0xFF16A34A) : const Color(0xFF4F46E5);
    
    return Semantics(
      label: event.isPublic ? 'Événement public' : 'Événement privé',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          event.isPublic ? 'PUBLIC' : 'PRIVÉ',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: txtColor, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
