import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/api/api_client.dart';
import 'package:prima_bascol_app/core/api/api_exception.dart';
import 'package:prima_bascol_app/core/errors/failures.dart';
import 'package:prima_bascol_app/core/services/file_export_service.dart';
import 'package:prima_bascol_app/core/storage/secure_storage_service.dart';

class FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'fake_token';
}

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(secureStorage: FakeSecureStorage());

  Response Function(String path, {Map<String, dynamic>? queryParameters, Options? options})? onRequest;

  @override
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (onRequest != null) {
      return onRequest!(path, queryParameters: queryParameters, options: options) as Response<T>;
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: null,
      statusCode: 200,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiClient fakeApiClient;
  late FileExportService service;

  setUp(() {
    fakeApiClient = FakeApiClient();
    service = FileExportService(fakeApiClient);
  });

  group('FileExportService Tests', () {
    test('throws ServerFailure when response data is empty or null', () async {
      fakeApiClient.onRequest = (path, {queryParameters, options}) {
        expect(options?.responseType, ResponseType.bytes);
        return Response<List<int>>(
          requestOptions: RequestOptions(path: path),
          data: <int>[],
          statusCode: 200,
        );
      };

      expect(
        () => service.exportAndOpenFile(
          endpoint: '/export/',
          defaultFileName: 'test.xlsx',
        ),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('rethrows ApiException as ServerFailure with descriptive message', () async {
      fakeApiClient.onRequest = (path, {queryParameters, options}) {
        throw ApiException(message: 'خطای سرور در تولید فایل گزارش');
      };

      expect(
        () => service.exportAndOpenFile(
          endpoint: '/export/',
          defaultFileName: 'test.xlsx',
        ),
        throwsA(isA<ServerFailure>().having(
          (e) => e.message,
          'message',
          contains('خطای سرور در تولید فایل گزارش'),
        )),
      );
    });

    test('passes query parameters and accept headers correctly', () async {
      String? capturedPath;
      Map<String, dynamic>? capturedParams;
      Options? capturedOptions;

      fakeApiClient.onRequest = (path, {queryParameters, options}) {
        capturedPath = path;
        capturedParams = queryParameters;
        capturedOptions = options;
        return Response<List<int>>(
          requestOptions: RequestOptions(path: path),
          data: <int>[1, 2, 3], // non-empty bytes
          statusCode: 200,
        );
      };

      try {
        await service.exportAndOpenFile(
          endpoint: '/reports/tickets/export/xlsx/',
          defaultFileName: 'report.xlsx',
          queryParameters: {'start_date': '1405/01/01', 'status': 'completed'},
        );
      } catch (_) {
        // OpenFilex may not open on test runner environment (headless), but we verify params were passed
      }

      expect(capturedPath, '/reports/tickets/export/xlsx/');
      expect(capturedParams?['start_date'], '1405/01/01');
      expect(capturedParams?['status'], 'completed');
      expect(capturedOptions?.responseType, ResponseType.bytes);
      expect(capturedOptions?.headers?['Accept'], '*/*');
    });
  });
}
