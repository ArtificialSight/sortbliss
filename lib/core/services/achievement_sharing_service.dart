import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/analytics_logger.dart';

/// Achievement sharing service for viral growth
///
/// Creates beautiful share cards for unlocked achievements
/// Supports:
/// - Image generation with achievement details
/// - Custom templates for different achievement types
/// - Social media optimization (1200x630 for best preview)
/// - Deep link integration for referrals
/// - Analytics tracking
class AchievementSharingService {
  static final AchievementSharingService instance = AchievementSharingService._();
  AchievementSharingService._();

  /// Share an achievement
  Future<bool> shareAchievement({
    required String title,
    required String description,
    required String category,
    required int coinsEarned,
    required String emoji,
    String? referralCode,
  }) async {
    try {
      // Generate share text
      final shareText = _generateShareText(
        title: title,
        description: description,
        coinsEarned: coinsEarned,
        emoji: emoji,
        referralCode: referralCode,
      );

      // Share with system dialog
      final result = await Share.share(
        shareText,
        subject: 'Achievement Unlocked in SortBliss! $emoji',
      );

      // Track analytics
      AnalyticsLogger.logEvent('achievement_shared', parameters: {
        'title': title,
        'category': category,
        'coins': coinsEarned,
        'has_referral_code': referralCode != null,
        'share_result': result.status.toString(),
      });

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('❌ Error sharing achievement: $e');
      return false;
    }
  }

