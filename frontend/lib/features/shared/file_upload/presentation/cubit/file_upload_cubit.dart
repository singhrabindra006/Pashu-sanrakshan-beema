import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/network/api_exceptions.dart';
import '../../../../../core/utils/file_picker_helper.dart';

enum FileUploadStatus { idle, picking, picked, failure }

/// Generic "pick a file, keep it until the form submits" state. Screens own the
/// upload call itself, because the destination endpoint differs.
class FileUploadState extends Equatable {
  const FileUploadState({this.status = FileUploadStatus.idle, this.file, this.message});

  final FileUploadStatus status;
  final PickedFileRef? file;
  final String? message;

  bool get hasFile => file != null;
  bool get isPicking => status == FileUploadStatus.picking;
  String? get path => file?.path;

  @override
  List<Object?> get props => [status, file?.path, message];
}

class FileUploadCubit extends Cubit<FileUploadState> {
  FileUploadCubit({FilePickerHelper? picker})
      : _picker = picker ?? FilePickerHelper(),
        super(const FileUploadState());

  final FilePickerHelper _picker;

  Future<void> pickImage(ImageSource source) async {
    emit(const FileUploadState(status: FileUploadStatus.picking));
    final result = await _picker.pickImage(source: source);
    _apply(result.dataOrNull, result.errorOrNull);
  }

  Future<void> pickEvidence() async {
    emit(const FileUploadState(status: FileUploadStatus.picking));
    final result = await _picker.pickEvidence();
    _apply(result.dataOrNull, result.errorOrNull);
  }

  void clear() => emit(const FileUploadState());

  void _apply(PickedFileRef? file, AppException? error) {
    if (file != null) {
      emit(FileUploadState(status: FileUploadStatus.picked, file: file));
      return;
    }
    // A cancelled picker returns to idle silently.
    if (error is CancelledException) {
      emit(const FileUploadState());
      return;
    }
    emit(FileUploadState(status: FileUploadStatus.failure, message: error?.message));
  }
}
