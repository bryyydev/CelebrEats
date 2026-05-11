import 'package:flutter/foundation.dart';

class Package {
  final String id;
  final String image;
  final String title;
  final double rating;
  final String price;
  final String oldPrice;
  final String guests;

  Package({
    required this.id,
    required this.image,
    required this.title,
    required this.rating,
    required this.price,
    required this.oldPrice,
    required this.guests,
  });

  // ✅ CRITICAL FIX: ensures same package = same object logically
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Package && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class FavoritesManager extends ChangeNotifier {
  final List<Package> _favorites = [];

  List<Package> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String id) {
    return _favorites.any((pkg) => pkg.id == id);
  }

  void toggleFavorite(Package package) {
    final exists = _favorites.indexWhere((p) => p.id == package.id);

    if (exists != -1) {
      _favorites.removeAt(exists);
    } else {
      _favorites.add(package);
    }

    notifyListeners();
  }

  void addFavorite(Package package) {
    if (!isFavorite(package.id)) {
      _favorites.add(package);
      notifyListeners();
    }
  }

  void removeFavorite(String id) {
    _favorites.removeWhere((pkg) => pkg.id == id);
    notifyListeners();
  }

  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }
}
