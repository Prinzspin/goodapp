import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/events/data/events_repository.dart';
import 'package:frontend_flutter/shared/widgets/event_card.dart';

class LikesScreen extends ConsumerWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedEventsAsync = ref.watch(likedEventsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(likedEventsProvider.future),
        child: likedEventsAsync.when(
          data: (events) => events.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(
                      event: event,
                      isLiked: true, // Par définition ici
                      onTap: () => context.push('/event/${event.id}'),
                      onLikePressed: () async {
                        await ref.read(eventsRepositoryProvider).toggleLike(event.id);
                        ref.invalidate(likedEventsProvider);
                        ref.invalidate(eventsListProvider);
                      },
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Erreur: ${err.toString()}'),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Aucun événement liké', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
