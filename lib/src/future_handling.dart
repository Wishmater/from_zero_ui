import 'package:flutter/material.dart';

//TODO 1 declare FutureBuilderFromZero (takes functions for rendering loading, error, done widgets (maybe even add some by default))
//TODO 1 declare MultipleFutureBuilderFromZero

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
  VoidCallback onRetry;

  ErrorCard({this.title, this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ErrorSign(
          title: title,
          subtitle: subtitle,
          onRetry: onRetry,
        ),
      ),
    );
  }

}

class ErrorSign extends StatelessWidget {

  String title;
  String subtitle;
  VoidCallback onRetry;

  ErrorSign({this.title, this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            child: Text("Reintentar"),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }

}

typedef MultipleAsyncWidgetBuilder<T> = Widget Function(BuildContext context, List<AsyncSnapshot<T>> snapshots);
typedef BetterAsyncWidgetBuilder<T> = Widget Function(BuildContext context, List<AsyncSnapshot<T>> snapshots, Object error, List<T> resultados);
class MultipleFutureBuilder<T> extends StatelessWidget {

  final List<Future<T>> futures;
  final MultipleAsyncWidgetBuilder<T> builder;
  final BetterAsyncWidgetBuilder<T> betterBuilder;

  MultipleFutureBuilder({@required this.futures, this.builder, this.betterBuilder})
      : assert(builder!=null || betterBuilder!=null);


  @override
  Widget build(BuildContext context) {
    List<AsyncSnapshot<T>> snapshots = [];
    return _getFutureBuilder(context, snapshots, 0);
  }

  Widget _getFutureBuilder(context, List<AsyncSnapshot<T>> snapshots, int i){
    if (i>=futures.length){
      if (builder!=null){
        return builder(context, snapshots);
      } else{
        List<T> resultados = [];
        var error = null;
        snapshots.forEach((element) {
          if (element.connectionState == ConnectionState.done){
            if (element.hasData){
              resultados.add(element.data);
            } else if (element.hasError){
              error = element.error;
            }
          }
        });
        return betterBuilder(context, snapshots, error, resultados);
      }
    }
    return FutureBuilder(
      future: futures[i],
      builder: (context, snapshot) {
        if (i<snapshots.length){
          snapshots[i] = snapshot;
        } else{
          snapshots.add(snapshot);
        }
        return _getFutureBuilder(context, snapshots, i+1);
      },
    );
  }

}
