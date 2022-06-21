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

  const FilePickerFromZero({
    required this.onSelected,
    required this.child,
    this.dialogTitle,
    this.allowMultiple = true,
    this.fileType = FileType.any,
    this.allowedExtensions,
    this.focusNode,
    this.enableDragAndDrop = true,
    this.allowDragAndDropInWholeScreen = false,
    Key? key,
  }) : super(key: key);

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
              child: _buildDragAndDrop(context, SizedBox.shrink()),
            ),
          );
          Overlay.of(context)!.insert(overlayEntry!);
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
    Widget result = InkWell(
      child: widget.child,
      focusNode: widget.focusNode,
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          dialogTitle: widget.dialogTitle,
          allowMultiple: true,
          type: widget.fileType,
          allowedExtensions: widget.allowedExtensions,
        );
        if (result != null) {
          widget.onSelected(result.files.map((e) => File(e.path!)).toList());
        }
      },
    );
    if (widget.enableDragAndDrop) {
      result = AnimatedContainer(
        duration: Duration(milliseconds: 250),
        child: result,
        color: _dragging
            ? Theme.of(context).toggleableActiveColor.withOpacity(0.2)
            : Theme.of(context).toggleableActiveColor.withOpacity(0),
      );
      if (!widget.allowDragAndDropInWholeScreen) {
        result = _buildDragAndDrop(context, result);
      }
    }
    return result;
  }

  Widget _buildDragAndDrop(BuildContext context, Widget child) {
    Widget result = DropTarget(
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
          final result = paths.map((e) => File(e)).toList();
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
      return paths.where((e) => _isAccepted(e)).isNotEmpty;
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
