import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider global pour le mode haut contraste
final highContrastProvider = StateProvider<bool>((ref) => false);
