import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field.dart';
import 'package:from_zero_ui/src/ui_utility_widgets.dart';


// TODO internationalize all

String? fieldValidatorRequired<T extends Comparable>(BuildContext context, DAO dao, Field<T> field) {
  return field.value==null||field.value!.toString().isEmpty ? 'Required' : null;
}

String? fieldValidatorNumberNotNegative(BuildContext context, DAO dao, Field<num> field) {
  return field.value==null ? null
      : field.value!<0 ? 'Number cannot be less than zero' : null;
}

String? fieldValidatorNumberNotZero(BuildContext context, DAO dao, Field<num> field) {
  return field.value==null ? null
      : field.value==0 ? 'Number cannot be zero' : null;
}

String? fieldValidatorStringIsEmail(BuildContext context, DAO dao, Field<String> field) {
  return field.value==null ? null
      : EmailValidator.validate(field.value!,) ? null : 'Must be a valid email address';
}




class ValidationMessage extends StatelessWidget {

  List<String> errors;

  ValidationMessage({
    Key? key,
    required this.errors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InitiallyAnimatedWidget(
      duration: Duration(milliseconds: 500),
      builder: (animationController, child) {
        return SizeTransition(
          sizeFactor: CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic),
          axis: Axis.vertical,
          axisAlignment: -1,
          child: child,
        );
      },
      child: Padding(
        padding: EdgeInsets.only(left: 18, right: 18, bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors.map((e) {
            return Padding(
              padding: EdgeInsets.all(0),
              child: Text(e,
                style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Theme.of(context).errorColor),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

}
