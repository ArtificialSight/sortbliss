import { google } from 'googleapis';
import * as functions from 'firebase-functions';

/**
 * Google Play receipt validation
 *
 * Validates purchases using Google Play Developer API v3
 * Documentation: https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products/get
 */

const androidpublisher = google.androidpublisher('v3');

interface GoogleReceiptValidationResult {
  valid: boolean;
  productId: string;
  transactionId: string;
  purchaseDate: number;
  expirationDate?: number;
  error?: string;
}

/**
 * Validates a Google Play purchase
 *
 * @param purchaseToken - Purchase token from Google Play
 * @param expectedProductId - Expected product ID to validate
 * @returns Validation result with purchase details
 */
export async function validateGoogleReceipt(
  purchaseToken: string,
  expectedProductId: string
): Promise<GoogleReceiptValidationResult> {
  // Package name from android/app/build.gradle
  const PACKAGE_NAME = 'com.sortbliss.app';

  try {
    // TODO: Set up Google Play service account credentials
    // 1. Go to Google Cloud Console > IAM & Admin > Service Accounts
    // 2. Create service account with "Service Account User" role
    // 3. Download JSON key file
    // 4. Run: firebase functions:config:set google.service_account="$(cat service-account-key.json)"
    //
    // OR use Application Default Credentials (recommended for Cloud Functions):
    // The service account is automatically available when deployed to Cloud Functions

    // Authenticate with Google Play Developer API
    const auth = new google.auth.GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const authClient = await auth.getClient();

    // Get purchase details from Google Play
    const response = await androidpublisher.purchases.products.get({
      auth: authClient as any,
      packageName: PACKAGE_NAME,
      productId: expectedProductId,
      token: purchaseToken,
    });

    const purchase = response.data;

    if (!purchase) {
      functions.logger.warn('Google Play purchase not found', {
        productId: expectedProductId,
        purchaseToken,
      });

      return {
        valid: false,
        productId: '',
        transactionId: '',
        purchaseDate: 0,
        error: 'Purchase not found',
      };
    }

    // Check purchase state (0 = purchased, 1 = cancelled, 2 = pending)
    if (purchase.purchaseState !== 0) {
      const stateMap: Record<number, string> = {
        1: 'Purchase was cancelled',
        2: 'Purchase is pending',
      };
      const errorMessage = stateMap[purchase.purchaseState || 0] || 'Invalid purchase state';

      functions.logger.warn('Google Play purchase invalid state', {
        productId: expectedProductId,
        purchaseState: purchase.purchaseState,
      });

      return {
        valid: false,
        productId: expectedProductId,
        transactionId: purchase.orderId || '',
        purchaseDate: 0,
        error: errorMessage,
      };
    }

    // Check consumption state (0 = not consumed, 1 = consumed)
    // For non-consumable purchases, ensure they haven't been consumed yet
    if (purchase.consumptionState === 1) {
      functions.logger.warn('Google Play purchase already consumed', {
        productId: expectedProductId,
        orderId: purchase.orderId,
      });

      // This might be a replay attack - allow it but log the warning
      // The receipt storage in index.ts will prevent duplicate grants
    }

    // Check if purchase was acknowledged
    // Purchases must be acknowledged within 3 days or they're refunded
    if (purchase.acknowledgementState === 0) {
      functions.logger.info('Purchase not yet acknowledged, will acknowledge now', {
        productId: expectedProductId,
        orderId: purchase.orderId,
      });

      // Acknowledge the purchase
      try {
        await androidpublisher.purchases.products.acknowledge({
          auth: authClient as any,
          packageName: PACKAGE_NAME,
          productId: expectedProductId,
          token: purchaseToken,
        });

        functions.logger.info('Purchase acknowledged successfully', {
          productId: expectedProductId,
          orderId: purchase.orderId,
        });
      } catch (ackError: any) {
        functions.logger.error('Failed to acknowledge purchase', {
          productId: expectedProductId,
          error: ackError.message,
        });
        // Continue anyway - purchase is valid even if acknowledgement fails
      }
    }

    // Extract purchase details
    const purchaseDateMs = purchase.purchaseTimeMillis
      ? parseInt(purchase.purchaseTimeMillis, 10)
      : Date.now();

    functions.logger.info('Google Play receipt validated successfully', {
      productId: expectedProductId,
      orderId: purchase.orderId,
    });

    return {
      valid: true,
      productId: expectedProductId,
      transactionId: purchase.orderId || purchaseToken,
      purchaseDate: purchaseDateMs,
    };
  } catch (error: any) {
    // Handle specific Google Play API errors
    if (error.code === 401) {
      functions.logger.error('Google Play API authentication failed', {
        error: error.message,
      });
      return {
        valid: false,
        productId: '',
        transactionId: '',
        purchaseDate: 0,
        error: 'API authentication failed. Check service account configuration.',
      };
    }

    if (error.code === 404) {
      functions.logger.warn('Purchase not found in Google Play', {
        productId: expectedProductId,
        purchaseToken,
      });
      return {
        valid: false,
        productId: '',
        transactionId: '',
        purchaseDate: 0,
        error: 'Purchase not found',
      };
    }

    functions.logger.error('Error validating Google Play receipt', {
      error: error.message,
      stack: error.stack,
    });

    return {
      valid: false,
      productId: '',
      transactionId: '',
      purchaseDate: 0,
      error: error.message,
    };
  }
}

/**
 * Validates a Google Play subscription
 *
 * Similar to product validation but handles subscription-specific fields
 */
export async function validateGoogleSubscription(
  purchaseToken: string,
  subscriptionId: string
): Promise<GoogleReceiptValidationResult> {
  const PACKAGE_NAME = 'com.sortbliss.app';

  try {
    const auth = new google.auth.GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const authClient = await auth.getClient();

    const response = await androidpublisher.purchases.subscriptions.get({
      auth: authClient as any,
      packageName: PACKAGE_NAME,
      subscriptionId: subscriptionId,
      token: purchaseToken,
    });

    const subscription = response.data;

    if (!subscription) {
      return {
        valid: false,
        productId: '',
        transactionId: '',
        purchaseDate: 0,
        error: 'Subscription not found',
      };
    }

    // Check payment state (0 = pending, 1 = received, 2 = free trial, 3 = pending deferred)
    const validPaymentStates = [1, 2]; // Received or free trial
    if (!validPaymentStates.includes(subscription.paymentState || 0)) {
      return {
        valid: false,
        productId: subscriptionId,
        transactionId: subscription.orderId || '',
        purchaseDate: 0,
        error: 'Subscription payment pending or failed',
      };
    }

    // Check expiration
    const expirationMs = subscription.expiryTimeMillis
      ? parseInt(subscription.expiryTimeMillis, 10)
      : 0;

    if (expirationMs && expirationMs < Date.now()) {
      return {
        valid: false,
        productId: subscriptionId,
        transactionId: subscription.orderId || '',
        purchaseDate: parseInt(subscription.startTimeMillis || '0', 10),
        expirationDate: expirationMs,
        error: 'Subscription has expired',
      };
    }

    const purchaseDateMs = parseInt(subscription.startTimeMillis || '0', 10);

    return {
      valid: true,
      productId: subscriptionId,
      transactionId: subscription.orderId || purchaseToken,
      purchaseDate: purchaseDateMs,
      expirationDate: expirationMs,
    };
  } catch (error: any) {
    functions.logger.error('Error validating Google Play subscription', {
      error: error.message,
    });

    return {
      valid: false,
      productId: '',
      transactionId: '',
      purchaseDate: 0,
      error: error.message,
    };
  }
}
