import 'package:flutter/foundation.dart';

/// The Data Model used across FavoritePage, Home, and EventPackage screens
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
}

class FavoritesManager extends ChangeNotifier {
  // Private list to hold the favorited packages
  final List<Package> _favorites = [];

  // Getter to access the list from FavoritePage
  List<Package> get favorites => List.unmodifiable(_favorites);

  /// Checks if a specific catering service is already in the favorites list
  bool isFavorite(String id) {
    return _favorites.any((pkg) => pkg.id == id);
  }

  /// Use this for Home and Browse screens to toggle the heart icon
  void toggleFavorite(Package package) {
    final index = _favorites.indexWhere((pkg) => pkg.id == package.id);
    if (index != -1) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(package);
    }
    notifyListeners(); // This triggers the UI refresh on all screens
  }

  /// Explicitly add a package (used in EventPackagesScreen logic)
  void addFavorite(Package package) {
    if (!isFavorite(package.id)) {
      _favorites.add(package);
      notifyListeners();
    }
  }

  /// Explicitly remove a package (used in the FavoritePage delete button)
  void removeFavorite(String id) {
    _favorites.removeWhere((pkg) => pkg.id == id);
    notifyListeners();
  }
}
