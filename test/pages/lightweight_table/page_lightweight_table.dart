import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';
import 'package:from_zero_ui/src/table/table_from_zero_models.dart';
import 'package:path_provider/path_provider.dart';

import '../../change_notifiers/theme_parameters.dart';
import '../../router.dart';
import '../home/page_home.dart';

class PageLightweightTable extends StatefulWidget {

  PageLightweightTable();

  @override
  _PageLightweightTableState createState() => _PageLightweightTableState();

}

class _PageLightweightTableState extends State<PageLightweightTable> {

  late Widget col1;
  late Widget col2;
  late Widget col3;
  late TableFromZero table1;
  late TableFromZero table2;
  late TableFromZero table3;
  final ScrollController scrollController = ScrollController();
  final ScrollController tableScrollController = ScrollController();
  final ScrollController customScrollController = ScrollController();
  List<TextEditingController?> textControllers = [
    null,
    null,
    TextEditingController(text: "CustomScrollController"),
  ];


  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      mainScrollController: scrollController,
      scrollbarType: ScaffoldFromZero.scrollbarTypeOverAppbar,
      title: Text("Lightweight Table"),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: mainRoutes),
        compact: compact,
      ),
      drawerFooterBuilder: (scaffoldContext, compact) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DrawerMenuButtonFromZero(
          //   selected: false,
          //   compact: compact,
          //   title: "Exportar Una Tabla (multipagina)",
          //   icon: Icon(Icons.plus_one),
          //   onTap: () {
          //     showModal(
          //       context: context,
          //       builder: (context) => Export.scrollable(
          //         scaffoldContext: scaffoldContext,
          //         scrollableChildBuilder: (context, i, currentSize, portrait, scale, format, controller) => _getCol3(context, controller, col3RowKeys),
          //         scrollableStickyOffset: 48,
          //         significantWidgetsKeys: col3RowKeys,
          //         textEditingControllers: textControllers,
          //         themeParameters: (context as WidgetRef).read(fromZeroThemeParametersProvider),
          //         title: DateTime.now().millisecondsSinceEpoch.toString() + " Tables",
          //         path: Export.getDefaultDirectoryPath('Playground From Zero'),
          //       ),
          //     );
          //   },
          // ),
          // DrawerMenuButtonFromZero(
          //   selected: false,
          //   compact: compact,
          //   title: "Exportar",
          //   icon: Icon(Icons.file_download),
          //   onTap: () {
          //     showModal(
          //       context: context,
          //       builder: (context) => Export(
          //         scaffoldContext: scaffoldContext,
          //         childBuilder: (context, i, currentSize, portrait, scale, format) => [col1, col2, col3][i],
          //         childrenCount: (currentSize, portrait, scale, format) => 3,
          //         textEditingControllers: textControllers,
          //         themeParameters: (context as WidgetRef).read(fromZeroThemeParametersProvider),
          //         title: DateTime.now().millisecondsSinceEpoch.toString() + " Tables",
          //         path: Export.getDefaultDirectoryPath('Playground From Zero'),
          //         // excelSheets: () => {
          //         //   'Table 2': table2,
          //         //   'Table 3': table3,
          //         // },
          //       ),
          //     );
          //   },
          // ),
          DrawerMenuFromZero(
            tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: settingsRoutes),
            compact: compact,
          )
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
    table2 = TableFromZero(
      scrollController: tableScrollController,
      enableStickyHeaders: true,
      minWidthGetter: (currentColumnKeys) => 640,
      alternateRowBackgroundBrightness: true,
      rows: List.generate(100, (index) => ["Dummy data " + index.toString(), "Dummy data", "Dummy data", "Dummy data", "Dummy data",]).map((e) {
        return SimpleRowModel(
          id: e,
          values: e.asMap(),
          rowAddon: Text('ADDON ASDFG fsgfad gadfsgkadfs glasdnfgklanfsgAFSG DAFG AFSD GADSF GADFGA DFSG'),
          onRowTap: (row){},
          onCellTap: (row,) {},
          // actions: [
          //   Container(width: 32, height: 32, color: Colors.red,),
          // ],
        );
      }).toList(),
      columns: ["Col 1", "Col 2", "Col 3", "Col 4", "Col 5"].map((e) {
        return SimpleColModel(
          name: e,
        );
      }).toList().asMap(),
    );
    col2 = Card(
      clipBehavior: Clip.hardEdge,
      child: ScrollbarFromZero(
        controller: tableScrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomScrollView(
            controller: tableScrollController,
            slivers: [table2],
          ),
        ),
      ),
    );
    col3 = Card(
      clipBehavior: Clip.hardEdge,
      child: ScrollbarFromZero(
        controller: customScrollController,
        child: _getCol3(context, customScrollController),
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

  List<GlobalKey> col3RowKeys = List.generate(100, (index) => GlobalKey());
  Widget _getCol3(BuildContext context, ScrollController controller, [List<Key>? rowKeys]){
    if (rowKeys==null) rowKeys = List.generate(100, (index) => ValueKey(index));
    table3 = TableFromZero(
      horizontalDivider: null,
      verticalDivider: null,
      alternateRowBackgroundBrightness: true,
      columns: ["Col 1", "Col 2", "Col 3", "Col 4", "Col 5"].map((e) => SimpleColModel(
        name: e,
        filterEnabled: true,
        width: e=="Col 1" ? 128 : null,
        alignment: e=="Col 3" ? TextAlign.right : null,
      )).toList().asMap(),
      rows: List.generate(100, (index) => SimpleRowModel(
        id: index,
        height: 36,
        rowKey: rowKeys![index],
        values: ["Dummy data" + index.toString(), "Dummy data", "Dummy data", "Dummy data", "Dummy data",].asMap(),
      )),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomScrollView(
        controller: controller,
        cacheExtent: double.infinity,
        physics: NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: ValueListenableBuilder(
                  valueListenable: textControllers[2]!,
                  builder: (context, TextEditingValue value, child) {
                    var v = value.text;
                    if (context.findAncestorWidgetOfExactType<Export>()==null)
                      v = "CustomScrollController";
                    return Text(v, style: Theme.of(context).textTheme.headline3,);
                  }
              ),
            ),
          ),
          table3,
          SliverToBoxAdapter(child: SizedBox(height: 16,),),
        ],
      ),
    );
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
    return SizedBox.shrink();
