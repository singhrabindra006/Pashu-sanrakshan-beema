import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../storage/prefs_storage.dart';
import '../storage/secure_storage.dart';
import 'api_exceptions.dart';
import 'api_host.dart';
import 'media_url.dart';
import 'result.dart';

/// Marks a request that has already been retried after a forced token refresh,
/// so a genuinely revoked session cannot loop.
const String _retriedFlag = 'lims_retried';

typedef JsonMap = Map<String, dynamic>;
typedef Decoder<T> = T Function(dynamic data);

/// Single Dio instance shared by every repository.
///
/// Responsibilities:
///  - attach the current Firebase ID token to every request,
///  - refresh the token once and retry on a 401,
///  - unwrap the `{ success, message, data }` envelope,
///  - translate transport/HTTP failures into [AppException]s.
class ApiClient {
  ApiClient({
    Dio? dio,
    FirebaseAuth? firebaseAuth,
    SecureStorage? secureStorage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _secureStorage = secureStorage ?? SecureStorage(),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: ApiHost.baseUrl,
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 30),
               sendTimeout: const Duration(seconds: 60),
               headers: {'Accept': 'application/json'},
               // Non-2xx is handled by the error translator below.
               validateStatus: (status) => status != null && status < 500,
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _idToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final options = error.requestOptions;
          final isUnauthorized = error.response?.statusCode == 401;
          if (isUnauthorized && options.extra[_retriedFlag] != true) {
            final token = await _idToken(forceRefresh: true);
            if (token != null) {
              options.extra[_retriedFlag] = true;
              options.headers['Authorization'] = 'Bearer $token';
              try {
                handler.resolve(await _dio.fetch<dynamic>(options));
                return;
              } catch (_) {
                // Fall through to the original error.
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: false),
      );
    }
  }

  final Dio _dio;
  final FirebaseAuth _firebaseAuth;
  final SecureStorage _secureStorage;

  Dio get dio => _dio;

  /// Probe USB / emulator / last Wi-Fi host and point Dio at the one that answers.
  Future<void> discoverHost(PrefsStorage prefs) async {
    final resolved = await ApiHost.resolve(prefs);
    _dio.options.baseUrl = resolved;
  }

