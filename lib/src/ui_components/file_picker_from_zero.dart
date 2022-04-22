import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';


class FilePickerFromZero extends StatelessWidget {

  final Widget child;
  final ValueChanged<List<File>> onSelected;
  final String? dialogTitle;
  final bool allowMultiple;
  final FileType fileType;
  final List<String>? allowedExtensions;
  final FocusNode? focusNode;

  const FilePickerFromZero({
    required this.onSelected,
    required this.child,
    this.dialogTitle,
    this.allowMultiple = true,
    this.fileType = FileType.any,
    this.allowedExtensions,
    this.focusNode,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO 2 add drag'n'drop functionality
    return InkWell(
      child: child,
      focusNode: focusNode,
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          dialogTitle: dialogTitle,
          allowMultiple: true,
          type: fileType,
          allowedExtensions: allowedExtensions,
        );
        if (result != null) {
          onSelected(result.files.map((e) => File(e.path!)).toList());
        }
      },
    );
  }

}
