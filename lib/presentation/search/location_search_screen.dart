import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/models/user_models.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<Map<String, String>> _recentPlaces = [];
  List<Map<String, String>> _searchResults = [];
  bool _isLoadingRecent = true;
  bool _isSearching = false;
  Timer? _debounce;
  
  static const Color brandYellow = Color(0xFFDC423D);
  static const String _googleApiKey = "AIzaSyDwTHDeGqgifYZGbYRtMakvOZKnIlpftX8";

  @override
  void initState() {
    super.initState();
    _loadRecentPlaces();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recentJson = prefs.getString('recent_searches');
    if (recentJson != null) {
      final List<dynamic> decoded = jsonDecode(recentJson);
      setState(() {
        _recentPlaces = decoded.map((e) => Map<String, String>.from(e)).toList();
        _isLoadingRecent = false;
      });
    } else {
      setState(() {
        _recentPlaces = [];
        _isLoadingRecent = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
    setState(() {
      _query = query;
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final response = await ref.read(bookingRepositoryProvider).getAutocompleteSuggestions(query, _googleApiKey);
      if (mounted) {
        setState(() {
          _searchResults = response.predictions.map((p) => {
            'title': p.structuredFormatting.mainText,
            'address': p.description,
            'distance': '', // Distance would require another API call per item or user location comparison
          }).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _savePlace(Map<String, String> place) async {
    final prefs = await SharedPreferences.getInstance();
    _recentPlaces.removeWhere((p) => p['title'] == place['title']);
    _recentPlaces.insert(0, place);
    if (_recentPlaces.length > 5) _recentPlaces = _recentPlaces.sublist(0, 5);
    
    await prefs.setString('recent_searches', jsonEncode(_recentPlaces));
    setState(() {});
    context.pop(place);
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => _recentPlaces = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 40.w,
        leading: IconButton(
          padding: EdgeInsets.only(left: 10.w),
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 22.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Search',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Custom Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Container(
              height: 52.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEA),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: brandYellow.withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 18.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'Where would you go?',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: Icon(Icons.close, color: Colors.grey[600], size: 18.sp),
                    ),
                ],
              ),
            ),
          ),

          // 2. Content
          Expanded(
            child: _query.isEmpty
                ? (_isLoadingRecent ? const Center(child: CircularProgressIndicator()) : _buildRecentPlaces())
                : _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? _buildNoResults()
                        : _buildSearchResults(_searchResults),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPlaces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent places',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              GestureDetector(
                onTap: _clearAll,
                child: Text(
                  'Clear All',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: brandYellow),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _recentPlaces.isEmpty 
            ? Center(
                child: Text('No recent places', style: TextStyle(color: Colors.grey[400], fontSize: 14.sp)),
              )
            : ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: _recentPlaces.length,
                separatorBuilder: (context, index) => Divider(color: Colors.grey[100], height: 1),
                itemBuilder: (context, index) {
                  final place = _recentPlaces[index];
                  return InkWell(
                    onTap: () => _savePlace(place),
                    child: _buildPlaceItem(place),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<Map<String, String>> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Row(
            children: [
              Text(
                'Results for ',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
              Text(
                '"$_query"',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: brandYellow),
              ),
              const Spacer(),
              Text(
                '${results.length} found',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: brandYellow),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: results.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey[100], height: 1),
            itemBuilder: (context, index) {
              final place = results[index];
              return InkWell(
                onTap: () => _savePlace(place),
                child: _buildPlaceItem(place, highlight: _query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 50.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Image.network(
              'https://raw.githubusercontent.com/Abdul-Muqaddam/RokiesRoyalRoutes/main/assets/images/no_data.png',
              height: 180.h,
              errorBuilder: (context, error, stack) => Icon(Icons.search_off, size: 80.r, color: Colors.grey[200]),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Not Found',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Text(
              'Sorry, the keyword you entered cannot be found, please check again or search with another keyword',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceItem(Map<String, String> place, {String? highlight}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.access_time, color: Colors.grey[350], size: 18.sp),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHighlightedText(place['title']!, highlight),
                SizedBox(height: 2.h),
                Text(
                  place['address']!,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[400]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          if (place['distance']!.isNotEmpty)
            Text(
              place['distance']!,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String? highlight) {
    if (highlight == null || highlight.isEmpty || !text.toLowerCase().contains(highlight.toLowerCase())) {
      return Text(
        text,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87),
      );
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    int start = 0;
    int indexOfHighlight;

    while ((indexOfHighlight = lowerText.indexOf(lowerHighlight, start)) != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, indexOfHighlight + highlight.length),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ));
      start = indexOfHighlight + highlight.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.normal, color: Colors.black87, fontFamily: 'Outfit'),
        children: spans,
      ),
    );
  }
}


