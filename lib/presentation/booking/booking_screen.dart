import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_models.dart';
import '../widgets/app_dialog.dart';
import 'booking_view_model.dart';
import '../../data/models/booking_settings.dart';
import '../../data/models/booking_models.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../widgets/phone_field.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bookingViewModelProvider, (previous, next) {
      final state = next.value;
      if (state == null) return;

      if (state.bookingStatus?.success == true && !state.requiresPayment) {
        context.go('/booking-success');
      } else if (state.error != null && state.error != previous?.value?.error) {
        AppDialog.show(
          context: context,
          title: 'Booking Error',
          message: state.error!,
        );
      }
    });

    final state = ref.watch(bookingViewModelProvider).value;
    if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final bookingSettings = ref.watch(bookingSettingsProvider);
    // Determine steps dynamically based on the booking type
    final enabledSteps = bookingSettings.steps.where((step) {
      // Step 1: Locations - Removed because we ask on Home screen
      if (step == BookingStep.locations) return false;
      
      // Step 2: Time - Only shown if user chose "Book later"
      if (step == BookingStep.time) return state.pickupTimeType == 'SCHEDULE';
      
      // Step 3: Vehicle - Removed because we ask on AvailableCars/Details
      if (step == BookingStep.vehicle) return false;
      
      // Step 4: Summary - Always shown
      return true;
    }).toList();

    final isLastStep = state.currentStep == enabledSteps.length - 1;

    // Synchronize page controller with state
    if (_pageController.hasClients && _pageController.page?.toInt() != state.currentStep) {
      if (state.currentStep < enabledSteps.length) {
        _pageController.animateToPage(
          state.currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20.sp),
          onPressed: () {
            if (state.currentStep > 0) {
              ref.read(bookingViewModelProvider.notifier).prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          isLastStep ? 'Request for rent' : 'Book a Ride',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!isLastStep) _buildStepIndicator(state.currentStep, enabledSteps),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: enabledSteps.map((step) {
                switch (step) {
                  case BookingStep.locations: return _BookingStep1(state: state);
                  case BookingStep.time: return _BookingStep2(state: state);
                  case BookingStep.vehicle: return _BookingStep3(state: state);
                  case BookingStep.summary: return _BookingStep4(state: state);
                }
              }).toList(),
            ),
          ),
          _buildBottomBar(state, enabledSteps),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep, List<BookingStep> enabledSteps) {
    final titles = enabledSteps.map((step) {
      switch (step) {
        case BookingStep.locations: return 'Where to?';
        case BookingStep.time: return 'Schedule';
        case BookingStep.vehicle: return 'Select Vehicle';
        case BookingStep.summary: return 'Checkout';
      }
    }).toList();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(enabledSteps.length, (index) {
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;
              return Expanded(
                child: Container(
                  height: 6.h,
                  margin: EdgeInsets.only(right: index < enabledSteps.length - 1 ? 12.w : 0),
                  decoration: BoxDecoration(
                    color: (isActive || isCompleted) ? Theme.of(context).colorScheme.secondary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 12.h),
          Text(
            'Step ${currentStep + 1} of ${enabledSteps.length} - ${titles[currentStep]}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BookingState state, List<BookingStep> enabledSteps) {
    if (state.currentStep >= enabledSteps.length) return const SizedBox.shrink();
    
    final currentStepType = enabledSteps[state.currentStep];
    final isLastStep = state.currentStep == enabledSteps.length - 1;

    String buttonText = 'Next Step';
    if (currentStepType == BookingStep.vehicle) buttonText = 'Go to Checkout';
    if (isLastStep) buttonText = 'Confirm Booking';

    bool isEnabled = true;
    if (currentStepType == BookingStep.locations) {
      isEnabled = state.pickupLocation.isNotEmpty && 
                  state.destination.isNotEmpty;
    } else if (currentStepType == BookingStep.vehicle) {
      isEnabled = state.selectedVehicle != null;
    } else if (currentStepType == BookingStep.summary) {
      isEnabled = true;
    }

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: isEnabled ? () async {
            if (!isLastStep) {
              await ref.read(bookingViewModelProvider.notifier).nextStep(enabledSteps.length);
            } else {
              // Perform validation for the last step
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (state.firstName.trim().isEmpty) {
                _showValidationError(context, 'Please enter your name');
                return;
              }
              if (state.email.trim().isEmpty || !emailRegex.hasMatch(state.email.trim())) {
                _showValidationError(context, 'Please enter a valid email address');
                return;
              }
              if (state.phone.trim().isEmpty) {
                _showValidationError(context, 'Please enter your phone number');
                return;
              }
              if (state.paymentMethod.isEmpty) {
                _showValidationError(context, 'Please select a payment method');
                return;
              }
              
              if (state.paymentMethod.toLowerCase().contains('wallet')) {
                final price = double.tryParse(state.selectedVehicle?.price?.toString() ?? '0') ?? 0.0;
                context.push('/wallet-confirmation', extra: {
                  'amount': price,
                  'onConfirm': () {
                    context.pop(); // Close confirmation screen
                    ref.read(bookingViewModelProvider.notifier).createBooking(context: context);
                  }
                });
                return;
              }
              
              ref.read(bookingViewModelProvider.notifier).createBooking(context: context);
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC423D),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
          ),
          child: state.isLoading 
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(buttonText, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }
}

class _BookingStep1 extends ConsumerWidget {
  final BookingState state;
  const _BookingStep1({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(bookingViewModelProvider.notifier);
    final settings = ref.watch(bookingSettingsProvider);
    
    final sections = settings.step1Order.where((s) => settings.step1Visibility[s] ?? true).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map((section) {
          switch (section) {
            case BookingStep1Section.header:
              return Column(
                key: const ValueKey('header'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where are we going?',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 22.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Enter your pickup and destination details',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 14.sp),
                  ),
                  SizedBox(height: 32.h),
                ],
              );
            case BookingStep1Section.locationFields:
              return Column(
                key: const ValueKey('locationFields'),
                children: [
                  _LocationField(
                    label: 'Pickup Location',
                    hint: 'From where?',
                    icon: 'assets/icons/ic_location.svg',
                    value: state.pickupLocation,
                    onChanged: viewModel.updatePickupLocation,
                    suggestions: state.pickupSuggestions,
                    onSuggestionTap: (p) => viewModel.selectSuggestion(p, true),
                  ),
                  GestureDetector(
                    onTap: viewModel.fetchCurrentLocation,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
                    child: Text(
                      'Choose your current location',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    ),
                  ),
                  _LocationField(
                    label: 'Destination',
                    hint: 'To where?',
                    icon: 'assets/icons/ic_location.svg',
                    iconColor: Theme.of(context).colorScheme.secondary,
                    value: state.destination,
                    onChanged: viewModel.updateDestination,
                    suggestions: state.destinationSuggestions,
                    onSuggestionTap: (p) => viewModel.selectSuggestion(p, false),
                  ),
                  if (state.isFlightMode == true) ...[
                    SizedBox(height: 16.h),
                    _buildFlightModeBanner(context, viewModel, state),
                  ],
                  if (state.distance == null) ...[
                    SizedBox(height: 16.h),
                    _buildCalculateButton(context, viewModel, state),
                  ],
                  if (state.error != null && state.isFlightMode != true) ...[
                    SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        state.error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13.sp, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (state.error!.contains('Flight Mode')) ...[
                      SizedBox(height: 12.h),
                      OutlinedButton(
                        onPressed: () => viewModel.setFlightMode(true),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                          minimumSize: Size(double.infinity, 45.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('Switch to Flight Mode', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                  SizedBox(height: 24.h),
                ],
              );
            case BookingStep1Section.recentPlaces:
              return Column(
                key: const ValueKey('recentPlaces'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Recent Destinations',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  ... (state.showAllRecent 
                      ? state.recentDestinations 
                      : state.recentDestinations.take(3)).map((item) => _RecentDestinationCard(
                    item: item,
                    onTap: () => viewModel.selectLocation(item, false),
                  )),
                  if (state.recentDestinations.length > 3)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: viewModel.toggleShowAllRecent,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          state.showAllRecent ? 'Show Less' : 'Show More',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8), 
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                ],
              );
            case BookingStep1Section.savedPlaces:
              return Column(
                key: const ValueKey('savedPlaces'),
                children: [
                    _buildSavedPlacesSection(context, viewModel, state),
                    if (state.savedPlaces.isNotEmpty) SizedBox(height: 32.h),
                ],
              );
            case BookingStep1Section.distanceCard:
              return Column(
                key: const ValueKey('distanceCard'),
                children: [
                  if (state.distance != null) ...[
                    _buildDistanceCard(context, state),
                    SizedBox(height: 24.h),
                  ],
                ],
              );
            case BookingStep1Section.saveLocation:
              return Column(
                key: const ValueKey('saveLocation'),
                children: [
                   _buildSaveLocationSection(context, viewModel, state),
                   SizedBox(height: 32.h),
                ],
              );
            default: return const SizedBox.shrink();
          }
        }).toList(),
      ),
    );
  }

  Widget _buildSavedPlacesSection(BuildContext context, BookingViewModel viewModel, BookingState state) {
    if (state.savedPlaces.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Places',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        ... (state.showAllSavedPlaces 
            ? state.savedPlaces 
            : state.savedPlaces.take(3)).map((item) => _SavedPlaceCard(
          item: item,
          onTap: () => viewModel.selectLocation(item, false),
        )),
        if (state.savedPlaces.length > 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: viewModel.toggleShowAllSavedPlaces,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                state.showAllSavedPlaces ? 'Show Less' : 'Show More',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary, 
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFlightModeBanner(BuildContext context, BookingViewModel viewModel, BookingState state) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/ic_flight.svg', colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn), width: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Flight Mode (Air Distance): Driving route not required.',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13.sp),
            ),
          ),
          IconButton(
            onPressed: () => viewModel.setFlightMode(false),
            icon: Icon(Icons.close, size: 20.sp, color: Theme.of(context).colorScheme.secondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton(BuildContext context, BookingViewModel viewModel, BookingState state) {
    final isEnabled = state.pickupLocation.isNotEmpty && state.destination.isNotEmpty;
    return ElevatedButton(
      onPressed: isEnabled ? viewModel.calculateDistance : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).textTheme.bodyMedium?.color,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/ic_location.svg', colorFilter: ColorFilter.mode(isEnabled ? Theme.of(context).colorScheme.secondary : Colors.grey, BlendMode.srcIn), width: 18.w),
          SizedBox(width: 8.w),
          Text('Calculate Distance', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDistanceCard(BuildContext context, BookingState state) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEA), // Very light red
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(child: _DistanceInfo(label: 'Distance', value: state.distance!)),
          Container(width: 1.w, height: 40.h, color: Colors.grey.withOpacity(0.2)),
          Expanded(child: _DistanceInfo(label: 'Estimated Time', value: state.duration!)),
        ],
      ),
    );
  }

  Widget _buildSaveLocationSection(BuildContext context, BookingViewModel viewModel, BookingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset('assets/icons/ic_location.svg', colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn), width: 14.w),
            SizedBox(width: 8.w),
            Text('Save Pickup Location', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13.sp, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _SaveLocationButton(label: 'Home', icon: 'assets/icons/ic_house.svg', onTap: () => viewModel.saveLocation('Home'))),
            SizedBox(width: 8.w),
            Expanded(child: _SaveLocationButton(label: 'Work', icon: 'assets/icons/ic_location.svg', onTap: () => viewModel.saveLocation('Work'))),
            SizedBox(width: 8.w),
            Expanded(child: _SaveLocationButton(label: 'Custom', icon: 'assets/icons/ic_location.svg', onTap: () => _showCustomLocationDialog(context, viewModel))),
          ],
        ),
        if (state.saveStatus != null) ...[
          SizedBox(height: 8.h),
          Text(state.saveStatus!, style: TextStyle(color: Colors.green, fontSize: 12.sp)),
        ],
      ],
    );
  }

  void _showCustomLocationDialog(BuildContext context, BookingViewModel viewModel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Save Custom Place', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter a name for this location', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. Gym',
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                viewModel.saveLocation(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatefulWidget {
  final String label;
  final String hint;
  final String icon;
  final Color? iconColor;
  final String value;
  final Function(String) onChanged;
  final List<Prediction> suggestions;
  final Function(Prediction) onSuggestionTap;
  final String? errorText;

  const _LocationField({
    required this.label,
    required this.hint,
    required this.icon,
    this.iconColor,
    required this.value,
    required this.onChanged,
    required this.suggestions,
    required this.onSuggestionTap,
    this.errorText,
  });

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  late TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_LocationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
    
    if (oldWidget.suggestions != widget.suggestions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateOverlay();
      });
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _updateOverlay() {
    _hideOverlay();
    if (widget.suggestions.isNotEmpty) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 48.w, // Match SingleChildScrollView padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 56.h), // Position below text field
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12.r),
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), 
                    blurRadius: 10, 
                    offset: const Offset(0, 4)
                  )
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              constraints: BoxConstraints(maxHeight: 250.h),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: widget.suggestions.length,
                itemBuilder: (context, index) {
                  final s = widget.suggestions[index];
                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    title: Text(s.structuredFormatting.mainText, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    subtitle: Text(s.description, style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      widget.onSuggestionTap(s);
                      _hideOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: _controller,
            onChanged: (val) {
              widget.onChanged(val);
              // Ensure overlay updates after the frame to catch the new suggestions
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _updateOverlay();
              });
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
              errorText: widget.errorText,
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.w),
                child: SvgPicture.asset(
                  widget.icon, 
                  width: 20.w,
                  height: 20.w,
                  colorFilter: ColorFilter.mode(widget.iconColor ?? Colors.grey, BlendMode.srcIn)
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class _BookingStep2 extends ConsumerWidget {
  final BookingState state;
  const _BookingStep2({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(bookingViewModelProvider.notifier);
    const Color brandYellow = Color(0xFFDC423D);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(
            'Schedule Ride',
            style: TextStyle(color: Colors.black87, fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'When would you like to be picked up?',
            style: TextStyle(color: Colors.black38, fontSize: 14.sp),
          ),
          SizedBox(height: 32.h),
          
          Text(
            'Select Date',
            style: TextStyle(color: Colors.black87, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _PremiumDateSelector(
            selectedDate: state.selectedDate,
            onDateSelected: viewModel.updateDate,
          ),
          
          SizedBox(height: 32.h),
          Text(
            'Select Time',
            style: TextStyle(color: Colors.black87, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _PremiumTimeGrid(
            selectedTime: state.selectedTime,
            onTimeSelected: viewModel.updateTime,
          ),
          
          SizedBox(height: 24.h),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) viewModel.updateTime(time.format(context));
              },
              icon: Icon(Icons.access_time, color: brandYellow),
              label: Text(
                'Choose custom time',
                style: TextStyle(color: brandYellow, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: 32.h),
          _InfoBox(text: 'Your chauffeur will wait 15 mins for free at no extra charge'),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}

class _PremiumDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _PremiumDateSelector({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // Next 2 weeks
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = date.day == selectedDate.day && date.month == selectedDate.month;
          final dayName = index == 0 ? 'Today' : _getDayName(date.weekday);
          
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 65.w,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDC423D) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: isSelected ? const Color(0xFFDC423D) : Colors.grey[200]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black38,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}

class _PremiumTimeGrid extends StatelessWidget {
  final String selectedTime;
  final Function(String) onTimeSelected;

  const _PremiumTimeGrid({required this.selectedTime, required this.onTimeSelected});

  @override
  Widget build(BuildContext context) {
    final times = ['08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 2.2,
      ),
      itemCount: times.length,
      itemBuilder: (context, index) {
        final time = times[index];
        final isSelected = time == selectedTime;
        return InkWell(
          onTap: () => onTimeSelected(time),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFDC423D) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isSelected ? const Color(0xFFDC423D) : Colors.grey[200]!),
              boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFDC423D).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeTypeButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeTypeButton({required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _DateSelector({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) onDateSelected(date);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary, size: 20),
            SizedBox(width: 12.w),
            Text(
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w600, fontSize: 14.sp),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }
}

class _TimeGrid extends StatelessWidget {
  final String selectedTime;
  final Function(String) onTimeSelected;

  const _TimeGrid({required this.selectedTime, required this.onTimeSelected});

  @override
  Widget build(BuildContext context) {
    final times = ['08:00 AM', '08:30 AM', '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 2.2,
      ),
      itemCount: times.length,
      itemBuilder: (context, index) {
        final time = times[index];
        final isSelected = time == selectedTime;
        return InkWell(
          onTap: () => onTimeSelected(time),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey[50],
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey[200]!),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                color: isSelected ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomTimeButton extends StatelessWidget {
  final String selectedTime;
  final Function(String) onTimeSelected;

  const _CustomTimeButton({required this.selectedTime, required this.onTimeSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            onTimeSelected(time.format(context));
          }
        },
        icon: Icon(Icons.access_time, color: Theme.of(context).colorScheme.secondary, size: 18),
        label: Text(
          'Choose custom time',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary, size: 20),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingStep3 extends ConsumerWidget {
  final BookingState state;
  const _BookingStep3({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(bookingViewModelProvider.notifier);
    final settings = ref.watch(bookingSettingsProvider);
    
    final sections = settings.step3Order.where((s) => settings.step3Visibility[s] ?? true).toList();

    final filteredVehicles = state.vehicleCategory == 'All' 
        ? state.availableVehicles 
        : state.availableVehicles.where((v) => v.category == state.vehicleCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        switch (section) {
          case BookingStep3Section.categoryTabs:
            return Padding(
              key: const ValueKey('categoryTabs'),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Vehicle',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Sedan', 'SUV', 'Van'].map((cat) => Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: CategoryTab(
                          text: cat,
                          isSelected: state.vehicleCategory == cat,
                          onClick: () => viewModel.setVehicleCategory(cat),
                        ),
                      )).toList(),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            );
          case BookingStep3Section.vehicleList:
            return Expanded(
              key: const ValueKey('vehicleList'),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                itemCount: filteredVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = filteredVehicles[index];
                  final isSelected = state.selectedVehicle?.id == vehicle.id;
                  
                  return GestureDetector(
                    onTap: () => viewModel.selectVehicle(vehicle),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.grey[50],
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey[200]!, width: isSelected ? 2 : 1),
                        boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60.w,
                                    height: 50.h,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    padding: EdgeInsets.all(4.w),
                                    child: (vehicle.imageUrl.isEmpty || vehicle.imageUrl == "") 
                                      ? Center(
                                          child: Icon(
                                            Icons.directions_car,
                                            color: Colors.grey.shade400,
                                            size: 24.w,
                                          ),
                                        )
                                      : Image.network(
                                          vehicle.imageUrl, 
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Icon(
                                              Icons.directions_car,
                                              color: Colors.grey.shade400,
                                              size: 24.w,
                                            ),
                                          ),
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 2,
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(right: 24.w),
                                          child: Text(
                                            vehicle.name,
                                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 13.sp),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          vehicle.model,
                                          style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      children: [
                                        _CapacityChip(icon: 'assets/icons/ic_user.svg', text: '${vehicle.passengers} pax'),
                                        SizedBox(width: 8.w),
                                        _CapacityChip(icon: 'assets/icons/ic_location.svg', text: '${vehicle.luggage} bags'),
                                      ],
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${vehicle.currency} ${vehicle.price.toStringAsFixed(0)}',
                                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 16.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            right: 0,
                            top: 4.h,
                            child: Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey[300]!, width: 2),
                              ),
                              child: Center(
                                child: AnimatedScale(
                                  scale: isSelected ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutBack,
                                  child: Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          default: return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}
class _BookingStep4 extends ConsumerStatefulWidget {
  final BookingState state;
  const _BookingStep4({required this.state});

  @override
  ConsumerState<_BookingStep4> createState() => _BookingStep4State();
}

class _BookingStep4State extends ConsumerState<_BookingStep4> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '${widget.state.firstName} ${widget.state.lastName}'.trim());
    _phoneController = TextEditingController(text: widget.state.phone);
    _emailController = TextEditingController(text: widget.state.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);
    final viewModel = ref.read(bookingViewModelProvider.notifier);
    final state = widget.state;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          // Route Timeline
          _buildRouteTimeline(context, state, brandYellow),
          SizedBox(height: 24.h),

          // Mini Vehicle Card
          _buildMiniVehicleCard(context, state, brandYellow),
          SizedBox(height: 24.h),

          // Date & Time
          Row(
            children: [
              Expanded(
                child: _buildInputBox(
                  label: 'Date',
                  value: state.pickupTimeType == 'NOW' ? 'Today' : '${state.selectedDate.day}/${state.selectedDate.month}/${state.selectedDate.year}',
                  icon: Icons.calendar_today_outlined,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: state.selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) viewModel.updateDate(date);
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildInputBox(
                  label: 'Time',
                  value: state.pickupTimeType == 'NOW' ? 'Now' : state.selectedTime,
                  icon: Icons.access_time,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) viewModel.updateTime(time.format(context));
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Passenger Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passenger Details',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              TextButton.icon(
                onPressed: () async {
                  try {
                    // Fetch directly from repository to avoid autoDispose issues
                    final repository = ref.read(userRepositoryProvider);
                    final response = await repository.getUserProfile();
                    
                    if (!response.success || response.user == null) {
                      throw Exception(response.message);
                    }
                    
                    final user = response.user!;
                    final firstName = user.firstName.isNotEmpty ? user.firstName : user.name.split(' ').first;
                    final lastName = user.lastName.isNotEmpty ? user.lastName : (user.name.contains(' ') ? user.name.split(' ').last : '');
                    
                    _nameController.text = '$firstName $lastName'.trim();
                    _phoneController.text = user.phone;
                    _emailController.text = user.email;

                    viewModel.updateCustomerInfo(
                      firstName: firstName,
                      lastName: lastName,
                      phone: user.phone,
                      email: user.email,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      final errorMsg = e.toString().replaceAll('Exception: ', '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMsg.isNotEmpty ? errorMsg : 'Could not fetch account info')),
                      );
                    }
                  }
                },
                icon: Icon(Icons.account_circle, size: 18.sp, color: brandYellow),
                label: Text('Use my account', style: TextStyle(color: brandYellow, fontSize: 14.sp)),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildUserDetailField(
            hint: 'Full Name',
            icon: Icons.person_outline,
            controller: _nameController,
            onChanged: (val) {
              final parts = val.split(' ');
              viewModel.updateCustomerInfo(
                firstName: parts.isNotEmpty ? parts.first : '',
                lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
              );
            },
            brandYellow: brandYellow,
          ),
          SizedBox(height: 12.h),
          AppPhoneField(
            controller: _phoneController,
            onChanged: (val) => viewModel.updateCustomerInfo(phone: val),
          ),
          SizedBox(height: 12.h),
          _buildUserDetailField(
            hint: 'Email Address',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) => viewModel.updateCustomerInfo(email: val),
            brandYellow: brandYellow,
          ),
          SizedBox(height: 24.h),

          // Promo Code
          _buildPromoCodeField(brandYellow),
          SizedBox(height: 32.h),

          // Payment Methods
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select payment method',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                'View All',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: brandYellow),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildPaymentList(context, state, viewModel, brandYellow),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildRouteTimeline(BuildContext context, BookingState state, Color brandYellow) {
    final cleanPickup = cleanLocationName(state.pickupLocation);
    final cleanDest = cleanLocationName(state.destination);

    final pickupTitle = cleanPickup.isEmpty 
        ? 'Current location' 
        : (cleanPickup == 'Current location' ? 'Current location' : cleanPickup.split(',').first);
    final destTitle = cleanDest.isEmpty ? 'Destination' : cleanDest.split(',').first;

    return Column(
      children: [
        _buildTimelineItem(
          icon: Icons.location_on,
          iconColor: Colors.red,
          title: pickupTitle,
          subtitle: cleanPickup.isEmpty ? 'Waiting for location...' : cleanPickup,
          showLine: true,
        ),
        _buildTimelineItem(
          icon: Icons.location_on,
          iconColor: brandYellow,
          title: destTitle,
          subtitle: cleanDest.isEmpty ? 'Waiting for destination...' : cleanDest,
          trailing: state.distance != null 
              ? Text(state.distance!, style: TextStyle(fontSize: 12.sp, color: Colors.black38))
              : null,
          showLine: false,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required bool showLine,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: iconColor, size: 24.sp),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2.w,
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(1.r),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (trailing != null) trailing,
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.sp, color: Colors.black38),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniVehicleCard(BuildContext context, BookingState state, Color brandYellow) {
    final vehicle = state.selectedVehicle;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEA), // Light red background for premium feel
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: brandYellow.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle?.name ?? 'Mustang Shelby GT',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.star, color: brandYellow, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      '4.9',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black45),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '(531 reviews)',
                      style: TextStyle(fontSize: 14.sp, color: Colors.black26),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (vehicle?.imageUrl != null && vehicle!.imageUrl.isNotEmpty)
            Image.network(vehicle.imageUrl, width: 100.w, height: 60.h, fit: BoxFit.contain)
          else
            Icon(Icons.directions_car, size: 60.sp, color: Colors.grey[200]),
        ],
      ),
    );
  }

  Widget _buildInputBox({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value.isEmpty ? label : value, style: TextStyle(fontSize: 14.sp, color: value.isEmpty ? Colors.black26 : Colors.black45)),
            Icon(icon, size: 18.sp, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeField(Color brandYellow) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Enter Promo Code',
        hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black26),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: brandYellow, width: 1.5),
        ),
        suffixIcon: Icon(Icons.copy_rounded, size: 20.sp, color: Colors.black26),
      ),
    );
  }

  Widget _buildUserDetailField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    required Color brandYellow,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black26),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, size: 20.sp, color: Colors.black45),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: brandYellow, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPaymentList(BuildContext context, BookingState state, BookingViewModel viewModel, Color brandYellow) {
    if (state.paymentGateways.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: state.paymentGateways.map((gateway) {
        Widget icon;
        switch (gateway.id.toLowerCase()) {
          case 'stripe':
            icon = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Inc._logo.svg/512px-Visa_Inc._logo.svg.png', 
                  width: 24.w,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.credit_card, size: 20.sp, color: Colors.black26),
                ),
                SizedBox(width: 6.w),
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/512px-Mastercard-logo.svg.png', 
                  width: 24.w,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ],
            );
            break;
          case 'paypal':
            icon = Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/512px-PayPal.svg.png', 
              width: 35.w,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance, size: 20.sp, color: Colors.black26),
            );
            break;
          case 'wallet':
            icon = Icon(Icons.account_balance_wallet_outlined, color: brandYellow, size: 28.sp);
            break;
          case 'cash':
            icon = Icon(Icons.payments_outlined, color: Colors.black45, size: 28.sp);
            break;
          default:
            icon = Icon(Icons.payment, color: Colors.black45, size: 28.sp);
        }

        return _buildPaymentOption(
          id: gateway.id,
          iconWidget: icon,
          title: gateway.title,
          subtitle: gateway.description,
          isSelected: state.paymentMethod == gateway.id,
          onTap: () => viewModel.updateCustomerInfo(paymentMethod: gateway.id),
          brandYellow: brandYellow,
        );
      }).toList(),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    Widget? iconWidget,
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color brandYellow,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isSelected ? brandYellow : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            if (iconWidget != null) 
              Container(
                width: 44.w, 
                height: 44.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: iconWidget,
              ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontSize: 14.sp, 
                      fontWeight: FontWeight.bold, 
                      color: isSelected ? Colors.black87 : Colors.black45
                    )
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle, 
                      style: TextStyle(fontSize: 12.sp, color: Colors.black26),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: brandYellow, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BookingState state;
  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodyMedium?.color,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected Vehicle', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.7), fontSize: 11.sp)),
                    Text(
                      state.selectedVehicle?.name ?? 'N/A', 
                      style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 14.sp, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Cost', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.7), fontSize: 11.sp)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${state.selectedVehicle?.currency} ${state.selectedVehicle?.price.toStringAsFixed(0)}', 
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18.sp, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.2)),
          SizedBox(height: 16.h),
          _SummaryItem(label: 'Pickup', value: cleanLocationName(state.pickupLocation)),
          SizedBox(height: 12.h),
          _SummaryItem(label: 'Destination', value: cleanLocationName(state.destination)),
          SizedBox(height: 12.h),
          _SummaryItem(label: 'Time', value: state.pickupTimeType == 'NOW' ? 'As soon as possible' : '${state.selectedDate.day}/${state.selectedDate.month} @ ${state.selectedTime}'),
        ],
      ),
    );
  }
}

