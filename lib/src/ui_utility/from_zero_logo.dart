import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:wave/config.dart';
// import 'package:wave/wave.dart';


class FromZeroBanner extends StatelessWidget {

  final double logoSizePercentage;


  const FromZeroBanner({super.key, this.logoSizePercentage=0.6});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade900,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Expanded(
                flex: 4,
                child: Transform.rotate(
                  angle: pi,
//                   child: WaveWidget(
//                     config: CustomConfig(
// //            gradients: [
// //              [Colors.red, Color(0xEEF44336)],
// //              [Colors.red[800], Color(0x77E57373)],
// //              [Colors.orange, Color(0x66FF9800)],
// //              [Colors.yellow, Color(0x55FFEB3B)]
// //            ],
// //            gradientBegin: Alignment.bottomLeft,
// //            gradientEnd: Alignment.topRight,
//                       durations: [35000, 19440, 10800, 6000],
//                       heightPercentages: [0.20, 0.23, 0.25, 0.30],
// //            heightPercentages: [0.16, 0.17, 0.18, 0.20],
// //            blur: MaskFilter.blur(BlurStyle.solid, 10),
// //            colors: [
// //              Colors.white70,
// //              Colors.white54,
// //              Colors.white30,
// //              Colors.white24,
// //            ],
//                       colors: [
//                         Colors.black54,
//                         Colors.black45,
//                         Colors.black26,
//                         Colors.black12,
//                       ],
//                     ),
//                     waveAmplitude: 2,
//                     backgroundColor: Colors.blue.shade900,
//                     heightPercentange: 0.5,
//                     size: Size(
//                       double.infinity,
//                       double.infinity,
//                     ),
//                   ),
                ),
              ),
              Expanded(flex: 1,child: Container(),),
            ],
          ),
          FractionallySizedBox(
            heightFactor: logoSizePercentage,
            widthFactor: logoSizePercentage,
            child: const FromZeroLogo(),
          ),
        ],
      ),
    );
  }

}


class FromZeroLogo extends StatelessWidget {
  const FromZeroLogo({super.key});


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = min(constraints.maxWidth, constraints.maxHeight);
        double fontSize = size*0.45;
        return Align(
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness==Brightness.light ? Colors.white : Colors.black)
                  .withOpacity(0.6),
              borderRadius: BorderRadius.all(Radius.circular(size/8)),
            ),
            height: size,
            width: size,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: size/12,),
                Text("From",
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.libreCaslonDisplay(
                    fontSize: fontSize,
                    color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.6),
                    height: 0.78,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text("Zero",
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.libreCaslonDisplay(
                    fontSize: fontSize,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    height: 0.78,
                      fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

  }

}
