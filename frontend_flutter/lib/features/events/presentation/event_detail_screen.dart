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

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final membershipAsync = ref.watch(eventMembershipProvider(eventId));
    final currentUser = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail Événement')),
      body: eventAsync.when(
        data: (event) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (event.photos.isNotEmpty)
                _buildPhotoGallery(context, ref, event)
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
                      children: [
                        Expanded(
                          child: Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        _buildStatusBadge(event),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildIconInfo(Icons.access_time_outlined, DateFormat('EEEE d MMMM, HH:mm').format(event.startDate)),
                    if (event.locationName != null) _buildIconInfo(Icons.place_outlined, event.locationName!),
                    const Divider(height: 32),
                    const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      event.description.isNotEmpty ? event.description : "Pas de description.",
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 32),

                    // Section Membership & Action
                    _buildMembershipSection(context, ref, event, membershipAsync),

                    // Section Gestion Demandes (visible UNIQUEMENT par le créateur)
                    if (currentUser != null && event.creatorId == currentUser.id) ...[
                      const SizedBox(height: 32),
                      _buildPendingRequestsSection(context, ref, event),
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
  Widget _buildPhotoGallery(BuildContext context, WidgetRef ref, EventModel event) {
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
  Widget _buildMembershipSection(
      BuildContext context, WidgetRef ref, EventModel event, AsyncValue<EventMemberModel?> membershipAsync) {
    return membershipAsync.when(
      data: (membership) {
        final isOwner = membership?.role == 'owner';
        final isAccepted = membership?.status == 'accepted';

        // CAS 1 : Membre accepted / Owner
        if (isOwner || isAccepted) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(isOwner ? 'Vous êtes l\'organisateur' : 'Vous participez à cet événement',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push('/chat/${event.id}'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, minimumSize: const Size(double.infinity, 50)),
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: const Text('Accéder à la discussion', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }

        // CAS 2 : Pending
        if (membership?.status == 'pending') {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(children: [
              Icon(Icons.hourglass_empty, color: Colors.amber),
              SizedBox(width: 12),
              Text('Demande envoyée (En attente de validation)', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
          );
        }

        // CAS 3 : Rejected
        if (membership?.status == 'rejected') {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(children: [
              Icon(Icons.cancel_outlined, color: Colors.red),
              SizedBox(width: 12),
              Text('Votre demande a été refusée', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
            ]),
          );
        }

        // CAS 4 : Non membre
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!event.isPublic)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.privacy_tip_outlined, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(child: Text('Événement privé. Accès à la discussion après validation par l\'organisateur.',
                      style: TextStyle(fontSize: 13, color: Colors.grey))),
                ]),
              ),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => _joinEvent(context, ref, event),
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
  Future<void> _joinEvent(BuildContext context, WidgetRef ref, EventModel event) async {
    try {
      await ref.read(eventsRepositoryProvider).joinEvent(event.id, event.isPublic);
      
      // FORCAGE DU REFRESH (ref.invalidate() laisse parfois une UI fantôme "non-chargée" au retour de l'API)
      ref.refresh(eventMembershipProvider(eventId));
      ref.refresh(eventDetailProvider(eventId));
      ref.invalidate(eventsListProvider);
      ref.invalidate(likedEventsProvider);
      ref.invalidate(conversationsListProvider); // Le chat général s'est potentiellement ouvert

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event.isPublic ? "Vous avez rejoint l'événement !" : "Demande envoyée !")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // === GESTION DEMANDES PENDING (Visible par le créateur) ===
  Widget _buildPendingRequestsSection(BuildContext context, WidgetRef ref, EventModel event) {
    final pendingAsync = ref.watch(pendingMembersProvider(event.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text('Demandes de participation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        pendingAsync.when(
          data: (pendingMembers) {
            if (pendingMembers.isEmpty) {
              return const Text('Aucune demande en attente.', style: TextStyle(color: Colors.grey));
            }
            return Column(
              children: pendingMembers.map((member) => _buildPendingMemberTile(context, ref, event, member)).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Impossible de charger les demandes'),
        ),
      ],
    );
  }

  Widget _buildPendingMemberTile(BuildContext context, WidgetRef ref, EventModel event, EventMemberModel member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(member.userName ?? member.userId, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Accepter',
              onPressed: () async {
                await ref.read(eventsRepositoryProvider).acceptMember(member.id);
                ref.refresh(pendingMembersProvider(event.id)); // Force réévaluation immédiate
                ref.invalidate(eventDetailProvider(event.id)); // Maj des compteurs
                ref.invalidate(conversationsListProvider); // Maj du chat list central
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membre accepté !')));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Refuser',
              onPressed: () async {
                await ref.read(eventsRepositoryProvider).rejectMember(member.id);
                ref.refresh(pendingMembersProvider(event.id)); // Force réévaluation immédiate
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande refusée.')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // === HELPERS ===
  Widget _buildIconInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(EventModel event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: event.isPublic ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        event.isPublic ? 'PUBLIC' : 'PRIVÉ',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
            color: event.isPublic ? Colors.green.shade700 : Colors.amber.shade800),
      ),
    );
  }
}