//     return TableFromZero.fromRowList(
//       layoutWidgetType: TableFromZero.animatedColumn,
//       columnNames: ["Col 1", "Col 2", "Col 3", "Col 4", "Very long column title 5"],
//       rows: rows,
//       rowIdsForAnimation: rowsIds,
//       colBackgroundColors: [null, null, null, Colors.green.withOpacity(0.4), Colors.red.withOpacity(0.4)],
//       rowBackgroundColors: [null, null, null, null, Colors.indigo.withOpacity(0.4)],
//       rowTakesPriorityOverColumn: false,
//       columnAlignments: [null, null, null, null, TextAlign.right],
//       colStyles: [null, null, null, null, Theme.of(context).textTheme.caption],
//       rowStyles: [null, null, null, null, Theme.of(context).textTheme.headline6],
//       columnFlexes: [2, 1, 1, 1, 1],
//       onRowTap: (RowModel row) {
//         log("Row ${row.values[0]} tapped");
//       },
//       onCheckBoxSelected: (row, focused) {
//         Future.delayed(Duration(seconds: 2)).then((value) {
//           setState(() {
//             selected[rowsIds.indexOf(row.id)] = focused;
//           });
//         });
//         setState(() {
//           selected[rowsIds.indexOf(row.id)] = null;
//         });
//       },
//       onAllSelected: (value) {
//         setState(() {
//           selected = List.generate(selected.length, (index) => value);
//         });
//       },
//       itemPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       initialSortedColumnIndex: 0,
//       selectedRows: selected,
//       verticalDivider: null,
// //                        horizontalDivider: null,
//       showFirstHorizontalDivider: false,
//       actions: [
//         IconButton(icon: Icon(Icons.edit), tooltip: "Edit", splashRadius: 24, onPressed: (){ },),
//         IconButton(icon: Icon(Icons.delete_forever), tooltip: "Delete", splashRadius: 24, onPressed: (){
//           setState(() {
//             rows.removeAt(2);
//             rowsIds.removeAt(2);
//             selected.removeAt(2);
//           });
//         },),
//       ],
//     );
  }

}
