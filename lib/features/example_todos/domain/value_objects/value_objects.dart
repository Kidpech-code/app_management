enum TodoFilter { all, completed, pending }

extension TodoFilterX on TodoFilter {
  bool apply(bool isCompleted) {
    switch (this) {
      case TodoFilter.all:
        return true;
      case TodoFilter.completed:
        return isCompleted;
      case TodoFilter.pending:
        return !isCompleted;
    }
  }
}
