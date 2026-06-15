import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../widgets/app_dialog.dart';

class VehicleManagementScreen extends ConsumerStatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  ConsumerState<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends ConsumerState<VehicleManagementScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('vehicles').select().order('title');
      setState(() {
        _vehicles = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppDialog.show(
          context: context,
          type: DialogType.error,
          title: 'Error',
          message: 'Failed to load vehicles: $e',
        );
      }
    }
  }

  Future<void> _deleteVehicle(String id, String title) async {
    bool confirmed = false;
    await AppDialog.show(
      context: context,
      type: DialogType.warning,
      title: 'Delete Vehicle',
      message: 'Are you sure you want to delete "$title"?',
      primaryButtonText: 'Delete',
      onPrimaryPressed: () {
        confirmed = true;
        Navigator.pop(context);
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
    if (confirmed != true) return;

    try {
      await _supabase.from('vehicles').delete().eq('id', id);
      
      // Invalidate the vehicles provider so Home/Booking screens refresh
      ref.invalidate(allVehiclesProvider);
      
      await _fetchVehicles();
      if (mounted) {
        AppDialog.show(
          context: context,
          type: DialogType.success,
          title: 'Deleted',
          message: '"$title" deleted successfully',
          autoDismissDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          context: context,
          type: DialogType.error,
          title: 'Delete Failed',
          message: 'Failed to delete vehicle: $e',
        );
      }
    }
  }

  void _openVehicleForm({Map<String, dynamic>? vehicle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VehicleFormSheet(
        vehicle: vehicle,
        onSaved: _fetchVehicles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;

    return _isLoading
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : RefreshIndicator(
            onRefresh: _fetchVehicles,
            color: accentColor,
            child: _vehicles.isEmpty
                ? _buildEmpty(accentColor)
                : ListView.separated(
                    padding: EdgeInsets.all(20.w),
                    itemCount: _vehicles.length + 1,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildAddButton(accentColor);
                      final v = _vehicles[index - 1];
                      return _buildVehicleCard(v, accentColor);
                    },
                  ),
          );
  }

  Widget _buildEmpty(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 72.w, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text('No vehicles yet',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          SizedBox(height: 8.h),
          Text('Tap the button below to add your first car',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: () => _openVehicleForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            icon: const Icon(Icons.add),
            label: Text('Add Vehicle', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(Color accentColor) {
    return ElevatedButton.icon(
      onPressed: () => _openVehicleForm(),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        minimumSize: Size(double.infinity, 50.h),
      ),
      icon: const Icon(Icons.add_circle_outline),
      label: Text('Add New Vehicle', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> v, Color accentColor) {
    final isActive = v['is_active'] == true;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Image
          ClipRRect(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
            child: (v['image_url'] ?? '').toString().isNotEmpty
                ? Image.network(
                    v['image_url'],
                    height: 160.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(v['title'] ?? '',
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(v['vehicle_type'] ?? '',
                    style: TextStyle(fontSize: 12.sp, color: accentColor, fontWeight: FontWeight.w600)),
                SizedBox(height: 6.h),
                Text(v['description'] ?? '',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.mediumGray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _infoChip(Icons.person_outline, '${v['passenger_capacity']} pax'),
                    SizedBox(width: 8.w),
                    _infoChip(Icons.luggage_outlined, '${v['luggage_capacity']} bags'),
                    SizedBox(width: 8.w),
                    _infoChip(Icons.attach_money, '\$${v['base_price']}'),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openVehicleForm(vehicle: v),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                          side: BorderSide(color: accentColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text('Edit',
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _deleteVehicle(v['id'].toString(), v['title'] ?? ''),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text('Delete',
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160.h,
      color: Colors.grey.shade100,
      child: Center(
          child: Icon(Icons.directions_car, size: 48.w, color: Colors.grey.shade400)),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.w, color: AppColors.mediumGray),
        SizedBox(width: 3.w),
        Text(label, style: TextStyle(fontSize: 11.sp, color: AppColors.mediumGray)),
      ],
    );
  }
}

// ─── Vehicle Form Sheet ───────────────────────────────────────────────────────

class _VehicleFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? vehicle;
  final VoidCallback onSaved;

  const _VehicleFormSheet({this.vehicle, required this.onSaved});

  @override
  ConsumerState<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends ConsumerState<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _vehicleTypeCtrl;
  late TextEditingController _passengerCtrl;
  late TextEditingController _luggageCtrl;
  late TextEditingController _basePriceCtrl;
  late TextEditingController _pricePerKmCtrl;
  late TextEditingController _pricePerHourCtrl;
  late TextEditingController _currencyCtrl;

  bool _isActive = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  File? _pickedImageFile;          // locally picked image
  String? _existingImageUrl;       // already-saved URL from Supabase

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _titleCtrl = TextEditingController(text: v?['title'] ?? '');
    _descCtrl = TextEditingController(text: v?['description'] ?? '');
    _vehicleTypeCtrl = TextEditingController(text: v?['vehicle_type'] ?? '');
    _passengerCtrl = TextEditingController(text: (v?['passenger_capacity'] ?? '').toString());
    _luggageCtrl = TextEditingController(text: (v?['luggage_capacity'] ?? '').toString());
    _basePriceCtrl = TextEditingController(text: (v?['base_price'] ?? '').toString());
    _pricePerKmCtrl = TextEditingController(text: (v?['price_per_km'] ?? '').toString());
    _pricePerHourCtrl = TextEditingController(text: (v?['price_per_hour'] ?? '').toString());
    _currencyCtrl = TextEditingController(text: v?['currency'] ?? 'USD');
    _isActive = v?['is_active'] ?? true;
    _existingImageUrl = v?['image_url'];
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _descCtrl, _vehicleTypeCtrl, _passengerCtrl, _luggageCtrl,
      _basePriceCtrl, _pricePerKmCtrl, _pricePerHourCtrl, _currencyCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Pick image from gallery ────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _pickedImageFile = File(picked.path));
  }

  // ── Upload to Supabase Storage → return public URL ─────────────────────────
  Future<String?> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);
    String _step = 'starting';

    try {
      // ── STEP 1: File info ─────────────────────────────────────────────────
      _step = 'reading file info';
      final bool fileExists = await file.exists();
      final int fileSize = fileExists ? await file.length() : 0;
      final rawExt = file.path.split('.').last.toLowerCase();
      final ext = rawExt == 'jpg' ? 'jpeg' : rawExt;
      final mimeType = 'image/$ext';
      final fileName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}.$rawExt';

      debugPrint('🔷 [Upload] Step 1 - File info:');
      debugPrint('   Path     : ${file.path}');
      debugPrint('   Exists   : $fileExists');
      debugPrint('   Size     : $fileSize bytes');
      debugPrint('   MIME     : $mimeType');
      debugPrint('   FileName : $fileName');

      if (!fileExists || fileSize == 0) {
        throw Exception('File does not exist or is empty.\nPath: ${file.path}');
      }

      // ── STEP 2: Read bytes ────────────────────────────────────────────────
      _step = 'reading file bytes';
      debugPrint('🔷 [Upload] Step 2 - Reading bytes...');
      final bytes = await file.readAsBytes();
      debugPrint('   Read ${bytes.length} bytes ✅');

      // ── STEP 3: Upload to Supabase Storage ───────────────────────────────
      _step = 'uploading to Supabase Storage (bucket: vehicles)';
      debugPrint('🔷 [Upload] Step 3 - Uploading to Supabase Storage...');
      debugPrint('   Bucket: vehicles | File: $fileName');

      await _supabase.storage
          .from('vehicles')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );
      debugPrint('   Upload to Storage ✅');

      // ── STEP 4: Get public URL ────────────────────────────────────────────
      _step = 'getting public URL';
      debugPrint('🔷 [Upload] Step 4 - Getting public URL...');
      final url = _supabase.storage.from('vehicles').getPublicUrl(fileName);
      debugPrint('   Public URL: $url ✅');

      return url;

    } catch (e, stack) {
      final errMsg = 'FAILED at step: "$_step"\n\nError: $e';
      debugPrint('❌ [Upload] $errMsg');
      debugPrint('   Stack: $stack');

      if (mounted) {
        // Show full error in a dialog for easy debugging
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Upload Failed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '❌ Failed at: $_step\n\n$e',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Common fixes:\n'
                    '• Supabase bucket "vehicles" must exist\n'
                    '• Bucket must be set to PUBLIC\n'
                    '• Storage INSERT policy required',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ── Save vehicle ───────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? imageUrl = _existingImageUrl;

    // Upload new image if one was picked
    if (_pickedImageFile != null) {
      imageUrl = await _uploadImage(_pickedImageFile!);
      if (imageUrl == null) {
        setState(() => _isSaving = false);
        return;
      }
    }

    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'image_url': imageUrl ?? '',
      'vehicle_type': _vehicleTypeCtrl.text.trim(),
      'passenger_capacity': int.tryParse(_passengerCtrl.text) ?? 0,
      'luggage_capacity': int.tryParse(_luggageCtrl.text) ?? 0,
      'base_price': double.tryParse(_basePriceCtrl.text) ?? 0.0,
      'price_per_km': double.tryParse(_pricePerKmCtrl.text) ?? 0.0,
      'price_per_hour': double.tryParse(_pricePerHourCtrl.text) ?? 0.0,
      'currency': _currencyCtrl.text.trim().isEmpty ? 'USD' : _currencyCtrl.text.trim(),
      'is_active': _isActive,
    };

    try {
      if (_isEditing) {
        await _supabase.from('vehicles').update(data).eq('id', widget.vehicle!['id']);
      } else {
        await _supabase.from('vehicles').insert(data);
      }

      // Invalidate the vehicles provider so Home/Booking screens refresh
      ref.invalidate(allVehiclesProvider);

      widget.onSaved();
      if (mounted) Navigator.pop(context);
      if (mounted) {
        AppDialog.show(
          context: context,
          type: DialogType.success,
          title: 'Success',
          message: _isEditing ? 'Vehicle updated successfully!' : 'Vehicle added successfully!',
          autoDismissDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          context: context,
          type: DialogType.error,
          title: 'Save Failed',
          message: 'Failed to save vehicle: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r), topRight: Radius.circular(24.r)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4.r)),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: accentColor),
                    SizedBox(width: 10.w),
                    Text(
                      _isEditing ? 'Edit Vehicle' : 'Add New Vehicle',
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(24.w),
                  children: [
                    // ── Image Picker ─────────────────────────────────────────
                    _buildImagePicker(accentColor),
                    SizedBox(height: 20.h),

                    _buildField('Vehicle Name', _titleCtrl, required: true),
                    SizedBox(height: 14.h),
                    _buildField('Description', _descCtrl, maxLines: 3),
                    SizedBox(height: 14.h),
                    _buildField('Vehicle Type', _vehicleTypeCtrl,
                        hint: 'e.g. Sedan, SUV, Van', required: true),
                    SizedBox(height: 14.h),
                    Row(children: [
                      Expanded(
                          child: _buildField('Passengers', _passengerCtrl,
                              keyboardType: TextInputType.number, required: true)),
                      SizedBox(width: 12.w),
                      Expanded(
                          child: _buildField('Luggage', _luggageCtrl,
                              keyboardType: TextInputType.number, required: true)),
                    ]),
                    SizedBox(height: 14.h),
                    _buildField('Base Price', _basePriceCtrl,
                        keyboardType: TextInputType.number,
                        prefixText: '\$ ',
                        required: true),
                    SizedBox(height: 14.h),
                    Row(children: [
                      Expanded(
                          child: _buildField('Price / km', _pricePerKmCtrl,
                              keyboardType: TextInputType.number, prefixText: '\$ ')),
                      SizedBox(width: 12.w),
                      Expanded(
                          child: _buildField('Price / hr', _pricePerHourCtrl,
                              keyboardType: TextInputType.number, prefixText: '\$ ')),
                    ]),
                    SizedBox(height: 14.h),
                    _buildField('Currency', _currencyCtrl, hint: 'USD'),
                    SizedBox(height: 16.h),

                    // ── Active toggle ────────────────────────────────────────
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: _isActive ? Colors.green : Colors.grey),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Active',
                                    style: TextStyle(
                                        fontSize: 14.sp, fontWeight: FontWeight.w600)),
                                Text('Visible to users during booking',
                                    style: TextStyle(
                                        fontSize: 11.sp, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeColor: accentColor,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // ── Save button ──────────────────────────────────────────
                    ElevatedButton(
                      onPressed: (_isSaving || _isUploadingImage) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        minimumSize: Size(double.infinity, 52.h),
                      ),
                      child: (_isSaving || _isUploadingImage)
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              _isEditing ? 'Update Vehicle' : 'Add Vehicle',
                              style: TextStyle(
                                  fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Image picker widget ────────────────────────────────────────────────────
  Widget _buildImagePicker(Color accentColor) {
    final hasLocal = _pickedImageFile != null;
    final hasRemote =
        (_existingImageUrl ?? '').isNotEmpty && _pickedImageFile == null;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
              color: hasLocal || hasRemote ? accentColor : Colors.grey.shade300,
              width: hasLocal || hasRemote ? 2 : 1.5),
        ),
        child: Stack(
          children: [
            // Image preview
            if (hasLocal)
              ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: Image.file(_pickedImageFile!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover),
              )
            else if (hasRemote)
              ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: Image.network(_existingImageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _pickerPlaceholder(accentColor)),
              )
            else
              _pickerPlaceholder(accentColor),

            // Edit overlay if image already exists
            if (hasLocal || hasRemote)
              Positioned(
                bottom: 10.h,
                right: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 16.w),
                      SizedBox(width: 4.w),
                      Text('Change',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pickerPlaceholder(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 48.w, color: accentColor),
          SizedBox(height: 8.h),
          Text('Tap to choose from gallery',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 4.h),
          Text('JPG, PNG recommended',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Text field builder ─────────────────────────────────────────────────────
  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    String? prefixText,
    bool required = false,
  }) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixText: prefixText,
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      ),
      validator: required
          ? (val) =>
              (val == null || val.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }
}
