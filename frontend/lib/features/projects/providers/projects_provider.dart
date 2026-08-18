import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/project_model.dart';
import '../../../core/network/api_client.dart';


final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, AsyncValue<List<ProjectModel>>>((ref) {
  return ProjectsNotifier(ref.read(dioProvider));
});

class ProjectsNotifier extends StateNotifier<AsyncValue<List<ProjectModel>>> {
  final Dio _dio;

  ProjectsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchProjects();
  }

  Future<void> fetchProjects({bool includeInactive = true, String? status, String? search}) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'include_inactive': includeInactive,
      };
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/projects',
        queryParameters: queryParams,
      );
      final List data = response.data as List;
      final projects = data.map((json) => ProjectModel.fromJson(json)).toList();
      state = AsyncValue.data(projects);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<bool> createProject(ProjectModel model) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/projects',
        data: model.toJson(),
      );
      await fetchProjects();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> updateProject(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put(
        '${ApiConstants.baseUrl}/projects/$id',
        data: data,
      );
      await fetchProjects();
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> toggleActive(int id, bool currentStatus) async {
    try {
      if (currentStatus) {
        await _dio.delete('${ApiConstants.baseUrl}/projects/$id');
      } else {
        await _dio.post('${ApiConstants.baseUrl}/projects/$id/restore');
      }
      await fetchProjects();
      return true;
    } catch (err) {
      return false;
    }
  }
}
