import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/comparable_list.dart';


enum ValidationErrorSeverity {
  warning,
  unfinished,
  nonBlockingError,
  error,
  disabling,
  invalidating,
}
Map<ValidationErrorSeverity, int> validationErrorSeverityWeights = {
  ValidationErrorSeverity.invalidating: 0,
  ValidationErrorSeverity.error: 10,
  ValidationErrorSeverity.nonBlockingError: 100,
  ValidationErrorSeverity.warning: 1000,
  ValidationErrorSeverity.unfinished: 10000,
  ValidationErrorSeverity.disabling: 100000,
};
extension SeverityWeight on ValidationErrorSeverity {
  int get weight => validationErrorSeverityWeights[this]!;
}


class ValidationError {
  Field field;
  ValidationErrorSeverity severity;
  String error;
  AnimationController? animationController;
  final bool? _isVisibleAsSaveConfirmation;
  bool get isVisibleAsSaveConfirmation => _isVisibleAsSaveConfirmation ?? severity!=ValidationErrorSeverity.disabling;
  final bool? _isVisibleAsHintMessage;
  bool get isVisibleAsHintMessage => _isVisibleAsHintMessage ?? severity!=ValidationErrorSeverity.disabling && severity!=ValidationErrorSeverity.unfinished;
  final bool? _isVisibleAsTooltip;
  bool get isVisibleAsTooltip => _isVisibleAsTooltip ?? severity==ValidationErrorSeverity.disabling;
  ValidationError({
    required this.field,
    required this.error,
    this.severity=ValidationErrorSeverity.error,
    bool? isVisibleAsSaveConfirmation,
    bool? isVisibleAsHintMessage,
    bool? isVisibleAsTooltip,
  })  : _isVisibleAsSaveConfirmation = isVisibleAsSaveConfirmation,
        _isVisibleAsHintMessage = isVisibleAsHintMessage,
        _isVisibleAsTooltip = isVisibleAsTooltip;

  @override
  String toString() => error;
  bool get isBlocking => severity==ValidationErrorSeverity.error || severity==ValidationErrorSeverity.invalidating;
  bool get isBeforeEditing => severity==ValidationErrorSeverity.disabling || severity==ValidationErrorSeverity.invalidating;

  ValidationError copyWith({
    String? error,
    bool? isVisibleAsSaveConfirmation,
    bool? isVisibleAsHintMessage,
    bool? isVisibleAsTooltip,
  }) {
    return ValidationError(
      field: field,
      severity: severity,
      error: error ?? this.error,
      isVisibleAsSaveConfirmation: isVisibleAsSaveConfirmation ?? this.isVisibleAsSaveConfirmation,
      isVisibleAsHintMessage: isVisibleAsHintMessage ?? this.isVisibleAsHintMessage,
      isVisibleAsTooltip: isVisibleAsTooltip ?? this.isVisibleAsTooltip,
    )..animationController=animationController;
  }
}

class InvalidatingError<T extends Comparable> extends ValidationError {
  T? defaultValue;
  bool showVisualConfirmation;
  bool allowUndoInvalidatingChange;
  bool allowSetThisFieldToDefaultValue;
  bool setAsDbValue;
  InvalidatingError({
    required Field<T> super.field,
    required super.error,
    this.defaultValue,
    this.showVisualConfirmation = false,
    this.allowUndoInvalidatingChange = true,
    this.allowSetThisFieldToDefaultValue = true,
    this.setAsDbValue = false,
    super.isVisibleAsSaveConfirmation,
    super.isVisibleAsHintMessage,
    super.isVisibleAsTooltip,
  })  : assert(showVisualConfirmation || allowUndoInvalidatingChange),
        super(
          severity: ValidationErrorSeverity.invalidating,
        );

