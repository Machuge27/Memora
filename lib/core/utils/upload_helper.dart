import 'package:flutter/material.dart';

class UploadHelper {
  static void showUploadError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showUploadSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showUploadProgress(BuildContext context, int current, int total) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text('Uploading... $current/$total files'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'TIMEOUT_ERROR':
        return 'Upload timed out. Please check your internet connection and try again.';
      case 'NETWORK_ERROR':
        return 'Network error. Please check your connection and try again.';
      case 'NO_FILES':
        return 'No files selected for upload.';
      case 'TOO_MANY_FILES':
        return 'Too many files selected. Maximum 20 files allowed.';
      case 'FILE_NOT_FOUND':
        return 'Selected file could not be found.';
      case 'NO_VALID_FILES':
        return 'No valid files found to upload.';
      case 'EMPTY_RESPONSE':
        return 'Server returned an empty response. Please try again.';
      default:
        return 'Upload failed. Please try again.';
    }
  }

  static bool isRetryableError(String errorCode) {
    return [
      'TIMEOUT_ERROR',
      'NETWORK_ERROR',
      'EMPTY_RESPONSE',
    ].contains(errorCode);
  }
}