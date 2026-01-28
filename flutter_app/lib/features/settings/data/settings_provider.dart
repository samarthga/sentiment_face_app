import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/expression_type.dart';

const _expressionTypeKey = 'expression_type';

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

/// Notifier for expression type setting.
class ExpressionTypeNotifier extends StateNotifier<ExpressionType> {
  ExpressionTypeNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences _prefs;

  static ExpressionType _loadInitial(SharedPreferences prefs) {
    final saved = prefs.getString(_expressionTypeKey);
    if (saved != null) {
      return ExpressionType.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ExpressionType.faceOnly,
      );
    }
    return ExpressionType.faceOnly;
  }

  void setExpressionType(ExpressionType type) {
    state = type;
    _prefs.setString(_expressionTypeKey, type.name);
  }
}

/// Provider for expression type setting.
final expressionTypeProvider =
    StateNotifierProvider<ExpressionTypeNotifier, ExpressionType>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ExpressionTypeNotifier(prefs);
});
