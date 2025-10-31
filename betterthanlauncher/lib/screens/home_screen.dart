import 'dart:io';
import 'package:flutter/material.dart';
import '../components/round_icon_button.dart';
import '../components/top_left_border_painter.dart';
import '../themes/theme_manager.dart';
import '../service/instance_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;
    final double topBarHeight = 80;
    final double leftBarWidth = 80;

    return Scaffold(
      backgroundColor: theme.components,
      body: Stack(
        children: [
          Positioned(
            top: topBarHeight,
            left: leftBarWidth,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              painter: TopLeftBorderPainter(
                backgroundColor: theme.background,
                borderColor: theme.components3,
                borderWidth: 1,
                radius: 20,
              ),
              child: ValueListenableBuilder(
                valueListenable: InstanceManager().instances,
                builder: (context, instanceList, _) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: instanceList.isEmpty
                        ? Center(
                            child: Text(
                              "No Instances Found",
                              style: TextStyle(
                                color: theme.text2,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: instanceList.length,
                            itemBuilder: (context, i) {
                              final name = instanceList[i]
                                  .path
                                  .split(Platform.pathSeparator)
                                  .last;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.components,
                                    borderRadius: BorderRadius.circular(10),
                                    //border: Border.all(color: theme.components3, width: 1),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      name,
                                      style: TextStyle(
                                        color: theme.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: Icon(Icons.play_arrow, color: theme.text),
                                    onTap: () {
                                      // TODO: Launch instance screen
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBarHeight,
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    'assets/icons/title.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: topBarHeight,
            left: 0,
            width: leftBarWidth,
            bottom: 0,
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  RoundIconButton(
                    icon: Icon(Icons.home, color: theme.text2),
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),
                  
                  RoundIconButton(
                    icon: Icon(Icons.add, color: theme.text2),
                    onPressed: () async {
                      await InstanceManager().createInstance("Instance_${DateTime.now().millisecondsSinceEpoch}");
                    },
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: theme.text, thickness: 1, height: 24),
                  ),

                  RoundIconButton(
                    icon: Icon(Icons.checkroom, color: theme.text2),
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: theme.text, thickness: 1, height: 24),
                  ),

                  RoundIconButton(
                    icon: Icon(Icons.settings, color: theme.text2),
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),
                  
                  RoundIconButton(
                    icon: Icon(Icons.discord, color: theme.text2), 
                    onPressed: () {},
                    normalColor: theme.components4,
                    hoverColor: theme.components5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
