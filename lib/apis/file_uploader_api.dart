import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../app_config.dart';
import '../dio_client.dart';

class FileUploaderApi {
  static final Dio _dio = DioClient.getInstance();

  Future<Response> upload(XFile image) async {
    // FormData to hold the image file
    FormData formData = FormData.fromMap({
      'img': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    return await _dio.post('${AppConfig.uploaderBaseUrl}/api/upload',
        data: formData,
        options: Options(
          headers: {
            'Accept': '*/*',
            'Content-Type': 'multipart/form-data',
          },
        ));
  }
}