  @override
  InvalidatingError<T> copyWith({
    String? error,
    bool? isVisibleAsSaveConfirmation,
    bool? isVisibleAsHintMessage,
    bool? isVisibleAsTooltip,
  }) {
    return InvalidatingError<T>(
      field: field as Field<T>,
      error: error ?? this.error,
      defaultValue: this.defaultValue,
      showVisualConfirmation: this.showVisualConfirmation,
      allowSetThisFieldToDefaultValue: this.allowSetThisFieldToDefaultValue,
      allowUndoInvalidatingChange: this.allowUndoInvalidatingChange,
      isVisibleAsSaveConfirmation: isVisibleAsSaveConfirmation ?? this.isVisibleAsSaveConfirmation,
      isVisibleAsHintMessage: isVisibleAsHintMessage ?? this.isVisibleAsHintMessage,
      isVisibleAsTooltip: isVisibleAsTooltip ?? this.isVisibleAsTooltip,
    )..animationController=animationController;
  }
}

class ForcedValueError<T extends Comparable> extends InvalidatingError<T> {
  bool Function(T? value, T? defaultValue)? comparator;
  ForcedValueError({
    required Field<T> field,
    required T? defaultValue,
    required super.error,
    super.showVisualConfirmation,
    super.isVisibleAsSaveConfirmation,
    super.isVisibleAsHintMessage,
    super.isVisibleAsTooltip,
    this.comparator,
  })  : super(
          field: field,
          defaultValue: defaultValue,
          allowSetThisFieldToDefaultValue: true,
          allowUndoInvalidatingChange: true,
        ) {
    severity = (comparator?.call(field.value, defaultValue) ?? field.value==defaultValue)
        ? ValidationErrorSeverity.disabling
        : ValidationErrorSeverity.invalidating;
  }

  @override
  ForcedValueError<T> copyWith({
    String? error,
    bool? isVisibleAsSaveConfirmation,
    bool? isVisibleAsHintMessage,
    bool? isVisibleAsTooltip,
    bool Function(T? value, T? defaultValue)? comparator,
  }) {
    return ForcedValueError<T>(
      field: field as Field<T>,
      error: error ?? this.error,
      defaultValue: defaultValue,
      showVisualConfirmation: showVisualConfirmation,
      isVisibleAsSaveConfirmation: isVisibleAsSaveConfirmation ?? this.isVisibleAsSaveConfirmation,
      isVisibleAsHintMessage: isVisibleAsHintMessage ?? this.isVisibleAsHintMessage,
      isVisibleAsTooltip: isVisibleAsTooltip ?? this.isVisibleAsTooltip,
      comparator: comparator ?? this.comparator,
    )..animationController=animationController;
  }
}



ValidationError? fieldValidatorRequired<T extends Comparable>(BuildContext context, DAO dao, Field<T> field, {
  String? errorMessage,
  ValidationErrorSeverity severity = ValidationErrorSeverity.error,
}) {
  return field.value==null||field.value!.toString().trim().isEmpty
      ? ValidationError(
          field: field,
          error: errorMessage ?? ('${field.uiName} ${FromZeroLocalizations.of(context).translate("validation_error_required")}'),
          severity: severity,
        )
      : null;
}

ValidationError? fieldValidatorListNotEmpty<T extends Comparable>(BuildContext context, DAO dao, Field<T> field, {
  String? errorMessage,
  ValidationErrorSeverity severity = ValidationErrorSeverity.error,
}) {
  return field is ListField && (field.value! as ComparableList).list.isEmpty
      ? ValidationError(
          field: field,
          error: errorMessage ?? 'At least one ${(field as ListField).objectTemplate.classUiName} required', // TODO 3 internationalize
          severity: severity,
        )
      : null;
}

ValidationError? fieldValidatorNumberNotNegative(BuildContext context, DAO dao, Field<num> field, {
  String? errorMessage,
  ValidationErrorSeverity severity = ValidationErrorSeverity.error,
}) {
  return field.value==null
      ? null
      : field.value!<0
          ? ValidationError(
            field: field,
            error: errorMessage ?? ('${field.uiName} ${FromZeroLocalizations.of(context).translate("validation_error_not_negative")}'),
            severity: severity,
          )
          : null;
}

