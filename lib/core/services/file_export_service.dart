import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      final response = await _apiClient.request(
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

      final rawData = response.data;
      if (rawData == null) {
        throw const ServerFailure("محتوای دریافتی از سرور برای خروجی خالی است.");
      }

      final List<int> bytes;
      if (rawData is List<int>) {
        bytes = rawData;
      } else if (rawData is List) {
        bytes = rawData.cast<int>();
      } else {
        throw ServerFailure("فرمت داده‌های دریافتی نامعتبر است: ${rawData.runtimeType}");
      }

      if (bytes.isEmpty) {
        throw const ServerFailure("فایل دریافتی از سرور خالی است.");
      }

      // Determine appropriate directory
      Directory? dir;
      try {
        if (Platform.isAndroid) {
          final downloadDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (downloadDirs != null && downloadDirs.isNotEmpty) {
            dir = downloadDirs.first;
          }
          dir ??= await getExternalStorageDirectory();
          dir ??= await getApplicationDocumentsDirectory();
        } else if (Platform.isWindows) {
          dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
      } catch (dirErr) {
        debugPrint("[FileExportService] Directory resolution fallback: $dirErr");
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
      debugPrint("[FileExportService] Saved ${bytes.length} bytes to: ${file.path}");

      // Open with default system app
      try {
        final openResult = await OpenFilex.open(file.path, type: resolvedMime);
        debugPrint("[FileExportService] OpenFilex result: type=${openResult.type}, message=${openResult.message}");
        if (openResult.type == ResultType.done) {
          return "فایل با موفقیت باز شد.";
        } else if (openResult.type == ResultType.noAppToOpen) {
          return "فایل در مسیر زیر ذخیره شد:\n${file.path}\n(برنامه مناسب برای باز کردن فایل یافت نشد)";
        } else {
          return "فایل با موفقیت در مسیر زیر ذخیره شد:\n${file.path}";
        }
      } catch (openErr) {
        debugPrint("[FileExportService] OpenFilex call error (app re-run required for native plugin): $openErr");
        return "فایل با موفقیت در حافظه دستگاه ذخیره شد:\n${file.path}";
      }
    } catch (e, st) {
      debugPrint("[FileExportService] Export error: $e\n$st");
      if (e is Failure) rethrow;
      throw ServerFailure("خطا در دانلود یا ذخیره فایل گزارش: ${e.toString()}");
    }
  }
}
