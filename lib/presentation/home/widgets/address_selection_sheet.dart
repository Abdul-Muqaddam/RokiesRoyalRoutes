import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../data/models/user_models.dart';
import '../../profile/saved_locations_view_model.dart';
import '../../../domain/repositories/booking_repository.dart';

class AddressSelectionSheet extends ConsumerStatefulWidget {
  final Function(Map<String, String>) onLocationSelected;
  const AddressSelectionSheet({super.key, required this.onLocationSelected});

  @override
  ConsumerState<AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends ConsumerState<AddressSelectionSheet> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();

  String? _selectedFrom;
  String? _selectedTo;
  List<Prediction> _suggestions = [];
  bool _isConfirmState = false;

  final List<Map<String, String>> _fallbackRecentPlaces = [
    {'name': 'Office', 'address': '2972 Westheimer Rd. Santa Ana, Illinois 85486', 'distance': '2.7km'},
    {'name': 'Coffee shop', 'address': '1901 Thornridge Cir. Shiloh, Hawaii 81063', 'distance': '1.1km'},
  ];

  @override
  void initState() {
    super.initState();
    _fromController.text = 'Current location';
    _selectedFrom = 'Current location';
    
    _fromFocus.addListener(() => setState(() {}));
    _toFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    try {
      final repo = ref.read(userRepositoryProvider);
      final response = await repo.getAutocompleteSuggestions(input, "AIzaSyDwTHDeGqgifYZGbYRtMakvOZKnIlpftX8");
      setState(() => _suggestions = response.predictions);
    } catch (e) {
      // Silently fail
    }
  }

