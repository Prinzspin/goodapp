import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/events/data/events_repository.dart';
import 'package:frontend_flutter/features/events/data/event_model.dart';
import 'package:intl/intl.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // L'événement sélectionné pour l'aperçu superposé
  EventModel? _selectedEvent;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsListProvider);

    return Scaffold(
      body: eventsAsync.when(
        data: (events) {
          // Filtrer seulement les événements avec coordonnées
          final geoEvents = events.where((e) => e.lat != null && e.lng != null).toList();

          if (geoEvents.isEmpty) {
            return const Center(child: Text('Aucun événement géolocalisé disponible'));
          }

          // Centrer sur le premier trouvé ou une coordonnée par défaut
          final initialCenter = LatLng(geoEvents.first.lat!, geoEvents.first.lng!);

          return Stack(
            children: [
              // Carte plein écran
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 13,
                  onTap: (tapPosition, point) => setState(() => _selectedEvent = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.goodapp.events',
                  ),
                  MarkerLayer(
                    markers: geoEvents.map((event) {
                      return Marker(
                        point: LatLng(event.lat!, event.lng!),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedEvent = event),
                          child: Icon(
                            Icons.location_on,
                            size: 40,
                            color: _selectedEvent?.id == event.id ? Colors.deepPurple : Colors.red,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Aperçu compact superposé (Overlay)
              if (_selectedEvent != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildEventPreview(_selectedEvent!),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildEventPreview(EventModel event) {
    final dateStr = DateFormat('dd MMM yyyy • HH:mm').format(event.startDate);

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.deepPurple.shade100, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  if (event.locationName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(event.locationName!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }
}
