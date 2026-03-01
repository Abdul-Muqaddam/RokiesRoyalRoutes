import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_models.dart';
import 'booking_view_model.dart';
import 'payment_webview.dart';

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
      } else if (state.requiresPayment && state.checkoutUrl != null) {
        final bookingId = state.bookingStatus?.bookingId ?? 0;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebView(
              url: state.checkoutUrl!,
              bookingId: bookingId,
              paymentType: state.paymentType ?? 'stripe',
              onSuccess: (code, bId) {
                Navigator.pop(context); // Close WebView
                if (state.paymentType == 'stripe') {
                  ref.read(bookingViewModelProvider.notifier).onStripeSuccess(code, bId);
                } else {
                  ref.read(bookingViewModelProvider.notifier).onPayPalSuccess(code, bId);
                }
              },
              onCancel: () {
                Navigator.pop(context); // Close WebView
                ref.read(bookingViewModelProvider.notifier).cancelPayment();
              },
            ),
          ),
        );
      } else if (state.error != null && state.error != previous?.value?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
        );
      }
    });

    final state = ref.watch(bookingViewModelProvider).value;
    if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Synchronize page controller with state
    if (_pageController.hasClients && _pageController.page?.toInt() != state.currentStep) {
      _pageController.animateToPage(
        state.currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () {
            if (state.currentStep > 0) {
              ref.read(bookingViewModelProvider.notifier).prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Book a Ride',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(state.currentStep),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _BookingStep1(state: state),
                _BookingStep2(state: state),
                _BookingStep3(state: state),
                _BookingStep4(state: state),
              ],
            ),
          ),
          _buildBottomBar(state),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    final titles = ['Where to?', 'Schedule', 'Select Vehicle', 'Checkout'];
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (index) {
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;
              return Expanded(
                child: Container(
                  height: 6.h,
                  margin: EdgeInsets.only(right: index < 3 ? 12.w : 0),
                  decoration: BoxDecoration(
                    color: (isActive || isCompleted) ? AppColors.gold : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 12.h),
          Text(
            'Step ${currentStep + 1} of 4 - ${titles[currentStep]}',
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

  Widget _buildBottomBar(BookingState state) {
    String buttonText = 'Next Step';
    if (state.currentStep == 2) buttonText = 'Go to Checkout';
    if (state.currentStep == 3) buttonText = 'Confirm Booking';

    bool isEnabled = true;
    if (state.currentStep == 0) {
      isEnabled = state.pickupLocation.isNotEmpty && state.destination.isNotEmpty;
    } else if (state.currentStep == 2) {
      isEnabled = state.selectedVehicle != null;
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
          onPressed: isEnabled ? () {
            if (state.currentStep < 3) {
              ref.read(bookingViewModelProvider.notifier).nextStep();
            } else {
              ref.read(bookingViewModelProvider.notifier).createBooking();
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
          ),
          child: state.isLoading 
            ? const CircularProgressIndicator(color: AppColors.navy)
            : Text(buttonText, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        ),
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
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where are we going?',
            style: TextStyle(color: AppColors.navy, fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter your pickup and destination details',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
          SizedBox(height: 32.h),
          
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
                style: TextStyle(color: AppColors.gold, fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          
          _LocationField(
            label: 'Destination',
            hint: 'To where?',
            icon: 'assets/icons/ic_location.svg',
            iconColor: AppColors.gold,
            value: state.destination,
            onChanged: viewModel.updateDestination,
            suggestions: state.destinationSuggestions,
            onSuggestionTap: (p) => viewModel.selectSuggestion(p, false),
          ),
          
          SizedBox(height: 24.h),
          
          _buildCalculateButton(viewModel, state),
          
          if (state.distance != null) ...[
            SizedBox(height: 24.h),
            _buildDistanceCard(state),
          ] else if (state.error != null) ...[
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                state.error!,
                style: TextStyle(color: Colors.red[700], fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          
          SizedBox(height: 32.h),
          _buildSaveLocationSection(context, viewModel, state),
          
          SizedBox(height: 32.h),
          _buildSavedPlacesSection(viewModel, state),
          
          SizedBox(height: 32.h),
          Text(
            'Recent Destinations',
            style: TextStyle(color: AppColors.navy, fontSize: 16.sp, fontWeight: FontWeight.bold),
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
                    color: AppColors.gold, 
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedPlacesSection(BookingViewModel viewModel, BookingState state) {
    if (state.savedPlaces.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Places',
          style: TextStyle(color: AppColors.navy, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        ...state.savedPlaces.map((item) => _SavedPlaceCard(
          item: item,
          onTap: () => viewModel.selectLocation(item, false),
        )),
      ],
    );
  }

  Widget _buildCalculateButton(BookingViewModel viewModel, BookingState state) {
    final isEnabled = state.pickupLocation.isNotEmpty && state.destination.isNotEmpty;
    return ElevatedButton(
      onPressed: isEnabled ? viewModel.calculateDistance : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/ic_location.svg', colorFilter: ColorFilter.mode(isEnabled ? AppColors.gold : Colors.grey, BlendMode.srcIn), width: 18.w),
          SizedBox(width: 8.w),
          Text('Calculate Distance', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDistanceCard(BookingState state) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E7), // Very light gold
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
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
            SvgPicture.asset('assets/icons/ic_location.svg', colorFilter: ColorFilter.mode(AppColors.gold, BlendMode.srcIn), width: 14.w),
            SizedBox(width: 8.w),
            Text('Save Pickup Location', style: TextStyle(color: AppColors.navy, fontSize: 13.sp, fontWeight: FontWeight.w600)),
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
        title: Text('Save Custom Place', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
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
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                viewModel.saveLocation(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text('Save', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final String hint;
  final String icon;
  final Color? iconColor;
  final String value;
  final Function(String) onChanged;
  final List<Prediction> suggestions;
  final Function(Prediction) onSuggestionTap;

  const _LocationField({
    required this.label,
    required this.hint,
    required this.icon,
    this.iconColor,
    required this.value,
    required this.onChanged,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.navy, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        TextField(
          controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
            prefixIcon: Padding(
              padding: EdgeInsets.all(12.w),
              child: SvgPicture.asset(
                icon, 
                width: 20.w,
                height: 20.w,
                colorFilter: ColorFilter.mode(iconColor ?? Colors.grey, BlendMode.srcIn)
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final s = suggestions[index];
                return ListTile(
                  title: Text(s.structuredFormatting.mainText, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                  subtitle: Text(s.description, style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => onSuggestionTap(s),
                );
              },
            ),
          ),
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

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Time',
            style: TextStyle(color: AppColors.navy, fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _TimeTypeButton(
                  text: 'Now',
                  isSelected: state.pickupTimeType == 'NOW',
                  onTap: () => viewModel.setPickupTimeType('NOW'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _TimeTypeButton(
                  text: 'Schedule',
                  isSelected: state.pickupTimeType == 'SCHEDULE',
                  onTap: () => viewModel.setPickupTimeType('SCHEDULE'),
                ),
              ),
            ],
          ),
          if (state.pickupTimeType == 'SCHEDULE') ...[
            SizedBox(height: 32.h),
            Text(
              'Select Date',
              style: TextStyle(color: AppColors.navy, fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            _DateSelector(
              selectedDate: state.selectedDate,
              onDateSelected: viewModel.selectDate,
            ),
            SizedBox(height: 32.h),
            Text(
              'Select Time',
              style: TextStyle(color: AppColors.navy, fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            _TimeGrid(
              selectedTime: state.selectedTime,
              onTimeSelected: viewModel.selectTime,
            ),
            SizedBox(height: 24.h),
            _CustomTimeButton(
              selectedTime: state.selectedTime,
              onTimeSelected: viewModel.selectTime,
            ),
          ],
          SizedBox(height: 32.h),
          _InfoBox(text: 'Your chauffeur will wait 15 mins for free at no extra charge'),
        ],
      ),
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
          color: isSelected ? AppColors.gold : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isSelected ? AppColors.gold : Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.navy : Colors.grey,
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
            const Icon(Icons.calendar_today, color: AppColors.gold, size: 20),
            SizedBox(width: 12.w),
            Text(
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14.sp),
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
              color: isSelected ? AppColors.gold : Colors.grey[50],
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: isSelected ? AppColors.gold : Colors.grey[200]!),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                color: isSelected ? AppColors.navy : Colors.grey[600],
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
        icon: const Icon(Icons.access_time, color: AppColors.gold, size: 18),
        label: Text(
          'Choose custom time',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14.sp),
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
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
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

    final filteredVehicles = state.vehicleCategory == 'All' 
        ? state.availableVehicles 
        : state.availableVehicles.where((v) => v.category == state.vehicleCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Vehicle',
                style: TextStyle(color: AppColors.navy, fontSize: 18.sp, fontWeight: FontWeight.bold),
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
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
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
                    color: isSelected ? Colors.white : Colors.grey[50], // White when selected for elevation
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: isSelected ? AppColors.gold : Colors.grey[200]!, width: isSelected ? 2 : 1),
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
                                  color: AppColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                padding: EdgeInsets.all(4.w),
                                child: Image.network(vehicle.imageUrl, fit: BoxFit.contain),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 24.w), // Space for radio button
                                      child: Text(
                                        vehicle.name,
                                        style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 13.sp),
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
                                  style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16.sp),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        top: 4.h, // Slight offset for better vertical alignment with first line of text
                        child: Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? AppColors.gold : Colors.grey[300]!, width: 2),
                          ),
                          child: Center(
                            child: AnimatedScale(
                              scale: isSelected ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              child: Container(
                                width: 10.w,
                                height: 10.w,
                                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
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
        ),
      ],
    );
  }
}

class _BookingStep4 extends ConsumerWidget {
  final BookingState state;
  const _BookingStep4({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(bookingViewModelProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(state: state),
          SizedBox(height: 32.h),
          Text(
            'Trip Details',
            style: TextStyle(color: AppColors.navy, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: CounterItem(
                  label: 'Passengers',
                  count: state.passengers,
                  maxCount: state.selectedVehicle?.passengers ?? 4,
                  onIncrement: () => viewModel.updatePassengers(state.passengers + 1),
                  onDecrement: () => viewModel.updatePassengers(state.passengers - 1),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CounterItem(
                  label: 'Luggage',
                  count: state.luggage,
                  maxCount: state.selectedVehicle?.luggage ?? 3,
                  onIncrement: () => viewModel.updateLuggage(state.luggage + 1),
                  onDecrement: () => viewModel.updateLuggage(state.luggage - 1),
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          Text(
            'Personal Details',
            style: TextStyle(color: AppColors.navy, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _CustomTextField(
                  label: 'First Name',
                  hint: 'John',
                  value: state.firstName,
                  onChanged: (v) => viewModel.updateCustomerInfo(firstName: v),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _CustomTextField(
                  label: 'Last Name',
                  hint: 'Doe',
                  value: state.lastName,
                  onChanged: (v) => viewModel.updateCustomerInfo(lastName: v),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _CustomTextField(
            label: 'Email Address',
            hint: 'john.doe@example.com',
            value: state.email,
            onChanged: (v) => viewModel.updateCustomerInfo(email: v),
          ),
          SizedBox(height: 16.h),
          _CustomTextField(
            label: 'Phone Number',
            hint: '+1 234 567 890',
            value: state.phone,
            onChanged: (v) => viewModel.updateCustomerInfo(phone: v),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16.h),
          _CustomTextField(
            label: 'Additional Note',
            hint: 'E.g. Call me when you arrive',
            value: state.additionalNote,
            onChanged: (v) => viewModel.updateCustomerInfo(note: v),
            maxLines: 3,
          ),
          SizedBox(height: 32.h),
          Text(
            'Payment Method',
            style: TextStyle(color: AppColors.navy, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          ...state.paymentGateways.map((g) => RadioListTile<String>(
            title: Text(g.title, style: TextStyle(color: AppColors.navy, fontSize: 14.sp)),
            value: g.id,
            groupValue: state.paymentMethod,
            onChanged: (v) => viewModel.updateCustomerInfo(paymentMethod: v),
            activeColor: AppColors.gold,
            contentPadding: EdgeInsets.zero,
          )),
          SizedBox(height: 32.h),
        ],
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
        color: AppColors.navy,
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
                    Text('Selected Vehicle', style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
                    Text(
                      state.selectedVehicle?.name ?? 'N/A', 
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
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
                  Text('Total Cost', style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${state.selectedVehicle?.currency} ${state.selectedVehicle?.price.toStringAsFixed(0)}', 
                      style: TextStyle(color: AppColors.gold, fontSize: 18.sp, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          const Divider(color: Colors.white24),
          SizedBox(height: 16.h),
          _SummaryItem(label: 'Pickup', value: state.pickupLocation),
          SizedBox(height: 12.h),
          _SummaryItem(label: 'Destination', value: state.destination),
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
            color: AppColors.navy, 
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
                color: AppColors.gold, 
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
              colorFilter: ColorFilter.mode(AppColors.gold, BlendMode.srcIn), 
              width: 14.w,
              height: 14.w,
            ),
            SizedBox(width: 4.w),
            Text(
              label == 'Custom' ? '+ Custom' : label, 
              style: TextStyle(color: AppColors.gold, fontSize: 11.sp, fontWeight: FontWeight.w500),
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
        Text('$label: ', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600)),
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
              Text('$count', style: TextStyle(color: AppColors.navy, fontSize: 16.sp, fontWeight: FontWeight.bold)),
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
          color: onTap != null ? AppColors.gold.withOpacity(0.1) : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: onTap != null ? AppColors.gold : Colors.grey, size: 18),
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
          style: TextStyle(color: AppColors.navy, fontSize: 14.sp, fontWeight: FontWeight.w600),
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
          color: isSelected ? AppColors.navy : Colors.grey[100],
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
                      color: AppColors.navy,
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
                color: AppColors.gold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHome ? Icons.home : (isWork ? Icons.work : Icons.location_on),
                color: AppColors.gold,
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
                      color: AppColors.navy,
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
