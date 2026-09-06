import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../api/api_client.dart';
import '../errors/failures.dart';

final fileExportServiceProvider = Provider<FileExportService>((ref) {
  return FileExportService(ref.watch(apiClientProvider));
});

class FileExportService {
  final ApiClient _apiClient;

  FileExportService(this._apiClient);

  /// Downloads file from [endpoint] with [queryParameters] and opens it with the default OS viewer
  Future<String> exportAndOpenFile({
    required String endpoint,
    required String defaultFileName,
    String? mimeType,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _apiClient.request<List<int>>(
        endpoint,
        method: 'GET',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': '*/*',
          },
        ),
        queryParameters: queryParameters,
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const ServerFailure("محتوای دریافتی از سرور برای خروجی خالی است.");
      }

      // Determine appropriate directory
      Directory? dir;
      try {
        if (Platform.isAndroid) {
          dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        } else if (Platform.isWindows) {
          dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Extract extension
      String extension = '';
      final dotIndex = defaultFileName.lastIndexOf('.');
      if (dotIndex != -1) {
        extension = defaultFileName.substring(dotIndex).toLowerCase();
      }

      // Resolve MIME type if not explicitly provided
      String? resolvedMime = mimeType;
      if (resolvedMime == null) {
        if (extension == '.xlsx') {
          resolvedMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        } else if (extension == '.pdf') {
          resolvedMime = 'application/pdf';
        } else if (extension == '.csv') {
          resolvedMime = 'text/csv';
        }
      }

      // Generate a safe disk filename to prevent URI encoding issues on external viewers
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileTypePrefix = extension == '.pdf' ? 'pdf' : (extension == '.csv' ? 'csv' : 'excel');
      final safeDiskName = 'report_${fileTypePrefix}_$timestamp$extension';
      final file = File('${dir.path}/$safeDiskName');
      await file.writeAsBytes(bytes, flush: true);

      // Open with default system app
      final openResult = await OpenFilex.open(file.path, type: resolvedMime);
      if (openResult.type == ResultType.done) {
        return "فایل با موفقیت در اکسل/پی‌دی‌اف خوان باز شد.";
      } else if (openResult.type == ResultType.noAppToOpen) {
        return "فایل ذخیره شد: ${file.path}\nنرم‌افزار مناسبی برای مشاهده این فرمت در دستگاه یافت نشد.";
      } else {
        return "فایل در مسیر زیر ذخیره شد:\n${file.path}";
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure("خطا در دانلود یا باز کردن فایل خروجی: ${e.toString()}");
    }
  }
}
