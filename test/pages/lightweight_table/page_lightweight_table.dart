import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';
import '../home/page_home.dart';

class PageLightweightTable extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageLightweightTable(PageFromZero previousPage, Animation<double> animation, Animation<double> secondaryAnimation)
      : super(previousPage, animation, secondaryAnimation);

  @override
  _PageLightweightTableState createState() => _PageLightweightTableState();

}

class _PageLightweightTableState extends State<PageLightweightTable> {

  final ScrollController scrollController = ScrollController();
  final ScrollController tableScrollController = ScrollController();
  final ScrollController customScrollController = ScrollController();

  int sortIndex = 0;
  bool ascending = true;
  List<bool> selected = List.generate(5, (index) => false);


  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Lightweight Table"),
      body: _getPage(context),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: [0, 2],),
      drawerFooterBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: [-1, -1], replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }

  Widget _getPage(context){
    return ScrollbarFromZero(
      controller: scrollController,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: scrollController,
            child: ResponsiveHorizontalInsets(
              child: Column(
                children: [
                  SizedBox(height: 12,),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: TableFromZero.fromRowList(
                        layoutWidgetType: TableFromZero.column,
                        columnNames: ["Col 1", "Col 2", "Col 3", "Col 4", "Col 5"],
                        rows: [
                          ["Dummy data", "Dummy data", "Dummy data", "Dummy data", "Dummy data",],
                          ["Dummy data", "Dummy data", "Dummy data", "Dummy data", "Dummy data",],
                          ["Dummy data", "Dummy data", "Dummy data", "Dummy data", "Dummy data",],
                          ["Dummy data", "Dummy data", "Dummy data", "Dummy data", "Dummy data",],
                          ["Dummy data", "Dummy data", "Dummy data", "Dummy data", "Dummy data",],
                        ],
                        colBackgroundColors: [null, null, null, Colors.green.withOpacity(0.4), Colors.red.withOpacity(0.4)],
                        rowBackgroundColors: [null, null, null, null, Colors.indigo.withOpacity(0.4)],
                        rowTakesPriorityOverColumn: false,
                        columnAlignments: [null, null, null, null, TextAlign.right],
                        colStyles: [null, null, null, null, Theme.of(context).textTheme.caption],
                        rowStyles: [null, null, null, null, Theme.of(context).textTheme.headline6],
                        columnFlexes: [2, 1, 1, 1, 1],
                        onRowTap: (int i) {
                          print("Row $i tapped");
                        },
                        onHeaderTap: (value) {
                          if (value==sortIndex){
                            setState(() {
                              ascending = !ascending;
                            });
                          } else{
                            setState(() {
                              sortIndex = value;
                              ascending = true;
                            });
                          }
                        },
                        onCheckBoxSelected: (i, focused) {
                          setState(() {
                            selected[i] = focused;
                          });
                        },
                        onAllSelected: (value) {
                          setState(() {
                            selected = List.generate(selected.length, (index) => value);
                          });
                        },
                        itemPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        sortedColumnIndex: sortIndex,
                        sortedAscending: ascending,
                        selectedRows: selected,
                        verticalDivider: null,
//                        horizontalDivider: null,
                        showFirstHorizontalDivider: false,
                        actions: [
                          IconButton(icon: Icon(Icons.edit), tooltip: "Edit", splashRadius: 24, onPressed: (){ },),
                          IconButton(icon: Icon(Icons.delete_forever), tooltip: "Delete", splashRadius: 24, onPressed: (){ },),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12,),
                  SizedBox(
                    height: constraints.maxHeight-24,
                    child: Card(
                      clipBehavior: Clip.hardEdge,
                      child: ScrollbarFromZero(
                        controller: tableScrollController,
                        applyPaddingToChildrenOnDesktop: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TableFromZero.fromRowList(
                            controller: tableScrollController,
                            columnNames: ["Col 1", "Col 2", "Col 3", "Col 4", "Col 5"],
                            rows: List.generate(100, (index) => ["Dummy data", "Dummy data", "Dummy data", "Dummy data", "Dummy data",]),
                            verticalPadding: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12,),
                  SizedBox(
                    height: constraints.maxHeight-24,
                    child: Card(
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
                                rows: List.generate(100, (index) => ["Dummy data", "Dummy data", "Dummy data", "Dummy data", "Dummy data",]),
                                verticalPadding: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12,),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
