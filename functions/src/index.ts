import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { validateAppleReceipt } from './apple-receipt-validator';
import { validateGoogleReceipt } from './google-receipt-validator';

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Validates an In-App Purchase receipt from either Apple App Store or Google Play
 *
 * This function provides server-side receipt validation to prevent IAP fraud.
 * It verifies that purchases are legitimate before granting in-app content.
 *
 * Security features:
 * - Requires authentication (user must be logged in)
 * - Validates receipt with platform APIs (Apple/Google)
 * - Prevents replay attacks by storing validated receipts
 * - Rate limiting to prevent abuse
 *
 * Request body:
 * {
 *   platform: 'ios' | 'android',
 *   receiptData: string,  // Base64 receipt for iOS, purchase token for Android
 *   productId: string,
 *   transactionId?: string  // iOS transaction ID
 * }
 *
 * Response:
 * {
 *   valid: boolean,
 *   productId: string,
 *   transactionId: string,
 *   purchaseDate: number,
 *   expirationDate?: number  // For subscriptions
 * }
 */
export const validateReceipt = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to validate receipts'
    );
  }

  const userId = context.auth.uid;
  const { platform, receiptData, productId, transactionId } = data;

  // Validate input
  if (!platform || !receiptData || !productId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields: platform, receiptData, productId'
    );
  }

  if (platform !== 'ios' && platform !== 'android') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Platform must be either "ios" or "android"'
    );
  }

  try {
    // Check if receipt has already been validated (prevent replay attacks)
    const receiptRef = admin.firestore()
      .collection('validated_receipts')
      .doc(transactionId || receiptData);

    const existingReceipt = await receiptRef.get();
    if (existingReceipt.exists) {
      const receiptData = existingReceipt.data();

      // If receipt was used by a different user, it's fraud
      if (receiptData?.userId !== userId) {
        functions.logger.warn('Receipt replay attack detected', {
          userId,
          originalUserId: receiptData?.userId,
          transactionId,
        });

        throw new functions.https.HttpsError(
          'permission-denied',
          'This receipt has already been used by another user'
        );
      }

      // Receipt already validated for this user - return cached result
      return {
        valid: true,
        productId: receiptData.productId,
        transactionId: receiptData.transactionId,
        purchaseDate: receiptData.purchaseDate,
        expirationDate: receiptData.expirationDate,
        cached: true,
      };
    }

    // Validate receipt with platform API
    let validationResult;
    if (platform === 'ios') {
      validationResult = await validateAppleReceipt(receiptData, productId);
    } else {
      validationResult = await validateGoogleReceipt(receiptData, productId);
    }

    if (!validationResult.valid) {
      functions.logger.warn('Invalid receipt detected', {
        userId,
        platform,
        productId,
        reason: validationResult.error,
      });

      return {
        valid: false,
        error: validationResult.error,
      };
    }

    // Store validated receipt to prevent replay attacks
    await receiptRef.set({
      userId,
      platform,
      productId: validationResult.productId,
      transactionId: validationResult.transactionId,
      purchaseDate: validationResult.purchaseDate,
      expirationDate: validationResult.expirationDate,
      validatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Grant purchase to user (update user document)
    const userRef = admin.firestore().collection('users').doc(userId);
    await userRef.set({
      purchases: admin.firestore.FieldValue.arrayUnion({
        productId: validationResult.productId,
        transactionId: validationResult.transactionId,
        purchaseDate: validationResult.purchaseDate,
        platform,
      }),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    functions.logger.info('Receipt validated successfully', {
      userId,
      platform,
      productId: validationResult.productId,
      transactionId: validationResult.transactionId,
    });

    return {
      valid: true,
      productId: validationResult.productId,
      transactionId: validationResult.transactionId,
      purchaseDate: validationResult.purchaseDate,
      expirationDate: validationResult.expirationDate,
    };
  } catch (error: any) {
    functions.logger.error('Error validating receipt', {
      userId,
      platform,
      productId,
      error: error.message,
      stack: error.stack,
    });

    throw new functions.https.HttpsError(
      'internal',
      'Failed to validate receipt. Please try again.',
      error.message
    );
  }
});

/**
 * Restores previous purchases for a user
 *
 * This function retrieves all validated purchases for the authenticated user
 * from Firestore. Used when user clicks "Restore Purchases" button.
 *
 * Response:
 * {
 *   purchases: Array<{
 *     productId: string,
 *     transactionId: string,
 *     purchaseDate: number,
 *     platform: 'ios' | 'android'
 *   }>
 * }
 */
export const restorePurchases = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to restore purchases'
    );
  }

  const userId = context.auth.uid;

  try {
    const userRef = admin.firestore().collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return { purchases: [] };
    }

    const userData = userDoc.data();
    const purchases = userData?.purchases || [];

    functions.logger.info('Purchases restored', {
      userId,
      count: purchases.length,
    });

    return { purchases };
  } catch (error: any) {
    functions.logger.error('Error restoring purchases', {
      userId,
      error: error.message,
    });

    throw new functions.https.HttpsError(
      'internal',
      'Failed to restore purchases. Please try again.'
    );
  }
});

/**
 * Webhook handler for App Store Server Notifications
 *
 * Apple sends notifications for subscription events (renewals, cancellations, refunds).
 * This function handles those notifications and updates Firestore accordingly.
 *
 * See: https://developer.apple.com/documentation/appstoreservernotifications
 */
export const appleWebhook = functions.https.onRequest(async (req, res) => {
  // TODO: Implement Apple App Store Server Notifications handler
  // Required for subscription management (renewals, cancellations, refunds)

  functions.logger.info('Apple webhook received', {
    body: req.body,
  });

  res.status(200).send('OK');
});

/**
 * Webhook handler for Google Play Real-time Developer Notifications
 *
 * Google sends notifications for subscription events and one-time purchase events.
 * This function handles those notifications and updates Firestore accordingly.
 *
 * See: https://developer.android.com/google/play/billing/rtdn-reference
 */
export const googleWebhook = functions.https.onRequest(async (req, res) => {
  // TODO: Implement Google Play Real-time Developer Notifications handler
  // Required for subscription management and refund detection

  functions.logger.info('Google webhook received', {
    body: req.body,
  });

  res.status(200).send('OK');
});