  /// Generate share card image for achievement
  Future<File?> generateShareCardImage({
    required String title,
    required String description,
    required String emoji,
    required int coinsEarned,
    required Color accentColor,
  }) async {
    try {
      // Create a custom painter for the share card
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1200, 630); // Optimal for social media

      // Draw background
      final bgPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, size.height),
          [accentColor.withOpacity(0.9), accentColor.withOpacity(0.6)],
        );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        bgPaint,
      );

      // Draw decorative elements
      _drawDecorativeElements(canvas, size, accentColor);

      // Draw achievement card
      final cardRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 1000,
        height: 450,
      );

      final cardPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final cardShadow = Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          cardRect.shift(const Offset(0, 10)),
          const Radius.circular(30),
        ),
        cardShadow,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(30)),
        cardPaint,
      );

      // Draw emoji
      final emojiPainter = TextPainter(
        text: TextSpan(
          text: emoji,
          style: const TextStyle(fontSize: 120),
        ),
        textDirection: TextDirection.ltr,
      );
      emojiPainter.layout();
      emojiPainter.paint(
        canvas,
        Offset(
          (size.width - emojiPainter.width) / 2,
          cardRect.top + 60,
        ),
      );

      // Draw title
      final titlePainter = TextPainter(
        text: TextSpan(
          text: title,
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      );
      titlePainter.layout(maxWidth: 900);
      titlePainter.paint(
        canvas,
        Offset(
          (size.width - titlePainter.width) / 2,
          cardRect.top + 210,
        ),
      );

      // Draw description
      final descPainter = TextPainter(
        text: TextSpan(
          text: description,
          style: const TextStyle(
            fontSize: 32,
            color: Colors.black87,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      );
      descPainter.layout(maxWidth: 900);
      descPainter.paint(
        canvas,
        Offset(
          (size.width - descPainter.width) / 2,
          cardRect.top + 320,
        ),
      );

      // Draw coins badge
      final coinBadgeRect = Rect.fromCenter(
        center: Offset(size.width / 2, cardRect.bottom - 60),
        width: 200,
        height: 60,
      );

      final coinPaint = Paint()
        ..shader = ui.Gradient.linear(
          coinBadgeRect.topLeft,
          coinBadgeRect.bottomRight,
          [Colors.amber.shade400, Colors.orange.shade600],
        );

      canvas.drawRRect(
        RRect.fromRectAndRadius(coinBadgeRect, const Radius.circular(30)),
        coinPaint,
      );

      final coinText = TextPainter(
        text: TextSpan(
          text: '+$coinsEarned 💰',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      coinText.layout();
      coinText.paint(
        canvas,
        Offset(
          coinBadgeRect.center.dx - coinText.width / 2,
          coinBadgeRect.center.dy - coinText.height / 2,
        ),
      );

      // Draw footer
      final footerPainter = TextPainter(
        text: const TextSpan(
          text: 'Play SortBliss • Download Now!',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      footerPainter.layout();
      footerPainter.paint(
        canvas,
        Offset(
          (size.width - footerPainter.width) / 2,
          size.height - 60,
        ),
      );

      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/achievement_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      debugPrint('❌ Error generating share card: $e');
      return null;
    }
  }

  /// Draw decorative elements on canvas
  void _drawDecorativeElements(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw circles
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.3), 60, paint);

    // Draw stars
    _drawStar(canvas, Offset(size.width * 0.15, size.height * 0.7), 40, paint);
    _drawStar(canvas, Offset(size.width * 0.8, size.height * 0.15), 50, paint);
  }

  /// Draw a star shape
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final angle = (3.14159 * 2) / points;

    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? size : size / 2;
      final x = center.dx + r * Math.cos(i * angle / 2 - 3.14159 / 2);
      final y = center.dy + r * Math.sin(i * angle / 2 - 3.14159 / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Share achievement with custom image
  Future<bool> shareAchievementWithImage({
    required String title,
    required String description,
    required String category,
    required int coinsEarned,
    required String emoji,
    required Color accentColor,
    String? referralCode,
  }) async {
    try {
      // Generate image
      final imageFile = await generateShareCardImage(
        title: title,
        description: description,
        emoji: emoji,
        coinsEarned: coinsEarned,
        accentColor: accentColor,
      );

      if (imageFile == null) {
        // Fallback to text-only sharing
        return await shareAchievement(
          title: title,
          description: description,
          category: category,
          coinsEarned: coinsEarned,
          emoji: emoji,
          referralCode: referralCode,
        );
      }

      // Generate share text
      final shareText = _generateShareText(
        title: title,
        description: description,
        coinsEarned: coinsEarned,
        emoji: emoji,
        referralCode: referralCode,
      );

      // Share with image
      final result = await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: shareText,
        subject: 'Achievement Unlocked! $emoji',
      );

      // Clean up temporary file
      try {
        await imageFile.delete();
      } catch (e) {
        debugPrint('⚠️ Could not delete temp file: $e');
      }

      // Track analytics
      AnalyticsLogger.logEvent('achievement_shared_with_image', parameters: {
        'title': title,
        'category': category,
        'coins': coinsEarned,
        'has_referral_code': referralCode != null,
        'share_result': result.status.toString(),
      });

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('❌ Error sharing achievement with image: $e');
      return false;
    }
  }

  /// Generate share text
  String _generateShareText({
    required String title,
    required String description,
    required int coinsEarned,
    required String emoji,
    String? referralCode,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('$emoji Achievement Unlocked!');
    buffer.writeln();
    buffer.writeln('$title');
    buffer.writeln(description);
    buffer.writeln();
    buffer.writeln('Reward: +$coinsEarned coins 💰');
    buffer.writeln();
    buffer.writeln('Play SortBliss - The Ultimate Puzzle Challenge!');

    if (referralCode != null) {
      buffer.writeln();
      buffer.writeln('Use my code for bonus coins: $referralCode');
      buffer.writeln('Download: https://sortbliss.com/referral?code=$referralCode');
    } else {
      buffer.writeln('Download now: https://sortbliss.com');
    }

    return buffer.toString();
  }

  /// Get share template for achievement type
  AchievementShareTemplate getTemplateForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'mastery':
        return AchievementShareTemplate(
          backgroundColor: Colors.purple,
          iconColor: Colors.white,
          accentColor: Colors.amber,
        );
      case 'speed':
        return AchievementShareTemplate(
          backgroundColor: Colors.orange,
          iconColor: Colors.white,
          accentColor: Colors.red,
        );
      case 'efficiency':
        return AchievementShareTemplate(
          backgroundColor: Colors.green,
          iconColor: Colors.white,
          accentColor: Colors.lightGreen,
        );
      case 'streak':
        return AchievementShareTemplate(
          backgroundColor: Colors.blue,
          iconColor: Colors.white,
          accentColor: Colors.cyan,
        );
      case 'collection':
        return AchievementShareTemplate(
          backgroundColor: Colors.pink,
          iconColor: Colors.white,
          accentColor: Colors.pinkAccent,
        );
      default:
        return AchievementShareTemplate(
          backgroundColor: Colors.indigo,
          iconColor: Colors.white,
          accentColor: Colors.indigoAccent,
        );
    }
  }
}

/// Achievement share template
class AchievementShareTemplate {
  final Color backgroundColor;
  final Color iconColor;
  final Color accentColor;

  AchievementShareTemplate({
    required this.backgroundColor,
    required this.iconColor,
    required this.accentColor,
  });
}

/// Simple math helper
class Math {
  static double cos(double radians) => ui.math.cos(radians);
  static double sin(double radians) => ui.math.sin(radians);
}
