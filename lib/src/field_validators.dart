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
  bool get isBlocking => severity==ValidationErrorSeverity.error || severity==ValidationErrorSeverity.invalidating;
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




class ValidationMessage extends StatefulWidget {

  static final Map<Brightness, Map<ValidationErrorSeverity, Color>> severityColors = {
    Brightness.light: {
      ValidationErrorSeverity.warning: Colors.yellow.shade900,
      ValidationErrorSeverity.nonBlockingError: Colors.red.shade900,
      ValidationErrorSeverity.error: Colors.red.shade900,
      ValidationErrorSeverity.invalidating: Colors.red.shade900,
    },
    Brightness.dark: {
      ValidationErrorSeverity.warning: Colors.yellow.shade400,
      ValidationErrorSeverity.nonBlockingError: Colors.red.shade400,
      ValidationErrorSeverity.error: Colors.red.shade400,
      ValidationErrorSeverity.invalidating: Colors.red.shade400,
    },
  };

  static const int animationCount = 5;
  static const double animationCountRate = 1/animationCount;
  final List<ValidationError> errors;

  ValidationMessage({
    Key? key,
    required this.errors,
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
        children: widget.errors.map((e) {
          return InitiallyAnimatedWidget(
            duration: Duration(milliseconds: 300),
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
              duration: Duration(milliseconds: 2000,),
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
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
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
