import 'home_settings.dart';
import 'profile_settings.dart';
import 'booking_settings.dart';

class AppConfig {
  final String accentColor; // Hex string (e.g., "DC423D")
  final String primaryColor; // Hex string (e.g., "1E1E1E")
  final String textColor; // Hex string (e.g., "333333")
  final String highlightTextColor; // Hex string (e.g., "1E1E1E")
  
  final HomeSettings homeSettings;
  final ProfileSettings profileSettings;
  final BookingSettings bookingSettings;

  AppConfig({
    required this.accentColor,
    required this.primaryColor,
    required this.textColor,
    required this.highlightTextColor,
    required this.homeSettings,
    required this.profileSettings,
    required this.bookingSettings,
  });

  factory AppConfig.defaultConfig() {
    return AppConfig(
      accentColor: "DC423D",
      primaryColor: "1E1E1E",
      textColor: "333333",
      highlightTextColor: "1E1E1E",
      homeSettings: HomeSettings.defaultSettings(),
      profileSettings: ProfileSettings.defaultSettings(),
      bookingSettings: BookingSettings.defaultSettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accentColor': accentColor,
      'primaryColor': primaryColor,
      'textColor': textColor,
      'highlightTextColor': highlightTextColor,
      'homeSettings': homeSettings.toJson(),
      'profileSettings': profileSettings.toJson(),
      'bookingSettings': bookingSettings.toJson(),
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      accentColor: (json['accentColor']?.toString() == "D4AF37" || json['accentColor'] == null) ? "DC423D" : json['accentColor'].toString(),
      primaryColor: (json['primaryColor']?.toString() == "0D2137" || json['primaryColor'] == null) ? "1E1E1E" : json['primaryColor'].toString(),
      textColor: json['textColor']?.toString() ?? "333333",
      highlightTextColor: (json['highlightTextColor']?.toString() == "001f3f" || json['highlightTextColor'] == null) ? "1E1E1E" : json['highlightTextColor'].toString(),
      homeSettings: json['homeSettings'] != null 
          ? HomeSettings.fromJson(json['homeSettings']) 
          : HomeSettings.defaultSettings(),
      profileSettings: json['profileSettings'] != null 
          ? ProfileSettings.fromJson(json['profileSettings']) 
          : ProfileSettings.defaultSettings(),
      bookingSettings: json['bookingSettings'] != null 
          ? BookingSettings.fromJson(json['bookingSettings']) 
          : BookingSettings.defaultSettings(),
    );
  }

  AppConfig copyWith({
    String? accentColor,
    String? primaryColor,
    String? textColor,
    String? highlightTextColor,
    HomeSettings? homeSettings,
    ProfileSettings? profileSettings,
    BookingSettings? bookingSettings,
  }) {
    return AppConfig(
      accentColor: accentColor ?? this.accentColor,
      primaryColor: primaryColor ?? this.primaryColor,
      textColor: textColor ?? this.textColor,
      highlightTextColor: highlightTextColor ?? this.highlightTextColor,
      homeSettings: homeSettings ?? this.homeSettings,
      profileSettings: profileSettings ?? this.profileSettings,
      bookingSettings: bookingSettings ?? this.bookingSettings,
    );
  }
}
