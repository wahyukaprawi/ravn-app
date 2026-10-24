import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/datasources/employee_remote_datasource.dart';
import '../../data/models/employee_models.dart';

part 'employee_directory_state.dart';

class EmployeeDirectoryCubit extends Cubit<EmployeeDirectoryState> {
  final EmployeeRemoteDataSource remoteDataSource;

  EmployeeDirectoryCubit(this.remoteDataSource)
    : super(EmployeeDirectoryInitial());

  Future<void> load({String? search}) async {
    final query = search?.trim() ?? _currentQuery;

    try {
      emit(EmployeeDirectoryLoading());
      final page = await remoteDataSource.getEmployees(search: query);

      emit(
        EmployeeDirectoryLoaded(
          employees: page.employees,
          query: query,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
        ),
      );
    } catch (e) {
      emit(EmployeeDirectoryError(apiErrorMessage(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! EmployeeDirectoryLoaded ||
        current.loadingMore ||
        current.currentPage >= current.lastPage) {
      return;
    }

    emit(current.copyWith(loadingMore: true, clearLoadMoreError: true));

    try {
      final page = await remoteDataSource.getEmployees(
        search: current.query,
        page: current.currentPage + 1,
      );
      final existingIds = current.employees.map((item) => item.id).toSet();
      final additions = page.employees
          .where((item) => !existingIds.contains(item.id))
          .toList();

      emit(
        current.copyWith(
          employees: [...current.employees, ...additions],
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          loadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(loadingMore: false, loadMoreError: apiErrorMessage(e)),
      );
    }
  }

  Future<void> search(String query) => load(search: query);

  void clear() => emit(EmployeeDirectoryInitial());

  String get _currentQuery {
    final current = state;
    return current is EmployeeDirectoryLoaded ? current.query : '';
  }
}