  void _onConfirm() {
    if (_selectedFrom != null && _selectedTo != null) {
      widget.onLocationSelected({
        'from': _selectedFrom!,
        'to': _selectedTo!,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Text(
                  'Select address',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22.sp, color: Colors.black45),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isConfirmState) _buildSelectionState(brandYellow, ref) else _buildConfirmState(brandYellow),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionState(Color brandYellow, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            children: [
              _buildAddressInput(
                controller: _fromController,
                focusNode: _fromFocus,
                hintText: 'From',
                icon: Icons.my_location,
                brandYellow: brandYellow,
                onChanged: (val) {
                   _fetchSuggestions(val);
                   setState(() => _selectedFrom = null);
                },
              ),
              SizedBox(height: 12.h),
              _buildAddressInput(
                controller: _toController,
                focusNode: _toFocus,
                hintText: 'To',
                icon: Icons.location_on_outlined,
                brandYellow: brandYellow,
                onChanged: (val) {
                   _fetchSuggestions(val);
                   setState(() => _selectedTo = null);
                },
              ),
            ],
          ),
        ),
        
        if (_suggestions.isNotEmpty)
          _buildSuggestionsList(brandYellow)
        else
          _buildRecentPlaces(brandYellow, ref),
      ],
    );
  }

  Widget _buildAddressInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required Color brandYellow,
    required Function(String) onChanged,
  }) {
    final bool isFocused = focusNode.hasFocus;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isFocused ? brandYellow : Colors.grey[200]!, width: isFocused ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: isFocused ? brandYellow : Colors.black38),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (val) {
                // If the user tries to edit "Current location", clear it entirely
                if (controller.text.startsWith('Current location') && val.length < 'Current location'.length) {
                  controller.clear();
                  onChanged('');
                } else if (val.length > 0 && controller.text == 'Current location') {
                   // This case shouldn't happen easily with normal typing but good for safety
                   controller.clear();
                   onChanged('');
                } else {
                  onChanged(val);
                }
              },
              style: TextStyle(
                fontSize: 15.sp, 
                color: controller.text == 'Current location' ? brandYellow : Colors.black87, 
                fontWeight: controller.text == 'Current location' ? FontWeight.bold : FontWeight.w500
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
          if (controller.text.isNotEmpty && isFocused)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Icon(Icons.cancel, size: 18.sp, color: Colors.black12),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(Color brandYellow) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 300.h),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final s = _suggestions[index];
          return ListTile(
            leading: Icon(Icons.location_on_outlined, color: Colors.black26, size: 20.sp),
            title: Text(s.structuredFormatting.mainText, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            subtitle: Text(s.description, style: TextStyle(fontSize: 12.sp, color: Colors.black38), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              final address = s.description;
              ref.read(bookingRepositoryProvider).addRecentDestination(address);
              
              if (_fromFocus.hasFocus) {
                _fromController.text = address;
                _selectedFrom = address;
              } else {
                _toController.text = address;
                _selectedTo = address;
              }
              setState(() => _suggestions = []);
              FocusScope.of(context).unfocus();
              if (_selectedFrom != null && _selectedTo != null) {
                setState(() => _isConfirmState = true);
              }
            },
          );
        },
      ),
    );
  }

  bool _showAllRecent = false;

  Widget _buildRecentPlaces(Color brandYellow, WidgetRef ref) {
    final recentDestinationsAsync = ref.watch(recentDestinationsProvider);
    final bool isFromFocused = _fromFocus.hasFocus;
    final bool isToFocused = _toFocus.hasFocus;
    final bool isAnyEmpty = (isFromFocused && _fromController.text.isEmpty) || (isToFocused && _toController.text.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAnyEmpty)
          ListTile(
            leading: Icon(Icons.my_location, color: brandYellow, size: 22.sp),
            title: Text(
              'Use current location',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: brandYellow),
            ),
            onTap: () {
              setState(() {
                if (isFromFocused) {
                  _fromController.text = 'Current location';
                  _selectedFrom = 'Current location';
                } else {
                  _toController.text = 'Current location';
                  _selectedTo = 'Current location';
                }
              });
              FocusScope.of(context).unfocus();
              if (_selectedFrom != null && _selectedTo != null) {
                setState(() => _isConfirmState = true);
              }
            },
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent places',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (recentDestinationsAsync.hasValue && recentDestinationsAsync.value!.length > 3)
                GestureDetector(
                  onTap: () => setState(() => _showAllRecent = !_showAllRecent),
                  child: Text(
                    _showAllRecent ? 'See Less' : 'See All',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: brandYellow),
                  ),
                ),
            ],
          ),
        ),
        recentDestinationsAsync.when(
          data: (locations) {
            if (locations.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Center(
                  child: Text('No recent places yet', style: TextStyle(color: Colors.grey[500], fontSize: 13.sp)),
                ),
              );
            }
            final placesToDisplay = _showAllRecent ? locations : locations.take(3).toList();
            
            return Column(
              children: placesToDisplay.map((place) => ListTile(
                leading: Icon(
                  Icons.history, 
                  color: Colors.black26, 
                  size: 22.sp
                ),
                title: Text(place.address.split(',').first, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                subtitle: Text(place.address, style: TextStyle(fontSize: 12.sp, color: Colors.black38), maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  ref.read(bookingRepositoryProvider).addRecentDestination(place.address);
                  if (_fromFocus.hasFocus || _fromController.text.isEmpty) {
                    _fromController.text = place.address;
                    _selectedFrom = place.address;
                  } else {
                    _toController.text = place.address;
                    _selectedTo = place.address;
                  }
                  if (_selectedFrom != null && _selectedTo != null) {
                    setState(() => _isConfirmState = true);
                  }
                },
              )).toList(),
            );
          },
          loading: () => Center(child: Padding(
            padding: EdgeInsets.all(20.r),
            child: SizedBox(width: 20.r, height: 20.r, child: CircularProgressIndicator(strokeWidth: 2, color: brandYellow)),
          )),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildConfirmState(Color brandYellow) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Column(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 24.sp),
                    Container(width: 2.w, height: 35.h, color: Colors.grey[200]),
                    Icon(Icons.location_on, color: brandYellow, size: 24.sp),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFrom?.split(',').first ?? 'Current location',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedFrom ?? 'Waiting for location...',
                      style: TextStyle(fontSize: 12.sp, color: Colors.black38),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTo?.split(',').first ?? 'Destination',
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _selectedTo ?? 'Waiting for destination...',
                      style: TextStyle(fontSize: 12.sp, color: Colors.black38),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandYellow,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text('Confirm Location', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
