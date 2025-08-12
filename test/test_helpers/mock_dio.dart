import 'package:dio/dio.dart';

class MockDio implements Dio {
  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) async {
    return Response<T>(
      requestOptions: requestOptions,
      statusCode: 200,
      data: _getMockData(requestOptions.path, requestOptions.method) as T?,
    );
  }

  // Return mock data based on the API endpoint
  dynamic _getMockData(String path, String method) {
    if (path.contains('/notes/latest')) {
      return {
        'successful': true,
        'data': {
          'totalCount': 0,
          'dataList': []
        }
      };
    }
    if (path.contains('/notes/myLatest')) {
      return {
        'successful': true,
        'data': {
          'totalCount': 0,
          'dataList': []
        }
      };
    }
    if (path.contains('/notes/deleted')) {
      return {
        'successful': true,
        'data': {
          'totalCount': 0,
          'dataList': []
        }
      };
    }
    
    // Default response
    return {
      'successful': true,
      'data': {}
    };
  }

  // Use noSuchMethod for all other Dio methods to avoid signature mismatch
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #get || 
        invocation.memberName == #post ||
        invocation.memberName == #put ||
        invocation.memberName == #delete) {
      // Extract path from positional arguments
      final path = invocation.positionalArguments.isNotEmpty 
          ? invocation.positionalArguments[0].toString()
          : '/';
      final method = invocation.memberName.toString().replaceAll('Symbol("', '').replaceAll('")', '');
      
      return Future.value(Response(
        requestOptions: RequestOptions(path: path, method: method.toUpperCase()),
        statusCode: 200,
        data: _getMockData(path, method.toUpperCase()),
      ));
    }
    return super.noSuchMethod(invocation);
  }
}