import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:sortbliss/core/app_export.dart';
import 'package:sortbliss/presentation/gameplay_screen/models/sort_item.dart';

class CentralPileWidget extends StatelessWidget {
  const CentralPileWidget({
    super.key,
    this.items = const <SortItem>[],
    this.showTutorial = false,
  });

  /// Items currently in the central pile.
  final List<SortItem> items;

  /// Whether the tutorial overlay should be visible.
  final bool showTutorial;

  @override
  Widget build(BuildContext context) {
    return _buildCentralPile(context);
  }

  Widget _buildCentralPile(BuildContext context) {
    // Extract opacity values to descriptive variables
    const double shadowOpacity = 0.3;
    const double containerOpacity = 0.8;

    return Container(
      height: 35.h,
      width: 80.w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(containerOpacity),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(shadowOpacity),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (items.isEmpty)
            _buildEmptyPile(context)
          else
            _buildItemPile(context, items),
          if (showTutorial) _buildTutorialOverlay(context),
        ],
      ),
    );
  }

  Widget _buildItemPile(BuildContext context, List<SortItem> items) {
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: EdgeInsets.symmetric(vertical: 0.5.h),
          child: Card(
            elevation: 2,
            child: ListTile(
              leading: CustomIconWidget(
                iconName: item.iconName,
                color: item.color,
                size: 6.w,
              ),
              title: Text(
                item.name,
                style: textTheme.bodyLarge,
              ),
              subtitle: Text(
                'Value: ${item.sortValue}',
                style: textTheme.bodySmall,
              ),
              onTap: item.onTap,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTutorialOverlay(BuildContext context) {
    // Extract opacity values to descriptive variables
    const double tutorialBackgroundOpacity = 0.1;
    const double tutorialContainerOpacity = 0.7;
    const double tutorialBorderOpacity = 0.5;

    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.7,
          colors: [
            Colors.yellow.withOpacity(tutorialBackgroundOpacity),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(tutorialContainerOpacity),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.yellow.withOpacity(tutorialBorderOpacity),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'touch_app',
                color: Colors.yellow,
                size: 8.w,
              ),
              SizedBox(height: 1.h),
              Text(
                'Drag items to sort them!',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPile(BuildContext context) {
    // Extract opacity values to descriptive variables
    const double emptyPileOpacity = 0.6;

    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(emptyPileOpacity),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'inbox',
              color: Colors.grey.shade600,
              size: 12.w,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Central Pile Empty',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Items will appear here during sorting',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