ValidationError? fieldValidatorNumberNotZero(BuildContext context, DAO dao, Field<num> field, {
  String? errorMessage,
  ValidationErrorSeverity severity = ValidationErrorSeverity.error,
}) {
  return field.value==null
      ? null
      : field.value==0
          ? ValidationError(
            field: field,
            error: errorMessage ?? ('${field.uiName} ${FromZeroLocalizations.of(context).translate("validation_error_not_zero")}'),
            severity: severity,
          )
          : null;
}

ValidationError? fieldValidatorStringIsEmail(BuildContext context, DAO dao, Field<String> field, {
  String? errorMessage,
  ValidationErrorSeverity severity = ValidationErrorSeverity.error,
}) {
  return field.value==null
      ? null
      : EmailValidator.validate(field.value!.trim(),)
          ? null
          : ValidationError(
            field: field,
            error: errorMessage ??
                '${field.uiName} ${FromZeroLocalizations.of(context).translate("validation_error_email")}',
            severity: severity,
          );
}





class FieldDiffMessage<T extends Comparable> extends StatelessWidget {

  final Field<T> field;
  final T? oldValue;
  final T? newValue;
  late final Field<T> oldValueField;
  late final Field<T> newdValueField;

  FieldDiffMessage({
    required this.field,
    required this.oldValue,
    required this.newValue,
    super.key,
  }) {
    final dummyDao = DAO(uiNameGetter: (dao) => 'Dummy', classUiNameGetter: (dao) => 'Dummy',);
    oldValueField = field.copyWith()
      ..onValueChanged = null;
    oldValueField.dao = dummyDao;
    oldValueField.value = oldValue;
    newdValueField = field.copyWith()
      ..onValueChanged = null;
    newdValueField.dao = dummyDao;
    newdValueField.value = newValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(
            width: 2,
            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.3),
          ),
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.uiName),
              IntrinsicWidth(
                child: Row(
                  children: [
                    Expanded(
                      child: MaterialKeyValuePair(
                        title: FromZeroLocalizations.of(context).translate("old_value"),
                        value: oldValueField.toString(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 16, left: 6, right: 6),
                      child: Icon(Icons.arrow_right_alt),
                    ),
                    Expanded(
                      child: MaterialKeyValuePair(
                        title: FromZeroLocalizations.of(context).translate("new_value"),
                        value: newdValueField.toString(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}


class ValidationMessage extends StatefulWidget {

  static final Map<Brightness, Map<ValidationErrorSeverity, Color>> severityColors = {
    Brightness.light: {
      ValidationErrorSeverity.disabling: Colors.grey.shade800,
      ValidationErrorSeverity.unfinished: Colors.grey.shade800,
      ValidationErrorSeverity.warning: Colors.yellow.shade900,
      ValidationErrorSeverity.nonBlockingError: Colors.orange.shade900,
      ValidationErrorSeverity.error: Colors.red.shade900,
      ValidationErrorSeverity.invalidating: Colors.red.shade900,
    },
    Brightness.dark: {
      ValidationErrorSeverity.disabling: Colors.grey.shade400,
      ValidationErrorSeverity.unfinished: Colors.grey.shade400,
      ValidationErrorSeverity.warning: Colors.yellow.shade400,
      ValidationErrorSeverity.nonBlockingError: Colors.orange.shade400,
      ValidationErrorSeverity.error: Colors.red.shade400,
      ValidationErrorSeverity.invalidating: Colors.red.shade400,
    },
  };

  static const int animationCount = 5;
  static const double animationCountRate = 1/animationCount;
  final List<ValidationError> errors;
  final bool passedFirstEdit;
  final TextStyle? errorTextStyle;
  final bool animate;
  final bool hideNotVisibleAsHintMessage;

  const ValidationMessage({
    required this.errors,
    required this.passedFirstEdit,
    this.animate = true,
    this.errorTextStyle,
    this.hideNotVisibleAsHintMessage = true,
    super.key,
  });

  @override
  State<ValidationMessage> createState() => _ValidationMessageState();

}

class _ValidationMessageState extends State<ValidationMessage> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final seenStrings = <String>[];
    for (final e in widget.errors) {
      if ((e.isBeforeEditing || widget.passedFirstEdit)
          && (!widget.hideNotVisibleAsHintMessage || e.isVisibleAsHintMessage) && !seenStrings.contains(e.error)) {
        seenStrings.add(e.error);
        children.add(InitiallyAnimatedWidget(
          duration: Duration(milliseconds: widget.animate ? 300 : 0),
          curve: Curves.easeOutCubic,
          builder: (animationController, child) {
            return SizeTransition(
              sizeFactor: animationController,
              axis: Axis.vertical,
              axisAlignment: -1,
              child: child,
            );
          },
          child: SingleValidationMessage(
            error: e,
            errorTextStyle: widget.errorTextStyle,
            animate: widget.animate,
          ),
        ),);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10,),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

}

class SingleValidationMessage extends StatefulWidget {

  final ValidationError error;
  final TextStyle? errorTextStyle;
  final bool animate;

  const SingleValidationMessage({
    required this.error,
    this.errorTextStyle,
    this.animate = true,
    super.key,
  });

  @override
  SingleValidationMessageState createState() => SingleValidationMessageState();

}

class SingleValidationMessageState extends State<SingleValidationMessage> with SingleTickerProviderStateMixin {

  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animate ? 2000 : 0,),
    );
    widget.error.animationController = animationController; // this is necessary because a context is needed for instanciating the AnimationController
    animationController.value = 1;
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.error.animationController = animationController;
    return AnimatedBuilder(
      animation: animationController,
      key: ValueKey(widget.error.severity.toString() + widget.error.error),
      builder: (context, child) {
        final baseColor = ValidationMessage.severityColors[Theme.of(context).brightness]![widget.error.severity]!;
        double value = animationController.value;
        int i;
        for (i=0; i<=ValidationMessage.animationCount && value>ValidationMessage.animationCountRate; i++) {
          value -= ValidationMessage.animationCountRate;
        }
        value = (value*ValidationMessage.animationCount).clamp(0, 1);
        if (i.isOdd) {
          value = 1-value;
        }
        final color = ColorTween(
          begin: baseColor.withOpacity(0),
          end: baseColor,
        ).transform(Curves.easeOutQuad.transform(value));
        return Padding(
          padding: const EdgeInsets.only(bottom: 4,),
          child: Container(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4, top: 2),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              color: widget.error.isBlocking
                  ? color
                  : Colors.transparent,
            ),
            child: Text(widget.error.toString(),
              style: (widget.errorTextStyle ?? Theme.of(context).textTheme.titleMedium!).copyWith(
                color: widget.error.isBlocking
                    ? Colors.white
                    : color,
              ),
            ),
          ),
        );
      },
    );
  }

}



class SaveConfirmationValidationMessage extends StatelessWidget {

  final List<ValidationError> allErrors;

  const SaveConfirmationValidationMessage({
    required this.allErrors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    List<ValidationError> warnings = [];
    List<ValidationError> redWarnings = [];
    List<ValidationError> errors = [];
    List<ValidationError> unfinished = [];
    for (final e in allErrors) {
      if (e.isVisibleAsSaveConfirmation) {
        if (e.severity==ValidationErrorSeverity.unfinished) {
          unfinished.add(e);
        } else if (e.severity==ValidationErrorSeverity.nonBlockingError) {
          redWarnings.add(e);
        } else if (e.isBlocking) {
          errors.add(e);
        } else {
          warnings.add(e);
        }
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SaveConfirmationValidationMessageGroup(
          name: '${FromZeroLocalizations.of(context).translate("errors")}:',
          severity: ValidationErrorSeverity.error,
          errors: errors,
        ),
        SaveConfirmationValidationMessageGroup(
          name: 'Advertencias Severas:',
          severity: ValidationErrorSeverity.nonBlockingError,
          errors: redWarnings,
        ),
        SaveConfirmationValidationMessageGroup(
          name: '${FromZeroLocalizations.of(context).translate("warnings")}:',
          severity: ValidationErrorSeverity.warning,
          errors: warnings,
        ),
        SaveConfirmationValidationMessageGroup(
          name: '${FromZeroLocalizations.of(context).translate("unfinished")}:',
          severity: ValidationErrorSeverity.unfinished,
          errors: unfinished,
        ),
      ],
    );
  }

}

class SaveConfirmationValidationMessageGroup extends StatelessWidget {

  final String? name;
  final ValidationErrorSeverity severity;
  final List<ValidationError> errors;

  const SaveConfirmationValidationMessageGroup({
    required this.name,
    required this.severity,
    required this.errors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return const SizedBox.shrink();
    }
    bool isBlocking = severity==ValidationErrorSeverity.error || severity==ValidationErrorSeverity.invalidating;
    final children = <Widget>[];
    final seenStrings = <String>[];
    for (final e in errors) {
      if (!seenStrings.contains(e.error)) {
        seenStrings.add(e.error);
        children.add(InkWell(
          onTap: () {
            Navigator.of(context).pop(false);
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              e.field.dao.focusError(e);
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 15, top: 1, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle,
                    size: 10,
                    color: ValidationMessage.severityColors[Theme.of(context).brightness]![e.severity],
                  ),
                ),
                const SizedBox(width: 6,),
                Expanded(
                  child: Text(e.error,
                    // style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: ValidationMessage.severityColors[Theme.of(context).brightness]![e.severity]!),
                  ),
                ),
              ],
            ),
          ),
        ),);
      }
    }
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(false);
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            errors.first.field.dao.focusError(errors.first);
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 18),
            if (name!=null)
              Row(
                children: [
                  Icon(Icons.warning,
                    size: isBlocking ? 38 : 27,
                    color: ValidationMessage.severityColors[Theme.of(context).brightness]![severity],
                  ),
                  const SizedBox(width: 4,),
                  Expanded(
                    child: Text(name!,
                      style: isBlocking
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ...children,
            if (isBlocking)
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

}



class ValidationRequiredOverlay extends StatelessWidget {
  final bool isRequired;
  final bool isEmpty;
  final bool dense;
  final TextAlign textAlign;
  final List<ValidationError> errors;
  final Widget child;

  const ValidationRequiredOverlay({
    required this.isRequired,
    required this.isEmpty,
    required this.errors,
    required this.child,
    required this.dense,
    this.textAlign = TextAlign.left,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showAsterisk = isRequired && (!dense || isEmpty);
    final visibleErrors = !showAsterisk ? <ValidationError>[]
        : errors.where((e) => e.isBlocking);
    final isAlignedRight = textAlign==TextAlign.right && !isEmpty; // because label is never aligned right in TextField
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showAsterisk)
          Positioned(
            top: dense ? 7
                : isEmpty ? 5 : 10,
            left: isAlignedRight ? null
                : dense ? -5
                : isEmpty ? 4 : 5,
            right: !isAlignedRight ? null
                : dense ? -5
                : isEmpty ? 4 : 5,
            child: TooltipFromZero(
              message: visibleErrors.isEmpty ? ''
                  : visibleErrors.map((e) => e.error).reduce((v, e) => '$v, $e'),
              child: IgnorePointer(
                child: Icon(MaterialCommunityIcons.asterisk,
                  size: dense ? 11 : isEmpty ? 14 : 8,
                  color: isEmpty
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.75),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
