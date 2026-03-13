import 'package:bearcon_card_app/config.dart';
import 'package:bearcon_card_app/domain/request/locationsend.request.dart';
import 'package:bearcon_card_app/domain/response/locationsend.response.dart';
import 'package:bearcon_card_app/infrastructure/dio_base/dio_interceptor.dart';
import 'package:bearcon_card_app/utils/dio.key.dart';
import 'package:bearcon_card_app/infrastructure/dio_base/notwork_utils.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// คลาส [ThedotService] เป็นเซอร์วิสสำหรับจัดการการยิง API ส่งพิกัดไปยัง Server ของ "The Dot"
/// 
/// **หน้าที่หลัก (Responsibilities):**
/// เป็นศูนย์กลางในการสื่อสาร HTTP POST โดยใช้ไลบรารี `Dio` 
/// ซึ่งออกแบบมาให้เบาและสามารถถูกเรียกใช้ได้ทันทีจากฝั่ง Background Isolate
///
/// **Business Logic (The "Why"):**
/// โค้ดส่วนนี้ถูกออกแบบมาเพื่อรองรับปัญหา "เน็ตหลุดกลางคัน" (Connection Error) 
/// ระหว่างที่รถกำลังวิ่งผ่านจุดอับสัญญาณ โดยมีการยัด `RetryInterceptor` เข้าไป 
/// เพื่อให้เกิดการ Retry ใหม่แบบฉลาด (Smart Delay) ช่วยลด Data Loss ให้ได้มากที่สุด
class ThedotService {
  final Dio _dio;

  ThedotService(this._dio);

  /// สร้าง Instance ของ [ThedotService] พร้อมฝัง Interceptor ทุกอย่างไว้ให้เสร็จสรรพ
  /// 
  /// **Business Logic (The "Why"):**
  /// ใช้ท่า `Factory Method` เพื่อตั้งค่า `BaseOptions` เช่น Timeout ต่างๆ 
  /// และยัด [RetryInterceptor] ให้พร้อมใช้งานทันที ทำให้ไม่ต้องเซตค่าเดิมๆ ซ้ำในโค้ดหลัก
  static ThedotService create({String optionalURL = ""}) {
    final dio = Dio(
      BaseOptions(
        headers: {'Connection': 'close'},
        baseUrl: optionalURL.isNotEmpty
            ? optionalURL
            : ConfigEnvironments.getEnvironments().url ?? "",
        receiveTimeout: Duration(seconds: DioKeys.receiveTimeout),
        connectTimeout: Duration(seconds: DioKeys.connectTimeout),
        sendTimeout: Duration(seconds: DioKeys.sendTimeout),
      ),
    );

    // Add standard interceptors
    dio.interceptors.add(dioHandler());

    // Logging interceptor
    dio.interceptors.add(
      PrettyDioLogger(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
      ),
    );

    // Retry logic
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retries: DioKeys.retries,
        retryEvaluator: (error, attempt) {
          error.requestOptions.extra["retries"] = attempt;
          return error.type == DioExceptionType.connectionError;
        },
        retryDelays: NetworkUtils.generateSmartRetryDelays(DioKeys.retries),
      ),
    );

    return ThedotService(dio);
  }

  /// ส่งข้อมูลพิกัด (Location) ของ Tag ไปยัดลงฐานข้อมูลของ Server
  /// 
  /// **พารามิเตอร์ (Params):**
  /// - [apiKey]: กุญแจ API ปกติจะส่งเป็นค่าคงที่ (Static Key) ผูกติดกับ Header `X-API-KEY`
  /// - [requestBody]: โมเดล [LocationSendRequest] ที่รวบรวมข้อมูล พิกัด, ความเร็ว, UUID, Battery
  /// 
  /// **คืนค่า (Returns):** [LocationSendResponse] หากยิงสำเร็จ 200/201
  /// 
  /// **การจัดการข้อผิดพลาด (Exceptions):**
  /// หากมี Error จากฝั่ง Network จะถูกดักจับและโยน [DioException] กลับไปให้ 
  /// [BackgroundBleController] แจ้งเตือนลง SQLite Logger แทน ไม่ทำให้แอปเด้ง (Crash)
  Future<LocationSendResponse> sendLocation({
    required String apiKey,
    required LocationSendRequest requestBody,
  }) async {
    try {
      final response = await _dio.post(
        "/device/receive",
        data: requestBody.toJson(),
        options: Options(headers: {"X-API-KEY": apiKey}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return LocationSendResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (_) {
      // Errors are handled by dioHandler interceptor
      rethrow;
    }
  }
}
