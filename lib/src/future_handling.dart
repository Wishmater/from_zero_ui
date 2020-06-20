import 'package:animations/animations.dart';
import 'package:flutter/material.dart';


class LoadingCard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LoadingSign(),
      ),
    );
  }

}

class LoadingSign extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

}

class ErrorCard extends StatelessWidget {

  String title;
  String subtitle;
  Widget icon;
  VoidCallback onRetry;

  ErrorCard({this.title, this.subtitle, this.onRetry, this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ErrorSign(
          title: title,
          subtitle: subtitle,
          onRetry: onRetry,
          icon: icon,
        ),
      ),
    );
  }

}

class ErrorSign extends StatelessWidget {

  String title;
  String subtitle;
  VoidCallback onRetry;
  Widget icon;

  ErrorSign({this.title, this.subtitle, this.onRetry, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon!=null)
            icon,
          if (icon!=null)
            SizedBox(height: 6,),
          Text(
            title,
            style: Theme.of(context).textTheme.headline6,
          ),
          SizedBox(height: 12,),
          Text(
            subtitle,
          ),
          if (onRetry!=null)
          SizedBox(height: 12,),
          if (onRetry!=null)
          RaisedButton(
            child: Text("Reintentar"), //TODO 3 internationalize
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }

}

typedef SuccessBuilder<T> = Widget Function(BuildContext context, T result);
typedef ErrorBuilder = Widget Function(BuildContext context, Object error);
typedef LoadingBuilder = Widget Function(BuildContext context);
class FutureBuilderFromZero<T> extends StatelessWidget {

  final key;
  final initialData;
  final Future future;
  final SuccessBuilder<T> successBuilder;
  ErrorBuilder errorBuilder;
  LoadingBuilder loadingBuilder;
  PageTransitionSwitcherTransitionBuilder transitionBuilder;

  FutureBuilderFromZero({
    this.key,
    @required this.future,
    @required this.successBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.initialData,
  }) {
    assert(successBuilder != null);
    if (errorBuilder==null) errorBuilder = _defaultErrorBuilder;
    if (loadingBuilder==null) loadingBuilder = _defaultLoadingBuilder;
    if (transitionBuilder==null) transitionBuilder = _defaultTransitionBuilder;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      key: key,
      future: future,
      initialData: initialData,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        Widget result;
        if (snapshot.connectionState == ConnectionState.done){
          if (snapshot.hasData){
            result = successBuilder(context, snapshot.data);
          } else if (snapshot.hasError){
            result = errorBuilder(context, snapshot.error);
          }
        } else{
          result = loadingBuilder(context);
        }
        return PageTransitionSwitcher(
          transitionBuilder: transitionBuilder,
          child: result,
          duration: Duration(milliseconds: 300),
        );
      },
    );
  }

  Widget _defaultLoadingBuilder(context){
    return LoadingSign();
  }

  Widget _defaultErrorBuilder(context, error){
    return ErrorSign(
      icon: Icon(Icons.error_outline, size: 64, color: Theme.of(context).errorColor,),
      title: "Oops!",
      subtitle: "Something went wrong...",
    );
  }

  Widget _defaultTransitionBuilder(Widget child, Animation<double> primaryAnimation, Animation<double> secondaryAnimation,){
    return FadeThroughTransition(
      animation: primaryAnimation,
      secondaryAnimation: secondaryAnimation,
      child: child,
      fillColor: Colors.transparent,
    );
  }

}
