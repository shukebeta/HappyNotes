import 'package:HappyNotes/helpers.dart';

class ApiResponse<T> extends GenericObject<T> implements Decodable<ApiResponse<T>>{
  T? data;
  bool successful;
  int errorCode;
  String message;

  ApiResponse({required Create<Decodable> create, required this.successful, required this.errorCode, required this.message}): super(create: create);

  @override
  ApiResponse<T> decode(dynamic json) {
    successful = json['successful'];
    errorCode = json['errorCode'];
    message = json['message'];
    data = genericObject(json['data']);
    return this;
  }

}