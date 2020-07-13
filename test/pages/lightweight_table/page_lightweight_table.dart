import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/export.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:provider/provider.dart';
import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageLightweightTable extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageLightweightTable(Animation<double> animation, Animation<double> secondaryAnimation)
      : super(animation, secondaryAnimation);

  @override
  _PageLightweightTableState createState() => _PageLightweightTableState();

}

class _PageLightweightTableState extends State<PageLightweightTable> {

  Widget col1;
  Widget col2;
  Widget col3;
  final ScrollController scrollController = ScrollController();
  final ScrollController tableScrollController = ScrollController();
  final ScrollController customScrollController = ScrollController();


  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
//      mainScrollController: scrollController,
      scrollbarType: ScaffoldFromZero.scrollbarTypeOverAppbar,
      currentPage: widget,
      title: Text("Lightweight Table"),
      body: _getPage(context),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: [0, 2],),
      drawerFooterBuilder: (compact) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DrawerMenuButtonFromZero(
            selected: false,
            compact: compact,
            title: "Exportar",
            icon: Icon(Icons.file_download),
            onTap: () {
              showModal(
                context: context,
                builder: (context) => Export(
                  childBuilder: (i, currentSize, portrait, scale, format) => [col1, col2, col3][i],
                  childrenCount: 3,
                  themeParameters: Provider.of<ThemeParameters>(context, listen: false),
                  title: DateTime.now().millisecondsSinceEpoch.toString() + " Tables",
//                  path: "",
                  path: Platform.environment["HOMEDRIVE"]+Platform.environment["HOMEPATH"]+"\\Documents\\Playground From Zero\\",
                ),
              );
            },
          ),
          DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: [-1, -1], replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
        ],
      ),
    );
  }

  Widget _getPage(context){
    col1 = Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ComplicatedTable(),
      ),
    );
    col2 = Card(
      clipBehavior: Clip.hardEdge,
      child: ScrollbarFromZero(
        controller: tableScrollController,
        applyPaddingToChildrenOnDesktop: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TableFromZero.fromRowList(
            controller: tableScrollController,
            columnNames: ["Col 1", "Col 2", "Col 3", "Col 4", "Col 5"],
            rows: List.generate(100, (index) => ["Dummy data " + index.toString(), "Dummy data", "Dummy data", "Dummy data", "Dummy data",]),
            verticalPadding: 16,
          ),
        ),
      ),
    );
    col3 = Card(
      clipBehavior: Clip.hardEdge,
      child: ScrollbarFromZero(
        controller: customScrollController,
        applyPaddingToChildrenOnDesktop: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomScrollView(
            controller: customScrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16),
                  child: Text("CustomScrollController", style: Theme.of(context).textTheme.headline4,),
                ),
              ),
              TableFromZero.fromRowList(
                layoutWidgetType: TableFromZero.sliverListViewBuilder,
                columnNames: ["Col 1", "Col 2", "Col 3", "Col 4", "Col 5"],
                rows: List.generate(100, (index) => ["Dummy data" + index.toString(), "Dummy data", "Dummy data", "Dummy data", "Dummy data",]),
                verticalPadding: 16,
              ),
              SliverToBoxAdapter(child: SizedBox(height: 16,),),
            ],
          ),
        ),
      ),
    );
    Widget result = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: scrollController,
          child: ResponsiveHorizontalInsets(
            child: Column(
              children: [
                SizedBox(height: 12,),
                col1,
                SizedBox(height: 12,),
                SizedBox(
                  height: constraints.maxHeight-24,
                  child: col2
                ),
                SizedBox(height: 12,),
                SizedBox(
                  height: constraints.maxHeight-24,
                  child: col3
                ),
                SizedBox(height: 12,),
              ],
            ),
          ),
        );
      },
    );
    return result;
  }
}


class ComplicatedTable extends StatefulWidget {

  @override
  _ComplicatedTableState createState() => _ComplicatedTableState();

}

class _ComplicatedTableState extends State<ComplicatedTable> {

  List<bool> selected = List.generate(5, (index) => false);
  List<int> rowsIds = List.generate(5, (index) => index);
  List<List<String>> rows = [
    ["Dummy data 0", "Dummy data", "Dummy data", "Dummy data", "Dummy data",],
    ["Dummy data 1", "Dummy data", "Dummy data", "Dummy data", "Dummy data",],
    ["Dummy data 2", "Dummy data", "Dummy data", "Dummy data", "Dummy data",],
    ["Dummy data 3", "Dummy data", "Dummy data", "Dummy data", "Dummy data",],
    ["Dummy data 4", "Dummy data", "Dummy data", "Dummy data", "Dummy data 64",],
  ];

  @override
  Widget build(BuildContext context) {
    return TableFromZero.fromRowList(
      layoutWidgetType: TableFromZero.animatedColumn,
      columnNames: ["Col 1", "Col 2", "Col 3", "Col 4", "Very long column title 5"],
      rows: rows,
      rowIdsForAnimation: rowsIds,
      colBackgroundColors: [null, null, null, Colors.green.withOpacity(0.4), Colors.red.withOpacity(0.4)],
      rowBackgroundColors: [null, null, null, null, Colors.indigo.withOpacity(0.4)],
      rowTakesPriorityOverColumn: false,
      columnAlignments: [null, null, null, null, TextAlign.right],
      colStyles: [null, null, null, null, Theme.of(context).textTheme.caption],
      rowStyles: [null, null, null, null, Theme.of(context).textTheme.headline6],
      columnFlexes: [2, 1, 1, 1, 1],
      onRowTap: (RowModel row) {
        print("Row ${row.values[0]} tapped");
      },
      onCheckBoxSelected: (row, focused) {
        Future.delayed(Duration(seconds: 2)).then((value) {
          setState(() {
            selected[rowsIds.indexOf(row.id)] = focused;
          });
        });
        setState(() {
          selected[rowsIds.indexOf(row.id)] = null;
        });
      },
      onAllSelected: (value) {
        setState(() {
          selected = List.generate(selected.length, (index) => value);
        });
      },
      itemPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      initialSortedColumnIndex: 0,
      selectedRows: selected,
      verticalDivider: null,
//                        horizontalDivider: null,
      showFirstHorizontalDivider: false,
      actions: [
        IconButton(icon: Icon(Icons.edit), tooltip: "Edit", splashRadius: 24, onPressed: (){ },),
        IconButton(icon: Icon(Icons.delete_forever), tooltip: "Delete", splashRadius: 24, onPressed: (){
          setState(() {
            rows.removeAt(2);
            rowsIds.removeAt(2);
            selected.removeAt(2);
          });
        },),
      ],
    );
  }

}
