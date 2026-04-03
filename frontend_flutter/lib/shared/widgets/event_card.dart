import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend_flutter/core/network/pb_client.dart';
import 'package:frontend_flutter/features/events/data/event_model.dart';
import 'package:intl/intl.dart';

class EventCard extends ConsumerWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final bool isLiked;
  final VoidCallback? onLikePressed;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.isLiked = false,
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pb = ref.read(pocketBaseProvider);
    final dateStr = DateFormat('dd MMM yyyy • HH:mm').format(event.startDate);
    
    // Status badges colors (accessible variants)
    final badgeBgColor = event.isPublic ? const Color(0xFFDCFCE7) : const Color(0xFFE0E7FF);
    final badgeTxtColor = event.isPublic ? const Color(0xFF16A34A) : Theme.of(context).colorScheme.primary;
    final badgeIcon = event.isPublic ? Icons.public : Icons.lock_outline;

    return Semantics(
      button: true,
      label: 'Événement ${event.title}, le $dateStr. ${event.isPublic ? "Public" : "Privé"}. ${event.likesCount} J\'aime, ${event.membersCount} Participants.',
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Event
              if (event.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: '${pb.baseUrl}/api/files/events/${event.id}/${event.photos[0]}',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(height: 180, color: const Color(0xFFF1F5F9)),
                      errorWidget: (context, url, error) => Container(
                        height: 180, 
                        color: const Color(0xFFF1F5F9), 
                        child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),
              
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, event.photos.isNotEmpty ? 0 : 16.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A), // Slate 900
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            semanticsLabel: "", // Handled by parent semantic node
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 14, color: badgeTxtColor),
                              const SizedBox(width: 4),
                              Text(
                                event.isPublic ? 'Public' : 'Privé',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: badgeTxtColor,
                                  letterSpacing: 0.5,
                                ),
                                semanticsLabel: "",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Date & Location
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Color(0xFF475569)),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF475569), // Slate 600
                            fontWeight: FontWeight.w500,
                          ),
                          semanticsLabel: "",
                        ),
                      ],
                    ),
                    if (event.locationName != null && event.locationName!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF475569)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.locationName!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              semanticsLabel: "",
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      event.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF334155), // Slate 700
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: "",
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Footer: Actions & Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Coeur
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              button: true,
                              label: isLiked ? 'Retirer J\'aime' : 'J\'aime',
                              child: InkWell(
                                onTap: onLikePressed,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border, 
                                    size: 22, 
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.likesCount}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              semanticsLabel: "",
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Membres
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.group_outlined, size: 22, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              '${event.membersCount}', 
                              style: const TextStyle(
                                color: Color(0xFF475569), 
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              semanticsLabel: "",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
