import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// FilterDialog - Search/discovery filters for swipe screen
/// Ported from web app FilterModal.jsx
class FilterDialog extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterDialog({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
    
    // Set defaults if not present
    _filters['location'] ??= '';
    _filters['maxDistance'] ??= 'any';
    _filters['ageMin'] ??= 18;
    _filters['ageMax'] ??= 50;
    _filters['gender'] ??= 'everyone';
  }

  void _applyFilters() {
    widget.onApplyFilters(_filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'location': '',
        'maxDistance': 'any',
        'ageMin': 18,
        'ageMax': 50,
        'gender': 'everyone',
      };
    });
    widget.onApplyFilters(_filters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cupidPink, AppColors.cupidPink],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Filter
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter city or leave blank',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      controller: TextEditingController(
                        text: _filters['location'],
                      ),
                      onChanged: (value) {
                        _filters['location'] = value;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Maximum Distance
                    const Text(
                      'Maximum Distance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _filters['maxDistance'],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'any',
                          child: Text('Any distance'),
                        ),
                        DropdownMenuItem(
                          value: 'same-city',
                          child: Text('Same city only'),
                        ),
                        DropdownMenuItem(
                          value: 'same-region',
                          child: Text('Same region'),
                        ),
                        DropdownMenuItem(
                          value: 'nearby',
                          child: Text('Nearby cities'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filters['maxDistance'] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Age Range
                    Text(
                      'Age Range: ${_filters['ageMin']} - ${_filters['ageMax']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: RangeValues(
                        (_filters['ageMin'] as int).toDouble(),
                        (_filters['ageMax'] as int).toDouble(),
                      ),
                      min: 18,
                      max: 65,
                      divisions: 47,
                      activeColor: AppColors.cupidPink,
                      labels: RangeLabels(
                        _filters['ageMin'].toString(),
                        _filters['ageMax'].toString(),
                      ),
                      onChanged: (values) {
                        setState(() {
                          _filters['ageMin'] = values.start.round();
                          _filters['ageMax'] = values.end.round();
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Gender Filter
                    const Text(
                      'Show Me',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGenderButton('everyone', 'Everyone'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildGenderButton('men', 'Men'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildGenderButton('women', 'Women'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cupidPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(String value, String label) {
    final isSelected = _filters['gender'] == value;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _filters['gender'] = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.cupidPink : Colors.grey[100],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
