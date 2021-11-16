import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field.dart';
import 'package:from_zero_ui/src/ui_utility_widgets.dart';

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
  ValidationError({
    required this.field,
    required this.error,
    this.severity=ValidationErrorSeverity.error,
  });
  @override
  String toString() => error;
  bool get isVisibleAsSaveConfirmation => severity!=ValidationErrorSeverity.disabling;
  bool get isVisibleAsHintMessage => severity!=ValidationErrorSeverity.disabling && severity!=ValidationErrorSeverity.unfinished;
  bool get isVisibleAsTooltip => severity==ValidationErrorSeverity.disabling;
  bool get isBlocking => severity==ValidationErrorSeverity.error || severity==ValidationErrorSeverity.invalidating;
  bool get isBeforeEditing => severity==ValidationErrorSeverity.disabling || severity==ValidationErrorSeverity.invalidating;
}

class InvalidatingError<T extends Comparable> extends ValidationError {
  T? defaultValue;
  bool showVisualConfirmation;
  bool allowUndoInvalidatingChange;
  bool allowSetThisFieldToDefaultValue;
  InvalidatingError({
    required Field<T> field,
    required String error,
    this.defaultValue,
    this.showVisualConfirmation = true,
    this.allowUndoInvalidatingChange = true,
    this.allowSetThisFieldToDefaultValue = true,
  })  : assert(showVisualConfirmation || allowUndoInvalidatingChange),
        super(
          field: field,
          error: error,
          severity: ValidationErrorSeverity.invalidating,
        );
}




ValidationError? fieldValidatorRequired<T extends Comparable>(BuildContext context, DAO dao, Field<T> field, {
  String? errorMessage,
  ValidationErrorSeverity severity = ValidationErrorSeverity.error,
}) {
  return field.value==null||field.value!.toString().isEmpty
      ? ValidationError(
        field: field,
        error: errorMessage ?? (field.uiName + ' ' + FromZeroLocalizations.of(context).translate("validation_error_required")),
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
            error: errorMessage ?? (field.uiName + ' ' + FromZeroLocalizations.of(context).translate("validation_error_not_negative")),
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
            error: errorMessage ?? (field.uiName + ' ' + FromZeroLocalizations.of(context).translate("validation_error_not_zero")),
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
      : EmailValidator.validate(field.value!,)
          ? null
          : ValidationError(
            field: field,
            error: errorMessage ?? FromZeroLocalizations.of(context).translate("validation_error_email"),
            severity: severity,
          );
}





class FieldDiffMessage extends StatelessWidget {

  final Field field;
  final dynamic oldValue;
  final dynamic newValue;
  late final Field oldValueField;
  late final Field newdValueField;

  FieldDiffMessage({
    Key? key,
    required this.field,
    required this.oldValue,
    required this.newValue,
  }) : super(key: key) {
    final dummyDao = DAO(uiNameGetter: (dao) => 'Dummy', classUiNameGetter: (dao) => 'Dummy',);
    oldValueField = field.copyWith();
    oldValueField.dao = dummyDao;
    oldValueField.value = oldValue;
    newdValueField = field.copyWith();
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
          borderRadius: BorderRadius.all(Radius.circular(8)),
          border: Border.all(
            width: 2,
            color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.3),
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
                    Padding(
                      padding: const EdgeInsets.only(top: 16, left: 6, right: 6),
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
      ValidationErrorSeverity.nonBlockingError: Colors.red.shade900,
      ValidationErrorSeverity.error: Colors.red.shade900,
      ValidationErrorSeverity.invalidating: Colors.red.shade900,
    },
    Brightness.dark: {
      ValidationErrorSeverity.disabling: Colors.grey.shade400,
      ValidationErrorSeverity.unfinished: Colors.grey.shade400,
      ValidationErrorSeverity.warning: Colors.yellow.shade400,
      ValidationErrorSeverity.nonBlockingError: Colors.red.shade400,
      ValidationErrorSeverity.error: Colors.red.shade400,
      ValidationErrorSeverity.invalidating: Colors.red.shade400,
    },
  };

  static const int animationCount = 5;
  static const double animationCountRate = 1/animationCount;
  final List<ValidationError> errors;
  final TextStyle? errorTextStyle;
  final bool animate;

  ValidationMessage({
    Key? key,
    required this.errors,
    this.animate = true,
    this.errorTextStyle,
  }) : super(key: key);

  @override
  State<ValidationMessage> createState() => _ValidationMessageState();

}

class _ValidationMessageState extends State<ValidationMessage> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 10, right: 10,),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.errors.where((e) => e.isVisibleAsHintMessage).map((e) {
          return InitiallyAnimatedWidget(
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
          );
        }).toList(),
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
    Key? key,
  }) : super(key: key);

  @override
  _SingleValidationMessageState createState() => _SingleValidationMessageState();

}

class _SingleValidationMessageState extends State<SingleValidationMessage> with SingleTickerProviderStateMixin {

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
            padding: EdgeInsets.only(left: 8, right: 8, bottom: 4, top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              color: widget.error.isBlocking
                  ? color
                  : Colors.transparent,
            ),
            child: Text(widget.error.toString(),
              style: (widget.errorTextStyle ?? Theme.of(context).textTheme.subtitle1!).copyWith(
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
    Key? key,
    required this.allErrors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<ValidationError> warnings = [];
    List<ValidationError> errors = [];
    List<ValidationError> unfinished = [];
    for (final e in allErrors) {
      if (e.isVisibleAsSaveConfirmation) {
        if (e.severity==ValidationErrorSeverity.unfinished) {
          unfinished.add(e);
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
          name: FromZeroLocalizations.of(context).translate("errors") + ':',
          severity: ValidationErrorSeverity.error,
          errors: errors,
        ),
        SaveConfirmationValidationMessageGroup(
          name: FromZeroLocalizations.of(context).translate("warnings") + ':',
          severity: ValidationErrorSeverity.warning,
          errors: warnings,
        ),
        SaveConfirmationValidationMessageGroup(
          name: FromZeroLocalizations.of(context).translate("unfinished") + ':',
          severity: ValidationErrorSeverity.unfinished,
          errors: unfinished,
        ),
      ],
    );
  }

}

class SaveConfirmationValidationMessageGroup extends StatelessWidget {

  final String name;
  final ValidationErrorSeverity severity;
  final List<ValidationError> errors;

  const SaveConfirmationValidationMessageGroup({
    Key? key,
    required this.name,
    required this.severity,
    required this.errors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 18,),
        Row(
          children: [
            Icon(Icons.warning,
              size: 38,
              color: ValidationMessage.severityColors[Theme.of(context).brightness]![severity]!,
            ),
            SizedBox(width: 6,),
            Expanded(
              child: Text(name,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ],
        ),
        ...errors.map((e) {
          return Padding(
            padding: const EdgeInsets.only(left: 15,),
            child: Row(
              children: [
                Icon(Icons.circle,
                  size: 10,
                  color: ValidationMessage.severityColors[Theme.of(context).brightness]![e.severity]!,
                ),
                SizedBox(width: 8,),
                Expanded(
                  child: Text(e.error,
                    // style: Theme.of(context).textTheme.bodyText1!.copyWith(color: ValidationMessage.severityColors[Theme.of(context).brightness]![e.severity]!),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

}
