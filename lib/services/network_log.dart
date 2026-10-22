import 'package:flutter/foundation.dart';
import 'package:nse_price_spike/models/network_event.dart';

/// In-memory log of the most recent network (or fixture) fetches, newest
/// first. Cleared when the app restarts.
class NetworkLog extends ChangeNotifier {
  static const capacity = 20;

  final List<NetworkEvent> _events = [];

  List<NetworkEvent> get events => List.unmodifiable(_events);

  void add(NetworkEvent event) {
    _events.insert(0, event);
    if (_events.length > capacity) {
      _events.removeRange(capacity, _events.length);
    }
    notifyListeners();
  }
}
