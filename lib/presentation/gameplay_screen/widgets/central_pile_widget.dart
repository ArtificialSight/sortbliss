import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/sort_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/widgets/custom_icon_widget.dart';
import '../gameplay_cubit/gameplay_cubit.dart';

class CentralPileWidget extends StatelessWidget {
  const CentralPileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameplayCubit, GameplayState>(
      builder: (context, state) {
        if (state is GameplayPlaying) {
          return _buildCentralPile(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCentralPile(BuildContext context, GameplayPlaying state) {
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
          if (state.items.isEmpty)
            _buildEmptyPile()
          else
            _buildItemPile(state.items),
          if (state.showTutorial) _buildTutorialOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildItemPile(List<SortItem> items) {
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
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                'Value: ${item.sortValue}',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              onTap: () {
                // Handle item tap
              },
            ),
          ),
        );
      },
    );
  }
  Widget _buildTutorialOverlay() {
    // Extract opacity values to descriptive variables
    const double tutorialBackgroundOpacity = 0.1;
    const double tutorialContainerOpacity = 0.7;
    const double tutorialBorderOpacity = 0.5;
    
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
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
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
  Widget _buildEmptyPile() {
    // Extract opacity values to descriptive variables
    const double emptyPileOpacity = 0.6;
    
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
              color: Colors.grey[600]!,
              size: 12.w,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Central Pile Empty',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Items will appear here during sorting',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
