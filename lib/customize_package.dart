import 'package:flutter/material.dart';
import 'datetime_picker_page.dart';

class CustomizePackagePage extends StatefulWidget {
  const CustomizePackagePage({super.key});

  @override
  State<CustomizePackagePage> createState() => _CustomizePackagePageState();
}

class _CustomizePackagePageState extends State<CustomizePackagePage> {
  String selectedTab = 'food';

  Set<String> selectedAppetizers = {};
  Set<String> selectedMainCourse = {};
  Set<String> selectedDesserts = {};
  Set<String> selectedDrinks = {};
  Set<String> selectedDecorations = {};
  Set<String> selectedExtraServices = {};

  int get totalFoodItems {
    return selectedAppetizers.length +
        selectedMainCourse.length +
        selectedDesserts.length +
        selectedDrinks.length;
  }

  int get totalDecorations {
    return selectedDecorations.length + selectedExtraServices.length;
  }

  int get totalItems => totalFoodItems + totalDecorations;

  bool get canProceed => totalItems > 0;

  void _switchTab(String tab) {
    if (selectedTab != tab) {
      setState(() {
        selectedTab = tab;
      });
    }
  }

  void _proceedToNext() {
    if (!canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item to proceed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedData = {
      'appetizers': selectedAppetizers.toList(),
      'mainCourse': selectedMainCourse.toList(),
      'desserts': selectedDesserts.toList(),
      'drinks': selectedDrinks.toList(),
      'decorations': selectedDecorations.toList(),
      'extraServices': selectedExtraServices.toList(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DateTimePickerPage(selectedItems: selectedData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Customize Package',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build Your Perfect Event',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Customize food and decorations for your event',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Items Selected:',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$totalItems',
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            icon: Icons.restaurant,
                            label: 'Food & Drinks',
                            count: totalFoodItems,
                            isSelected: selectedTab == 'food',
                            onTap: () => _switchTab('food'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTabButton(
                            icon: Icons.card_giftcard,
                            label: 'Decorations & Extras',
                            count: totalDecorations,
                            isSelected: selectedTab == 'decorations',
                            onTap: () => _switchTab('decorations'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (selectedTab == 'food')
                    _buildFoodSection()
                  else
                    _buildDecorationsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed
                        ? Colors.deepOrange
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: canProceed ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        canProceed
                            ? 'Next - Select Date & Time'
                            : 'Select Items to Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (canProceed) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection('Appetizers', selectedAppetizers.length, [
          'Beef Lumpiang Shanghai',
          'Chicken Lumpiang Shanghai',
          'Fried Ham and Cheese Roll',
          'Crispy Fried Calamari',
        ], selectedAppetizers),
        const SizedBox(height: 20),
        _buildCategorySection('Main Course', selectedMainCourse.length, [
          'Lechon Baboy',
          'Beef Caldereta',
          'Pancit Bihon',
          'Beef Steak',
          'Pork Menudo',
          'Fish Fillet',
        ], selectedMainCourse),
        const SizedBox(height: 20),
        _buildCategorySection('Desserts', selectedDesserts.length, [
          'Leche Flan',
          'Cassava Cake',
          'Buko Pandan',
          'Fruit Salad',
          'Kutsinta',
        ], selectedDesserts),
        const SizedBox(height: 20),
        _buildCategorySection('Drinks', selectedDrinks.length, [
          'Iced Tea',
          'Soft Drinks',
          'Fresh Juice',
          'Coffee',
          'Water',
          'Beer',
        ], selectedDrinks),
      ],
    );
  }

  Widget _buildDecorationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection('Decorations', selectedDecorations.length, [
          'Balloon Arch',
          'Table Centerpieces',
          'Photo Booth',
          'Backdrop',
          'Chair Covers',
          'Lighting',
        ], selectedDecorations),
        const SizedBox(height: 20),
        _buildCategorySection('Extra Services', selectedExtraServices.length, [
          'Sound System',
          'Service Staff',
          'Event Host',
          'Photographer',
          'Live Band',
          'DJ',
        ], selectedExtraServices),
        const SizedBox(height: 20),
        if (totalDecorations > 0) _buildPackageSummary(),
      ],
    );
  }

  Widget _buildCategorySection(
    String title,
    int count,
    List<String> items,
    Set<String> selectedSet,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 10),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildSelectionItem(item, selectedSet)),
        ],
      ),
    );
  }

  Widget _buildSelectionItem(String title, Set<String> selectedSet) {
    final isSelected = selectedSet.contains(title);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedSet.remove(title);
          } else {
            selectedSet.add(title);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.deepOrange : Colors.black87,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepOrange : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.deepOrange : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Package Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Food Items:',
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
              Text(
                '$totalFoodItems',
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Decorations & Extras:',
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
              Text(
                '$totalDecorations',
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ready to proceed with your custom package!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
