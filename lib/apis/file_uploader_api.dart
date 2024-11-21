import 'package:dio/dio.dart';
import '../app_config.dart';
import '../dio_client.dart';

class FileUploaderApi {
  static final Dio _dio = DioClient.getInstance();

  Future<Response> upload(MultipartFile imageFile) async {
    // FormData to hold the image file
    FormData formData = FormData.fromMap({
      'img': imageFile,
    });
    return await _dio.post('${AppConfig.uploaderBaseUrl}/api/upload',
        data: formData,
        options: Options(
          headers: {
            'Accept': '*/*',
            'Content-Type': 'application/octet-stream',
          },
        ));
  }
}
