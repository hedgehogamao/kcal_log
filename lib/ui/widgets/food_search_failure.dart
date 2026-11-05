import 'package:flutter/material.dart';

import '../../logic/food_search_worker.dart';
import '../../logic/i18n.dart';

class FoodSearchFailureView extends StatelessWidget {
  const FoodSearchFailureView({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_outlined),
          const SizedBox(height: 12),
          Text(
            tr(
              context,
              error is FoodSearchFailure &&
                      (error as FoodSearchFailure).code == 'queryTooLong'
                  ? 'searchTooLong'
                  : 'searchUnavailable',
            ),
            key: const ValueKey('food-search-error'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('food-search-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(tr(context, 'retry')),
          ),
        ],
      ),
    ),
  );
}