  Future<String?> _idToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return _secureStorage.readIdToken();
    try {
      final token = await user.getIdToken(forceRefresh);
      if (token != null) await _secureStorage.writeIdToken(token);
      return token;
    } on FirebaseAuthException {
      return _secureStorage.readIdToken();
    } catch (_) {
      return _secureStorage.readIdToken();
    }
  }

  /// Headers for widgets that fetch bytes themselves (CachedNetworkImage, PDFs).
  Future<Map<String, String>> authHeaders() async {
    final token = await _idToken();
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  Future<Result<T>> get<T>(
    String path, {
    JsonMap? query,
    required Decoder<T> decoder,
  }) => _send(
    decoder,
    () => _dio.get<dynamic>(path, queryParameters: _clean(query)),
  );

  Future<Result<T>> post<T>(
    String path, {
    Object? body,
    JsonMap? query,
    required Decoder<T> decoder,
  }) => _send(
    decoder,
    () => _dio.post<dynamic>(path, data: body, queryParameters: _clean(query)),
  );

  Future<Result<T>> put<T>(
    String path, {
    Object? body,
    required Decoder<T> decoder,
  }) => _send(decoder, () => _dio.put<dynamic>(path, data: body));

  Future<Result<T>> patch<T>(
    String path, {
    Object? body,
    required Decoder<T> decoder,
  }) => _send(decoder, () => _dio.patch<dynamic>(path, data: body));

  Future<Result<T>> delete<T>(
    String path, {
    Object? body,
    required Decoder<T> decoder,
  }) => _send(decoder, () => _dio.delete<dynamic>(path, data: body));

  /// POST/PUT with an optional file. Used by animal, profile photo and claim
  /// evidence uploads.
  Future<Result<T>> multipart<T>(
    String path, {
    required JsonMap fields,
    String method = 'POST',
    String? filePath,
    String fileField = 'photo',
    required Decoder<T> decoder,
    ProgressCallback? onProgress,
  }) async {
    final form = FormData();
    fields.forEach((key, value) {
      if (value != null) form.fields.add(MapEntry(key, value.toString()));
    });

    if (filePath != null) {
      final file = File(filePath);
      if (!await file.exists()) {
        return Result.failure(
          const RequestException('The selected file no longer exists'),
        );
      }
      form.files.add(
        MapEntry(
          fileField,
          await MultipartFile.fromFile(
            filePath,
            filename: p.basename(filePath),
            contentType: _mediaType(filePath),
          ),
        ),
      );
    }

    return _send(
      decoder,
      () => _dio.request<dynamic>(
        path,
        data: form,
        options: Options(method: method),
        onSendProgress: onProgress,
      ),
    );
  }

  /// Downloads an authenticated file to a local path (PDF viewer, sharing).
  Future<Result<String>> download(
    String url,
    String savePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      await _dio.download(
        resolveMediaUrl(url),
        savePath,
        onReceiveProgress: onProgress,
      );
      return Result.success(savePath);
    } on DioException catch (error) {
      return Result.failure(_translate(error));
    } catch (error) {
      return Result.failure(ServerException(error.toString()));
    }
  }

  Future<Result<T>> _send<T>(
    Decoder<T> decoder,
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final status = response.statusCode ?? 0;
      final body = response.data;

      if (status >= 200 && status < 300) {
        final payload = body is Map<String, dynamic> && body.containsKey('data')
            ? body['data']
            : body;
        return Result.success(decoder(payload));
      }
      return Result.failure(_fromBody(status, body));
    } on DioException catch (error) {
      return Result.failure(_translate(error));
    } catch (error) {
      return Result.failure(ServerException('Unexpected error: $error'));
    }
  }

  AppException _translate(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
          'Cannot reach the LIMS API. Keep the phone on USB debugging, or allow port 4000 in Windows Firewall.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const CancelledException();
      case DioExceptionType.badCertificate:
        return const NetworkException(
          'The server certificate could not be verified.',
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final response = error.response;
        if (response == null) {
          if (error.error is SocketException) return const NetworkException();
          return ServerException(error.message ?? 'Request failed');
        }
        return _fromBody(response.statusCode ?? 500, response.data);
    }
  }

  AppException _fromBody(int status, dynamic body) {
    final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final message = (map['message'] as String?)?.trim();
    final code = map['code'] as String?;

    if (status == 422) {
      return ValidationException(
        message ?? 'Please correct the highlighted fields',
        statusCode: status,
        code: code,
        fieldErrors: _fieldErrors(map['errors']),
      );
    }
    if (status == 401 || status == 403) {
      return AuthException(
        message ?? 'Your session is no longer valid',
        statusCode: status,
        code: code,
      );
    }
    if (status >= 500) {
      return ServerException(
        message ?? 'The server is unavailable. Please try again.',
        statusCode: status,
        code: code,
      );
    }
    return RequestException(
      message ?? 'Request failed',
      statusCode: status,
      code: code,
    );
  }

  Map<String, String>? _fieldErrors(dynamic errors) {
    if (errors is! List) return null;
    final result = <String, String>{};
    for (final entry in errors) {
      if (entry is Map && entry['field'] != null) {
        result[entry['field'].toString()] = entry['message'].toString();
      }
    }
    return result.isEmpty ? null : result;
  }

  JsonMap? _clean(JsonMap? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) cleaned[key] = value;
    });
    return cleaned.isEmpty ? null : cleaned;
  }

  MediaType? _mediaType(String filePath) =>
      switch (p.extension(filePath).toLowerCase()) {
        '.jpg' || '.jpeg' => MediaType('image', 'jpeg'),
        '.png' => MediaType('image', 'png'),
        '.pdf' => MediaType('application', 'pdf'),
        _ => null,
      };
}
