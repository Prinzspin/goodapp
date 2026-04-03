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
  // Stockage local optimiste des likes
  final Map<String, bool> _likedStates = {};

  // Recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLikes();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    setState(() {
      _likedStates[eventId] = !isLiked;
    });
    try {
      await ref.read(eventsRepositoryProvider).toggleLike(eventId);
    } catch (e) {
      setState(() {
        _likedStates[eventId] = isLiked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // === BARRE DE RECHERCHE ===
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: theme.scaffoldBackgroundColor,
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher un événement...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                        tooltip: 'Effacer',
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9), // Slate 100
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // === LISTE DES ÉVÉNEMENTS ===
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.refresh(eventsListProvider);
                _loadLikes();
              },
              child: eventsAsync.when(
                data: (events) {
                  // Filtrage local
                  final filtered = _searchQuery.isEmpty
                      ? events
                      : events.where((e) {
                          return e.title.toLowerCase().contains(_searchQuery) ||
                              (e.locationName?.toLowerCase().contains(_searchQuery) ?? false) ||
                              e.description.toLowerCase().contains(_searchQuery);
                        }).toList();

                  if (events.isEmpty) return _buildEmptyState(context, isSearch: false);
                  if (filtered.isEmpty) return _buildEmptyState(context, isSearch: true);

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final event = filtered[index];
                      return EventCard(
                        event: event,
                        onTap: () => context.push('/event/${event.id}'),
                        isLiked: _likedStates[event.id] ?? false,
                        onLikePressed: () => _onLikeToggled(event.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => _buildErrorState(context, ref, err),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/event/create'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isSearch}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearch ? Icons.search_off : Icons.event_available_outlined,
              size: 72,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch
                  ? 'Aucun événement trouvé pour\n"$_searchQuery"'
                  : 'Aucun événement pour le moment...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
                height: 1.4,
              ),
            ),
            if (isSearch) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
                onPressed: () => _searchController.clear(),
              ),
            ] else ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.push('/event/create'),
                child: const Text('Créer le premier événement'),
              ),
            ],
          ],
        ),
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
