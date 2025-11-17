import axios from 'axios';
import * as functions from 'firebase-functions';

/**
 * Apple App Store receipt validation
 *
 * Validates receipts with Apple's verifyReceipt API
 * Documentation: https://developer.apple.com/documentation/appstorereceipts/verifyreceipt
 */

// Apple verifyReceipt endpoints
const PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';

// Apple receipt status codes
const STATUS_CODES: Record<number, string> = {
  0: 'Valid receipt',
  21000: 'The App Store could not read the JSON object you provided.',
  21002: 'The data in the receipt-data property was malformed or missing.',
  21003: 'The receipt could not be authenticated.',
  21004: 'The shared secret you provided does not match the shared secret on file.',
  21005: 'The receipt server is not currently available.',
  21006: 'This receipt is valid but the subscription has expired.',
  21007: 'This receipt is from the test environment (sandbox).',
  21008: 'This receipt is from the production environment.',
  21009: 'Internal data access error.',
  21010: 'The user account cannot be found or has been deleted.',
};

interface AppleReceiptValidationResult {
  valid: boolean;
  productId: string;
  transactionId: string;
  purchaseDate: number;
  expirationDate?: number;
  error?: string;
}

/**
 * Validates an Apple App Store receipt
 *
 * @param receiptData - Base64 encoded receipt data
 * @param expectedProductId - Expected product ID to validate against
 * @returns Validation result with purchase details
 */
export async function validateAppleReceipt(
  receiptData: string,
  expectedProductId: string
): Promise<AppleReceiptValidationResult> {
  // TODO: Add your Apple shared secret from App Store Connect
  // Get it from: App Store Connect > My Apps > [Your App] > App Information > App-Specific Shared Secret
  const APPLE_SHARED_SECRET = functions.config().apple?.shared_secret || 'YOUR_APPLE_SHARED_SECRET';

  if (APPLE_SHARED_SECRET === 'YOUR_APPLE_SHARED_SECRET') {
    functions.logger.error('Apple shared secret not configured');
    throw new Error('Apple shared secret not configured. Run: firebase functions:config:set apple.shared_secret="your_secret"');
  }

  try {
    // Try production environment first
    let response = await axios.post(PRODUCTION_URL, {
      'receipt-data': receiptData,
      'password': APPLE_SHARED_SECRET,
      'exclude-old-transactions': true,
    });

    let status = response.data.status;

    // If receipt is from sandbox (status 21007), retry with sandbox URL
    if (status === 21007) {
      functions.logger.info('Receipt is from sandbox, retrying with sandbox URL');
      response = await axios.post(SANDBOX_URL, {
        'receipt-data': receiptData,
        'password': APPLE_SHARED_SECRET,
        'exclude-old-transactions': true,
      });
      status = response.data.status;
    }

    // If receipt is from production but we're in sandbox (status 21008), use production
    if (status === 21008) {
      functions.logger.info('Receipt is from production environment');
      // Already using production URL, response is valid
    }

    // Check if receipt is valid
    if (status !== 0) {
      const errorMessage = STATUS_CODES[status] || `Unknown status code: ${status}`;
      functions.logger.warn('Apple receipt validation failed', {
        status,
        error: errorMessage,
      });

      return {
        valid: false,
        productId: '',
        transactionId: '',
        purchaseDate: 0,
        error: errorMessage,
      };
    }

    // Extract latest receipt info
    const receipt = response.data.receipt;
    const inAppPurchases = receipt.in_app || [];
    const latestReceiptInfo = response.data.latest_receipt_info || [];

    // Combine all purchase info (for subscriptions, latest_receipt_info is used)
    const allPurchases = [...inAppPurchases, ...latestReceiptInfo];

    // Find the purchase matching the expected product ID
    const purchase = allPurchases.find(
      (p: any) => p.product_id === expectedProductId
    );

    if (!purchase) {
      functions.logger.warn('Product ID not found in receipt', {
        expectedProductId,
        foundProducts: allPurchases.map((p: any) => p.product_id),
      });

      return {
        valid: false,
        productId: '',
        transactionId: '',
        purchaseDate: 0,
        error: 'Product ID not found in receipt',
      };
    }

    // Extract purchase details
    const transactionId = purchase.transaction_id || purchase.original_transaction_id;
    const purchaseDateMs = parseInt(purchase.purchase_date_ms, 10);
    const expirationDateMs = purchase.expires_date_ms
      ? parseInt(purchase.expires_date_ms, 10)
      : undefined;

    // Check if subscription has expired (if applicable)
    if (expirationDateMs && expirationDateMs < Date.now()) {
      functions.logger.warn('Subscription has expired', {
        productId: expectedProductId,
        expirationDate: new Date(expirationDateMs).toISOString(),
      });

      return {
        valid: false,
        productId: purchase.product_id,
        transactionId,
        purchaseDate: purchaseDateMs,
        expirationDate: expirationDateMs,
        error: 'Subscription has expired',
      };
    }

    functions.logger.info('Apple receipt validated successfully', {
      productId: purchase.product_id,
      transactionId,
    });

    return {
      valid: true,
      productId: purchase.product_id,
      transactionId,
      purchaseDate: purchaseDateMs,
      expirationDate: expirationDateMs,
    };
  } catch (error: any) {
    functions.logger.error('Error validating Apple receipt', {
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
 * Verifies the signature of an App Store Server Notification
 *
 * Required for webhook security to ensure notifications are from Apple
 * Documentation: https://developer.apple.com/documentation/appstoreservernotifications/receiving_app_store_server_notifications
 */
export function verifyAppleWebhookSignature(
  signedPayload: string,
  signature: string
): boolean {
  // TODO: Implement signature verification using Apple's public key
  // This prevents fake webhook requests from malicious actors
  return true;
}
