import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../../logic/calc.dart';
import '../../logic/i18n.dart';
import '../../logic/weekly_review.dart';

class WeeklyReviewCard extends StatelessWidget {
  const WeeklyReviewCard({
    super.key,
    required this.review,
    required this.useKj,
  });
  final WeeklyReview review;
  final bool useKj;
  @override
  Widget build(BuildContext context) {
    String energy(double? v) => v == null
        ? tr(context, 'notLogged')
        : '${fmtEnergy(v, useKj)} ${energyUnit(useKj)}';
    return Card(
      key: const ValueKey('weekly-review'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(context, 'weeklyReviewTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${review.currentDates.first} — ${review.currentDates.last}'),
            Text(
              tr(context, 'weeklyReviewCoverage', {
                'n': '${review.currentTotals.length}',
                'missing': '${7 - review.currentTotals.length}',
              }),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'weeklyReviewCurrent', {
                'v': energy(review.currentAverage),
              }),
            ),
            Text(
              '${review.previousDates.first} — ${review.previousDates.last}',
            ),
            Text(
              tr(context, 'weeklyReviewPrevious', {
                'n': '${review.previousTotals.length}',
                'v': energy(review.previousAverage),
              }),
            ),
            if (review.difference != null)
              Text(
                tr(context, 'weeklyReviewDifference', {
                  'v':
                      '${review.difference! > 0
                          ? '+'
                          : review.difference! < 0
                          ? '−'
                          : ''}${energy(review.difference!.abs())}',
                }),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                for (final m in MealType.values)
                  Text(
                    '${mealLabel(context, m)} · ${review.mealDays[m]!.length}/7',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'weeklyReviewCaution'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
