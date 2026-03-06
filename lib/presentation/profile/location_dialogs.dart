import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_models.dart';
import 'saved_locations_view_model.dart';

class SavedPlacesDialog extends ConsumerWidget {
  const SavedPlacesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(savedLocationsViewModelProvider);
    final viewModel = ref.read(savedLocationsViewModelProvider.notifier);
    final isActionLoading = ref.watch(savedLocationsViewModelProvider.select((vm) => ref.read(savedLocationsViewModelProvider.notifier).isActionLoading));

    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      title: Text(
        'Saved Places',
        style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color, fontWeight: FontWeight.bold, fontSize: 18.sp),
      ),
      content: SizedBox(
        width: 320.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                locationsAsync.when(
                  data: (locations) {
                    if (locations.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Text(
                          'No saved places yet.',
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12.sp),
                        ),
                      );
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 300.h),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: locations.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final place = locations[index];
                          return _PlaceItemRow(
                            place: place,
                            onEdit: () => _showAddPlaceDialog(context, ref, place: place),
                            onDelete: () => ref.read(savedLocationsViewModelProvider.notifier).deleteCustomLocation(place),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => Padding(
                    padding: EdgeInsets.all(24.h),
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary),
                  ),
                  error: (err, _) => Text('Error: $err'),
                ),
                SizedBox(height: 16.h),
                TextButton.icon(
                  onPressed: () => _showAddPlaceDialog(context, ref),
                  icon: Icon(Icons.add, size: 20.w, color: Theme.of(context).colorScheme.secondary),
                  label: Text(
                    'Add New Place',
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(minimumSize: Size(double.infinity, 48.h)),
                ),
              ],
            ),
            if (isActionLoading)
              Container(
                color: Colors.white.withOpacity(0.5),
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        ),
      ],
    );
  }

  void _showAddPlaceDialog(BuildContext context, WidgetRef ref, {LocationItem? place}) {
    showDialog(
      context: context,
      builder: (context) => AddPlaceDialog(initialPlace: place),
    );
  }
}

class _PlaceItemRow extends StatelessWidget {
  final LocationItem place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlaceItemRow({
    required this.place,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (place.name.toLowerCase() == 'home') {
      icon = Icons.home_outlined;
    } else if (place.name.toLowerCase() == 'work') {
      icon = Icons.work_outline;
    } else {
      icon = Icons.location_on_outlined;
    }

    final isFixed = place.name.toLowerCase() == 'home' || place.name.toLowerCase() == 'work';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  place.address,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, color: Theme.of(context).textTheme.bodySmall?.color, size: 16.w),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (!isFixed) ...[
            SizedBox(width: 8.w),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.6), size: 16.w),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class AddPlaceDialog extends ConsumerStatefulWidget {
  final LocationItem? initialPlace;
  const AddPlaceDialog({super.key, this.initialPlace});

  @override
  ConsumerState<AddPlaceDialog> createState() => _AddPlaceDialogState();
}

class _AddPlaceDialogState extends ConsumerState<AddPlaceDialog> {
  late TextEditingController _labelController;
  late TextEditingController _addressController;
  bool _isFetchingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialPlace?.name ?? '');
    _addressController = TextEditingController(text: widget.initialPlace?.address ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We watch the entire state to get updates on isActionLoading (manual provider)
    final viewModel = ref.watch(savedLocationsViewModelProvider.notifier);
    final isActionLoading = viewModel.isActionLoading;
    final suggestions = viewModel.suggestions;

    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      title: Text(
        widget.initialPlace == null ? 'Add New Place' : 'Edit Place',
        style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color, fontWeight: FontWeight.bold, fontSize: 18.sp),
      ),
      content: SizedBox(
        width: 320.w,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.initialPlace?.name != 'Home' && widget.initialPlace?.name != 'Work') ...[
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: 'Label (e.g. Gym)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                  ),
                  ),
                ),
                SizedBox(height: 12.h),
              ] else 
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    'Editing ${widget.initialPlace!.name}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                ),
              
              TextField(
                controller: _addressController,
                onChanged: viewModel.fetchSuggestions,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ),
              
              if (suggestions.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r)],
                  ),
                  child: Column(
                    children: suggestions.take(5).map((suggestion) => ListTile(
                      title: Text(suggestion.structuredFormatting.mainText, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                      subtitle: Text(suggestion.description, style: TextStyle(fontSize: 11.sp)),
                      onTap: () {
                        _addressController.text = suggestion.description;
                        viewModel.clearSuggestions();
                      },
                    )).toList(),
                  ),
                ),

              TextButton.icon(
                onPressed: _isFetchingCurrentLocation ? null : _useCurrentLocation,
                icon: _isFetchingCurrentLocation 
                    ? SizedBox(width: 14.w, height: 14.h, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.secondary))
                    : Icon(Icons.my_location, size: 14.w, color: Theme.of(context).colorScheme.secondary),
                label: Text(
                  'Use current location',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11.sp, fontWeight: FontWeight.w500),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
        ),
        ElevatedButton(
          onPressed: isActionLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: isActionLoading
              ? SizedBox(height: 20.h, width: 20.h, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2))
              : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _useCurrentLocation() async {
    setState(() => _isFetchingCurrentLocation = true);
    final address = await ref.read(savedLocationsViewModelProvider.notifier).getCurrentAddress();
    if (address != null) {
      _addressController.text = address;
    }
    setState(() => _isFetchingCurrentLocation = false);
  }

  void _save() {
    final label = _labelController.text;
    final address = _addressController.text;
    if (address.isEmpty) return;

    final name = widget.initialPlace?.name ?? label;
    if (name.isEmpty) return;

    if (name.toLowerCase() == 'home' || name.toLowerCase() == 'work') {
      ref.read(savedLocationsViewModelProvider.notifier).saveLocation(name, address).then((_) {
        if (mounted) Navigator.pop(context);
      });
    } else {
      ref.read(savedLocationsViewModelProvider.notifier).saveCustomLocation(name, address).then((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }
}
