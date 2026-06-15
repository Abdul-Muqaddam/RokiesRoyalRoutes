import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/user_repository_impl.dart';

part 'wallet_view_model.g.dart';

class WalletState {
  final double availableBalance;
  final double totalExpend;
  final List<WalletTransaction> transactions;
  final bool isLoading;

  WalletState({
    this.availableBalance = 0.0,
    this.totalExpend = 0.0,
    this.transactions = const [],
    this.isLoading = false,
  });

  WalletState copyWith({
    double? availableBalance,
    double? totalExpend,
    List<WalletTransaction>? transactions,
    bool? isLoading,
  }) {
    return WalletState(
      availableBalance: availableBalance ?? this.availableBalance,
      totalExpend: totalExpend ?? this.totalExpend,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class WalletViewModel extends _$WalletViewModel {
  final _supabase = Supabase.instance.client;

  @override
  Future<WalletState> build() async {
    final userProfile = await ref.watch(userProfileProvider.future);
    
    // Total expend is derived from totalSpent string (e.g. "$120.00")
    final cleanSpent = userProfile.totalSpent.replaceAll(RegExp(r'[^0-9.]'), '');
    final totalExpend = double.tryParse(cleanSpent) ?? 0.0;
    
    // Available balance from UserDto
    final availableBalance = userProfile.walletBalance;

    final transactions = await _fetchRecentTransactions();

    return WalletState(
      availableBalance: availableBalance,
      totalExpend: totalExpend,
      transactions: transactions,
      isLoading: false,
    );
  }

  Future<List<WalletTransaction>> _fetchRecentTransactions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(15);

      final List<dynamic> data = response as List;
      final List<WalletTransaction> txs = data.map((b) => WalletTransaction(
        id: b['id'].toString(),
        title: b['title']?.toString() ?? 'Transaction',
        description: b['description']?.toString() ?? '',
        amount: double.tryParse(b['amount']?.toString() ?? '0') ?? 0.0,
        date: DateTime.parse(b['created_at'].toString()),
        isCredit: b['is_credit'] ?? false,
      )).toList();


      return txs;
    } catch (e) {
      print('DEBUG: Error fetching transactions: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userProfile = await ref.read(userProfileProvider.future);
      final cleanSpent = userProfile.totalSpent.replaceAll(RegExp(r'[^0-9.]'), '');
      final totalExpend = double.tryParse(cleanSpent) ?? 0.0;
      final availableBalance = userProfile.walletBalance;
      final transactions = await _fetchRecentTransactions();

      return WalletState(
        availableBalance: availableBalance,
        totalExpend: totalExpend,
        transactions: transactions,
        isLoading: false,
      );
    });
  }
}
