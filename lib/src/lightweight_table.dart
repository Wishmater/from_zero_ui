import 'package:flutter/material.dart';

class TableFromZero extends StatelessWidget {

  List<Map<String, dynamic>> json; //TODO 2 also allow a List<List<String>>
  List<String> jsonColumnKeys;
  List<String> columnNames;
  List<TextStyle> columnStyles;
  List<TextAlign> columnAlignments;
  List<int> columnFlexes;
  List<Color> backgroundColors;
  bool useColumnInsteadOfBuilder;
  double itemHeight;


  TableFromZero({
    this.json,
    this.jsonColumnKeys,
    this.columnNames,
    this.columnStyles,
    this.columnAlignments,
    this.columnFlexes,
    this.useColumnInsteadOfBuilder = false,
    this.backgroundColors,
    this.itemHeight = 38,
  }) {
    if (columnFlexes==null) columnFlexes = [];
    while (columnFlexes.length < columnNames.length){
      columnFlexes.add(1);
    }
    if (columnAlignments==null) columnAlignments = [];
    while (columnAlignments.length < columnNames.length){
      columnAlignments.add(TextAlign.end);
    }
    if (backgroundColors==null) backgroundColors = [];
    while (backgroundColors.length < columnNames.length){
      backgroundColors.add(Colors.transparent);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (columnStyles==null) columnStyles = [];
    while (columnStyles.length < columnNames.length){
      columnStyles.add(Theme.of(context).textTheme.bodyText1);
    }
    if (useColumnInsteadOfBuilder){
      return Column(
        children: List.generate((json.length+1)*2, (index) => _getRow(context, index)),
      );
    } else{
      //TODO 2 test this
      return ListView.builder(
        itemCount: (json.length+1)*2,
        itemBuilder: _getRow,
      );
    }
  }


  Widget _getRow(BuildContext context, int i){
    if (i%2!=0) return Divider(height: 1,);
    i = i~/2;
    if (i==0){
      return Container(
        height: itemHeight,
        child: Row(
          children: List.generate(columnNames.length, (j) {
            while(j>=columnNames.length)
              j -= columnNames.length-1;
            return Expanded(
              child: Container(
                decoration: backgroundColors[j]!=Colors.transparent ? BoxDecoration(
                    gradient: LinearGradient( //TODO 2 add an option to disable gradient
                        colors: [
                          backgroundColors[j].withOpacity(0),
                          backgroundColors[j].withOpacity(backgroundColors[j].opacity*0.5),
                          backgroundColors[j].withOpacity(backgroundColors[j].opacity*0.5),
                          backgroundColors[j].withOpacity(0), //TODO 2 allow this to support both alignments
                        ],
                        stops: [
                          0,
                          0.45,
                          0.9,
                          1,
                        ]
                    )
                ) : null,
                height: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal:  12.0),
                child: Container(
                  width: double.infinity,
                  child: Text(
                    columnNames[j],
                    style: Theme.of(context).textTheme.subtitle2,
                    textAlign: columnAlignments[j],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    } else{
      i--;
      return Container(
        height: itemHeight,
        child: Row(
          children: List.generate(columnNames.length, (j) {
            while(j>=columnNames.length)
              j -= columnNames.length-1;
            return Expanded(
              child: Container(
                decoration: backgroundColors[j]!=Colors.transparent ? BoxDecoration(
                  gradient: LinearGradient( //TODO 2 add an option to disable gradient
                    colors: [
                      backgroundColors[j].withOpacity(0),
                      backgroundColors[j],
                      backgroundColors[j],
                      backgroundColors[j].withOpacity(0), //TODO 2 allow this to support both alignments
                    ],
                    stops: [
                      0,
                      0.45,
                      0.9,
                      1,
                    ]
                  )
                ) : null,
                height: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: double.infinity,
                  child: Text(
                    json[i][jsonColumnKeys[j]] == null ? ""
                        : json[i][jsonColumnKeys[j]].toString(),
                    style: columnStyles[j],
                    textAlign: columnAlignments[j],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }
  }

}
