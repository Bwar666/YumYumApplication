import 'package:cap/Pages/RecipeSubmissionPage.dart';
import 'package:cap/Pages/SearchPage.dart';
import 'package:cap/constants.dart';
import 'package:cap/models/recipe_model.dart';
import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  final Filter initialFilter;
  final ValueChanged<Filter> onApply;

  const FilterDialog({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Difficulty? _selectedDifficulty;
  late String? _selectedCategory;
  late RangeValues _prepTimeRange;
  final List<String> _categories = [
    'Dinner',
    'Breakfast',
    'Lunch',
    'Fast Food',
    'Appetizers',
    'Salad',
    'Dessert'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.initialFilter.difficulty;
    _selectedCategory = widget.initialFilter.category;
    _prepTimeRange = RangeValues(
      widget.initialFilter.minPreparationTime?.toDouble() ?? 0,
      widget.initialFilter.maxPreparationTime?.toDouble() ?? 120,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Recipes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FilterSection(
                    title: 'Difficulty Level',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Difficulty.values.map((difficulty) {
                        final label = difficulty.toString().split('.').last;
                        final isSelected = _selectedDifficulty == difficulty;
                        return FilterChip(
                          label: Text(label[0].toUpperCase() + label.substring(1)),
                          selected: isSelected,
                          selectedColor: AppConstants.primaryColor?.withOpacity(0.2),
                          checkmarkColor: AppConstants.primaryColor,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) => setState(() {
                            _selectedDifficulty = selected ? difficulty : null;
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  FilterSection(
                    title: 'Meal Category',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: AppConstants.primaryColor?.withOpacity(0.2),
                          checkmarkColor: AppConstants.primaryColor,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) => setState(() {
                            _selectedCategory = selected ? category : null;
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  FilterSection(
                    title: 'Preparation Time (minutes)',
                    child: RangeSlider(
                      values: _prepTimeRange,
                      min: 0,
                      max: 120,
                      divisions: 12,
                      labels: RangeLabels(
                        '${_prepTimeRange.start.round()}',
                        '${_prepTimeRange.end.round()}',
                      ),
                      activeColor: AppConstants.primaryColor,
                      onChanged: (values) => setState(() => _prepTimeRange = values),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDifficulty = null;
                      _selectedCategory = null;
                      _prepTimeRange = const RangeValues(0, 120);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _applyFilters(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _applyFilters() {
    final filter = Filter(
      difficulty: _selectedDifficulty,
      category: _selectedCategory,
      minPreparationTime: _prepTimeRange.start.round(),
      maxPreparationTime: _prepTimeRange.end.round(),
    );
    widget.onApply(filter);
    Navigator.pop(context);
  }
}