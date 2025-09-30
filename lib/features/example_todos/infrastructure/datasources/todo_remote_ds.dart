import 'package:dio/dio.dart';

import 'package:app_management/features/example_todos/infrastructure/models/todo_dto.dart';

class TodoRemoteDataSource {
  TodoRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<TodoDto>> fetchTodos({required int page, CancelToken? cancelToken}) async {
    final response = await _dio.get<List<dynamic>>(
      '/todos',
      queryParameters: <String, dynamic>{'page': page},
      cancelToken: cancelToken,
    );
    final data = response.data ?? <dynamic>[];
    return data.map((dynamic json) => TodoDto.fromJson(Map<String, dynamic>.from(json as Map))).toList();
  }

  Future<TodoDto> addTodo({required String title}) async {
    final response = await _dio.post<Map<String, dynamic>>('/todos', data: <String, dynamic>{'title': title});
    return TodoDto.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<TodoDto> toggleTodo({required String id}) async {
    final response = await _dio.patch<Map<String, dynamic>>('/todos/$id/toggle');
    return TodoDto.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> deleteTodo({required String id}) async {
    await _dio.delete<void>('/todos/$id');
  }
}