class _DistanceInfo extends StatelessWidget {
  final String label;
  final String value;
  const _DistanceInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label, 
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color, 
            fontSize: 12.sp, 
            fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value, 
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary, 
                fontSize: 20.sp, 
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveLocationButton extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;
  const _SaveLocationButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon, 
              colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn), 
              width: 14.w,
              height: 14.w,
            ),
            SizedBox(width: 4.w),
            Text(
              label == 'Custom' ? '+ Custom' : label, 
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.7), fontSize: 12.sp)),
        Expanded(
          child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class CounterItem extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CounterItem({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CounterButton(icon: Icons.remove, onTap: count > 1 || (label == 'Luggage' && count > 0) ? onDecrement : null),
              Text('$count', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              _CounterButton(icon: Icons.add, onTap: count < maxCount ? onIncrement : null),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: onTap != null ? Theme.of(context).colorScheme.secondary.withOpacity(0.1) : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: onTap != null ? Theme.of(context).colorScheme.secondary : Colors.grey, size: 18),
      ),
    );
  }
}
class _CapacityChip extends StatelessWidget {
  final String icon;
  final String text;
  const _CapacityChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(icon, width: 12.w, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
        SizedBox(width: 4.w),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 11.sp)),
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final String value;
  final Function(String) onChanged;
  final TextInputType? keyboardType;
  final int maxLines;

  const _CustomTextField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12.sp)),
        SizedBox(height: 8.h),
        TextField(
          controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14.sp, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}
class CategoryTab extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onClick;

  const CategoryTab({required this.text, required this.isSelected, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClick,
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RecentDestinationCard extends StatelessWidget {
  final LocationItem item;
  final VoidCallback onTap;

  const _RecentDestinationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final parts = item.address.split(',');
    final title = parts.isNotEmpty ? parts[0].trim() : 'Recent';
    final subtitle = parts.length > 1 ? parts.sublist(1).join(',').trim() : item.address;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: Colors.grey, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  final LocationItem item;
  final VoidCallback onTap;

  const _SavedPlaceCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isHome = item.name.toLowerCase() == 'home';
    final bool isWork = item.name.toLowerCase() == 'work';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[50]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHome ? Icons.home : (isWork ? Icons.work : Icons.location_on),
                color: Theme.of(context).colorScheme.secondary,
                size: 24.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.address.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      item.address,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
