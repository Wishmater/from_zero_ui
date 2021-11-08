import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field.dart';
import 'package:from_zero_ui/src/ui_utility_widgets.dart';

enum ValidationErrorSeverity {
  warning,
  nonBlockingError,
  error,
  disabling,
  invalidating,
}

class ValidationError {
  ValidationErrorSeverity severity;
  String error;
  ValidationError({
    required this.error,
    this.severity=ValidationErrorSeverity.error,
  });
  @override
  String toString() => error;
  bool get isVisibleAsHintMessage => severity!=ValidationErrorSeverity.disabling;
  bool get isVisibleAsTooltip => severity==ValidationErrorSeverity.disabling;
  bool get isBlocking => severity==ValidationErrorSeverity.error || severity==ValidationErrorSeverity.invalidating;
  bool get isBeforeEditing => severity==ValidationErrorSeverity.disabling || severity==ValidationErrorSeverity.invalidating;
}

class InvalidatingError<T> extends ValidationError {
  T? defaultValue;
  bool showVisualConfirmation;
  bool allowUndoInvalidatingChange;
  bool allowSetThisFieldToDefaultValue;
  InvalidatingError({
    required String error,
    this.defaultValue,
    this.showVisualConfirmation = true,
    this.allowUndoInvalidatingChange = true,
    this.allowSetThisFieldToDefaultValue = true,
  })  : assert(showVisualConfirmation || allowUndoInvalidatingChange),
        super(
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
    oldValueField = field.copyWith()..value=oldValue;
    newdValueField = field.copyWith()..value=newValue;
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
      ValidationErrorSeverity.warning: Colors.yellow.shade900,
      ValidationErrorSeverity.nonBlockingError: Colors.red.shade900,
      ValidationErrorSeverity.error: Colors.red.shade900,
      ValidationErrorSeverity.invalidating: Colors.red.shade900,
    },
    Brightness.dark: {
      ValidationErrorSeverity.disabling: Colors.grey.shade400,
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

class _ValidationMessageState extends State<ValidationMessage> {

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
            child: InitiallyAnimatedWidget(
              key: ValueKey(e.severity.toString() + e.error),
              duration: Duration(milliseconds: widget.animate ? 2000 : 0,),
              curve: Curves.linear,
              builder: (animation, child) {
                final baseColor = ValidationMessage.severityColors[Theme.of(context).brightness]![e.severity]!;
                double value = animation.value;
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
                      color: e.isBlocking
                          ? color
                          : Colors.transparent,
                    ),
                    child: Text(e.toString(),
                      style: (widget.errorTextStyle ?? Theme.of(context).textTheme.subtitle1!).copyWith(
                        color: e.isBlocking
                            ? Colors.white
                            : color,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

}
