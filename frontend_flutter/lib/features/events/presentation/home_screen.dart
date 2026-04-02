import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/events/data/events_repository.dart';
import 'package:frontend_flutter/shared/widgets/event_card.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Stockage local optimiste
  final Map<String, bool> _likedStates = {};

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    final likedEvents = await ref.read(eventsRepositoryProvider).fetchLikedEvents();
    if (mounted) {
      setState(() {
        for (var event in likedEvents) {
          _likedStates[event.id] = true;
        }
      });
    }
  }

  Future<void> _onLikeToggled(String eventId) async {
    final isLiked = _likedStates[eventId] ?? false;
    
    // UI Optimiste
    setState(() {
      _likedStates[eventId] = !isLiked;
    });

    try {
      await ref.read(eventsRepositoryProvider).toggleLike(eventId);
    } catch (e) {
      // Revenir en arrière en cas d'erreur
      setState(() {
        _likedStates[eventId] = isLiked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(eventsListProvider);
          _loadLikes();
        },
        child: eventsAsync.when(
          data: (events) => events.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(
                      event: event,
                      onTap: () => context.push('/event/${event.id}'),
                      isLiked: _likedStates[event.id] ?? false,
                      onLikePressed: () => _onLikeToggled(event.id),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _buildErrorState(context, ref, err),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/event/create'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_available_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Aucun événement pour le moment...', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.push('/event/create'),
            child: const Text('Créer le premier événement'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: ${err.toString()}', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(eventsListProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
