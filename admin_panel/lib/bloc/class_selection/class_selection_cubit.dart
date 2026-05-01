import 'package:flutter_bloc/flutter_bloc.dart';

class ClassSelectionCubit extends Cubit<String?> {
  ClassSelectionCubit() : super(null);

  void selectClass(String classId) => emit(classId);
  void clearSelection() => emit(null);
}
