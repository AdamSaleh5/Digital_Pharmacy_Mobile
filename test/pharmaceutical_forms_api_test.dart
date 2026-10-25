import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'anonymous form lookup follows every page using the selected drug ID',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://144.91.111.63:5002'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              requests.add(request);
              final page = request.queryParameters['PageNumber'] as int;
              handler.resolve(
                Response(
                  requestOptions: request,
                  statusCode: 200,
                  data: {
                    'status': 200,
                    'data': {
                      'data': [
                        {
                          'id': 170 + page,
                          'tradeName': 'Synthetic product',
                          'scientificName': 'Synthetic ingredient',
                          'pharmaceuticalForm': 'Synthetic form $page',
                          'price': page == 1 ? 0 : 2.5,
                        },
                      ],
                      'meta': {
                        'pageNumber': page,
                        'totalPages': 2,
                        'totalCount': 2,
                        'hasPreviousPage': page > 1,
                        'hasNextPage': page < 2,
                      },
                    },
                  },
                ),
              );
            },
          ),
        );
      addTearDown(dio.close);
      final api = ApiService(client: ApiTransport(dio: dio));
      final forms = await api.fetchPharmaceuticalForms(id: 17);
      expect(forms.map((form) => form.price), [0, 2.5]);
      expect(requests, hasLength(2));
      for (var index = 0; index < requests.length; index++) {
        expect(requests[index].path, '/api/GetPharmaceuticalForm');
        expect(requests[index].queryParameters, {
          'id': 17,
          'PageNumber': index + 1,
          'PageSize': 100,
        });
        expect(requests[index].headers['Authorization'], isNull);
      }
    },
  );
}
