import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';


class FilePickerFromZero extends StatefulWidget {

  final Widget child;
  final ValueChanged<List<File>> onSelected;
  final String? dialogTitle;
  final bool allowMultiple;
  final FileType fileType;
  final List<String>? allowedExtensions;
  final FocusNode? focusNode;
  final bool enableDragAndDrop;
  final bool allowDragAndDropInWholeScreen;
  final bool onlyForDragAndDrop;
  final bool pickDirectory;
  final String? initialDirectory;
  final bool enabled;

  const FilePickerFromZero({
    required this.onSelected,
    required this.child,
    this.dialogTitle,
    this.allowMultiple = true,
    this.pickDirectory = false,
    this.fileType = FileType.any,
    this.allowedExtensions,
    this.focusNode,
    this.enableDragAndDrop = true,
    this.allowDragAndDropInWholeScreen = false,
    this.onlyForDragAndDrop = false,
    this.initialDirectory,
    this.enabled = true,
    super.key,
  });

  @override
  State<FilePickerFromZero> createState() => _FilePickerFromZeroState();

}

class _FilePickerFromZeroState extends State<FilePickerFromZero> {

  bool _dragging = false;
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
    if (widget.allowDragAndDropInWholeScreen) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          overlayEntry = OverlayEntry(
            builder: (context) => Positioned.fill(
              child: _buildDragAndDrop(context, const SizedBox.shrink()),
            ),
          );
          Overlay.of(context).insert(overlayEntry!);
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    overlayEntry?.remove();
  }

  @override
  Widget build(BuildContext context) {
    Widget result;
    if (widget.onlyForDragAndDrop) {
      result = widget.child;
    } else {
      result = InkWell(
        focusNode: widget.focusNode,
        onTap: !widget.enabled ? null : () async {
          final result = await pickFileFromZero(
            dialogTitle: widget.dialogTitle,
            pickDirectory: widget.pickDirectory,
            fileType: widget.fileType,
            allowedExtensions: widget.allowedExtensions,
            initialDirectory: widget.initialDirectory,
          );
          if (result!=null) {
            widget.onSelected(result);
          }
        },
        child: widget.child,
      );
    }
    if (widget.enableDragAndDrop) {
      result = AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: _dragging
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
            : Theme.of(context).colorScheme.secondary.withOpacity(0),
        child: result,
      );
      if (!widget.allowDragAndDropInWholeScreen) {
        result = _buildDragAndDrop(context, result);
      }
    }
    return result;
  }

  Widget _buildDragAndDrop(BuildContext context, Widget child) {
    Widget result = DropTarget(
      enable: widget.enabled,
      onDragEntered: (detail) {
        if (mounted) {
          setState(() {
            _dragging = true;
          });
        }
      },
      onDragExited: (detail) {
        if (mounted) {
          setState(() {
            _dragging = false;
          });
        }
      },
      onDragDone: (detail) {
        if (mounted) {
          final paths = detail.files.map((e) => e.path).toList();
          final result = paths.map(File.new).toList();
          if (_isListAccepted(paths)) {
            widget.onSelected(result);
          }
          setState(() {
            _dragging = false;
          });
        }
      },
      child: child,
    );
    // if (_dragging) {
    //   result = MouseRegion(
    //     cursor: SystemMouseCursors.copy,
    //     child: result,
    //   );
    // }
    return result;
  }

  bool _isListAccepted(List<String> paths) {
    if (!widget.allowMultiple && paths.length>1) {
      return false;
    } else {
      return paths.where(_isAccepted).isNotEmpty;
    }
  }
  bool _isAccepted(String path) {
    bool accepted = true;
    if (accepted && widget.allowedExtensions!=null) {
      final dotIndex = path.lastIndexOf('.')+1;
      if (dotIndex>0 && dotIndex<path.length-1) {
        final extension = path.substring(dotIndex);
        accepted = widget.allowedExtensions!.contains(extension);
      } else {
        accepted = false;
      }
    }
    return accepted;
  }

}



Future<List<File>?> pickFileFromZero({
  String? dialogTitle,
  bool pickDirectory = false,
  bool allowMultiple = false,
  FileType fileType = FileType.any,
  List<String>? allowedExtensions,
  String? initialDirectory,
}) async {
  if (!pickDirectory) {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      allowMultiple: allowMultiple,
      type: fileType,
      allowedExtensions: allowedExtensions,
      initialDirectory: initialDirectory,
      lockParentWindow: true,
    );
    if (result != null) {
      return result.files.map((e) => File(e.path!)).toList();
    }
  } else {
    String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      lockParentWindow: true,
    );
    if (result != null) {
      return [File(result)];
    }
  }
  return null;
}