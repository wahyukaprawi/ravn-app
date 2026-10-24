part of 'employee_directory_cubit.dart';

abstract class EmployeeDirectoryState extends Equatable {
  const EmployeeDirectoryState();

  @override
  List<Object?> get props => [];
}

class EmployeeDirectoryInitial extends EmployeeDirectoryState {}

class EmployeeDirectoryLoading extends EmployeeDirectoryState {}

class EmployeeDirectoryLoaded extends EmployeeDirectoryState {
  final List<EmployeeSummary> employees;
  final String query;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool loadingMore;
  final String? loadMoreError;

  const EmployeeDirectoryLoaded({
    required this.employees,
    required this.query,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.loadingMore = false,
    this.loadMoreError,
  });

  EmployeeDirectoryLoaded copyWith({
    List<EmployeeSummary>? employees,
    String? query,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? loadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return EmployeeDirectoryLoaded(
      employees: employees ?? this.employees,
      query: query ?? this.query,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [
    employees,
    query,
    currentPage,
    lastPage,
    total,
    loadingMore,
    loadMoreError,
  ];
}

class EmployeeDirectoryError extends EmployeeDirectoryState {
  final String message;

  const EmployeeDirectoryError(this.message);

  @override
  List<Object?> get props => [message];
}
