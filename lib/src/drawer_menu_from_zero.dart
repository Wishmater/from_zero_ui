import 'package:flutter/material.dart';

class ResponsiveDrawerMenuItem{

  String title;
  String route;
  IconData icon;
  List<List<ResponsiveDrawerMenuItem>> children; //TODO 2 implement multilevel / children
  List<int> selectedChild;

  ResponsiveDrawerMenuItem({this.title, this.route, this.icon, this.children, this.selectedChild});


}

class DrawerMenuFromZero extends StatefulWidget {

  static const int alwaysReplaceInsteadOfPuhsing = 1;
  static const int neverReplaceInsteadOfPuhsing = 2;
  static const int exceptRootReplaceInsteadOfPuhsing = 0;

  final List<List<ResponsiveDrawerMenuItem>> tabs;
  final List<int> selected;
  final bool compact;
  final int replaceInsteadOfPuhsing;

  DrawerMenuFromZero({
    @required this.tabs,
    this.selected = const [0, 0],
    this.compact = false,
    this.replaceInsteadOfPuhsing = 0,
  });

  @override
  _DrawerMenuFromZeroState createState() => _DrawerMenuFromZeroState();

}

class _DrawerMenuFromZeroState extends State<DrawerMenuFromZero> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _getWidgets(context, widget.tabs, widget.selected),
    );
  }

  List<Widget> _getWidgets(BuildContext context, List<List<ResponsiveDrawerMenuItem>> tabs, List<int> selected){
    List<Widget> result = [];
    for (int i=0; i<tabs.length; i++){
      if (i>0){
        result.add(Divider());
      }
      result.addAll(
          List.generate(tabs[i].length, (j) => DrawerMenuButtonFromZero(
            title: tabs[i][j].title,
            selected: selected[0]==i && selected[1]==j,
            compact: widget.compact,
            icon: Icon(tabs[i][j].icon,),
            onTap: () {
              if (i!=selected[0] || j!=selected[1]) {
                try{
                  var scaffold = Scaffold.of(context);
                  if (scaffold.hasDrawer)
                    Navigator.of(context).pop();
                } catch(_, __){}
                if (widget.replaceInsteadOfPuhsing == DrawerMenuFromZero.exceptRootReplaceInsteadOfPuhsing){
                  if (selected[0]==0 && selected[1]==0){
                    Navigator.pushNamed(context, tabs[i][j].route);
                  } else{
                    if (i==0 && j==0){ //&& pushedMain
                      Navigator.pop(context);
                    } else{
                      Navigator.pushReplacementNamed(context, tabs[i][j].route);
                    }
                  }
                } else if (widget.replaceInsteadOfPuhsing == DrawerMenuFromZero.neverReplaceInsteadOfPuhsing){
                  Navigator.pushNamed(context, tabs[i][j].route);
                } else if (widget.replaceInsteadOfPuhsing == DrawerMenuFromZero.alwaysReplaceInsteadOfPuhsing){
                  Navigator.pushReplacementNamed(context, tabs[i][j].route);
                }
              }
            },
          ))
      );
    }
    return result;
  }

}


class DrawerMenuButtonFromZero extends StatefulWidget {

  final bool selected;
  final bool compact;
  final String title;
  final String subtitle;
  final Icon icon;
  final GestureTapCallback onTap;
  final Color selectedColor;

  DrawerMenuButtonFromZero({this.selected=false, this.compact=false, this.title,
      this.subtitle, this.icon, this.onTap, this.selectedColor});

  @override
  _DrawerMenuButtonFromZeroState createState() => _DrawerMenuButtonFromZeroState(selectedColor);

}

class _DrawerMenuButtonFromZeroState extends State<DrawerMenuButtonFromZero> {

  Color selectedColor;

  _DrawerMenuButtonFromZeroState(this.selectedColor);

  @override
  Widget build(BuildContext context) {
    if (widget.selectedColor==null){
      selectedColor = Theme.of(context).brightness==Brightness.dark
          ? Theme.of(context).accentColor
          : Theme.of(context).primaryColor;
    }
    return Container(
      color: widget.selected
          ? selectedColor.withOpacity(0.05)
          : Colors.transparent,
      child: ListTile(
        selected: widget.selected,
        title: Text(widget.title, style: TextStyle(
          color: widget.selected ? selectedColor : Theme.of(context).textTheme.bodyText1.color
        ),),
        contentPadding: EdgeInsets.all(0),
        leading: AspectRatio(
          aspectRatio: 1,
          child: Builder(
            builder: (context) {
              Widget result = SizedBox.expand(
                child: widget.compact ? Tooltip(
                  message: widget.title,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: widget.icon,
                  ),
                ) : Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: widget.icon,
                ),
              );
              if (widget.selected) result = IconTheme(
                data: Theme.of(context).iconTheme.copyWith(
                  color: selectedColor,
                ),
                child: result,
              );
              return result;
            }
          ),
        ),
        onTap: widget.onTap,
      ),
    );
  }
}
