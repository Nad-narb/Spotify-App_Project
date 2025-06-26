import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'artists.dart';
import 'tracks.dart';
import 'spotifyInteraction.dart';

class BarChartSample1 extends StatefulWidget {
  BarChartSample1({Key? key, required this.title}) : super(key: key);
  final String title;

  List<Color> get availableColors => const <Color>[
    Colors.purple,
    Colors.yellow,
    Colors.blue,
    Colors.orange,
    Colors.pink,
    Colors.red,
  ];

  final Color barBackgroundColor = Colors.white;
  final Color barColor = Colors.blue;
  final Color touchedBarColor = Colors.green;

@override
State<StatefulWidget> createState() => BarChartSample1State();
}
class BarChartSample1State extends State<BarChartSample1> {
  Map<String, List<String>> genreMap = {};
  List<String> genreKeys = [];
  final Duration animDuration = const Duration(milliseconds: 250);
  bool isLoading = true;
  int touchedIndex = -1;
  bool isPlaying = false;


  @override
  void initState() {
    debugPrint("Reached genre page");
    _loadGenreData();
    super.initState();
  }

  Future<void> _loadGenreData() async {
    try {
      final loadedGenreMap = await getTopGenres();
      setState(() {
        genreMap = loadedGenreMap;
        genreKeys = loadedGenreMap.keys.toList();
        isLoading = false;
      });
    }
    catch (e) {
      debugPrint("Error loading genre data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String getArtists(List<String> artists) {
    int len = artists.length;
    String str;
    if(len == 1){
      str = artists[0];
    }
    else if(len == 2){
      str = artists[0] + "\n" + artists[1];
    }
    else if(len > 3){
      str = artists[0] + "\n" + artists[1]+ "\n" + artists[2];
    }
    else {
      str = "no artists found";
    }
    return str;
  }


  @override
  Widget build(BuildContext context) {
    if(isLoading){
      return const Center(child: CircularProgressIndicator());
    }
    if(genreKeys.isEmpty){
      return const Center(child: Text("No genre data available"));
    }
    return Scaffold(backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text(widget.title),
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
    ),
    drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Drawer Header'),
          ),
          ListTile(
            title: const Text('Top Tracks'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Top Artists'),
            onTap: () {
              Navigator.push(
              context,
                MaterialPageRoute(builder: (context) => ArtistsPage(title: "Artists")),
              );
            },
          ),
          ListTile(
            title: const Text('Top Genres'),
            onTap: () {
            },
          ),
        ],
      ),
    ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            children: [
        Expanded(
        child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                /*
                const SizedBox(
                  height: 38,
                ),
                const Text(
                  'Top Genres',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'Past 6 Months',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 38,
                ),
                */
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: BarChart(
                      isPlaying ? randomData() : mainBarData(),
                      duration: animDuration,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.green,
                ),
                onPressed: () {
                  setState(() {
                    isPlaying = !isPlaying;
                    if (isPlaying) {
                      refreshState();
                    }
                  });
                },
              ),
            ),
          )
        ],
      ),
      ),
    ],
    ),
      ),
    );
  }

  BarChartGroupData makeGroupData(
      int x,
      double y, {
        bool isTouched = false,
        Color? barColor,
        double width = 20,
        List<int> showTooltips = const [],
      }) {
    barColor ??= widget.barColor;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 5 : y,
          color: isTouched ? widget.touchedBarColor : barColor,
          width: width,
          borderSide: isTouched
              ? BorderSide(color: widget.touchedBarColor)
              : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: widget.barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingGroups() => List.generate(5, (i) {
    switch (i) {
      case 0:
        var l1 = (genreMap[genreKeys[0]]!.length).toDouble()*.5;
        return makeGroupData(0, l1, isTouched: i == touchedIndex);
      case 1:
        var l2 = (genreMap[genreKeys[1]]!.length).toDouble()*.5;
        return makeGroupData(1, l2, isTouched: i == touchedIndex);
      case 2:
        var l3 = (genreMap[genreKeys[2]]!.length).toDouble()*.5;
        return makeGroupData(2, l3, isTouched: i == touchedIndex);
      case 3:
        var l4 = (genreMap[genreKeys[3]]!.length).toDouble()*.5;
        return makeGroupData(3, l4, isTouched: i == touchedIndex);
      case 4:
        var l5 = (genreMap[genreKeys[4]]!.length).toDouble()*.5;
        return makeGroupData(4, l5, isTouched: i == touchedIndex);
      default:
        return throw Error();
    }
  });

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.blueGrey,
          tooltipHorizontalAlignment: FLHorizontalAlignment.center,
          tooltipMargin: 16,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String genre;
            switch (group.x) {
              case 0:
                genre = getArtists(genreMap[genreKeys[0]] as List<String>);
                break;
              case 1:
                genre = getArtists(genreMap[genreKeys[1]] as List<String>);
                break;
              case 2:
                genre = getArtists(genreMap[genreKeys[2]] as List<String>);
                break;
              case 3:
                genre = getArtists(genreMap[genreKeys[3]] as List<String>);
              case 4:
                genre = getArtists(genreMap[genreKeys[4]] as List<String>);
                break;
              default:
                throw Error();
            }
            return BarTooltipItem(
              'Top Artists:\n$genre\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: (rod.toY - 1).toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white, //widget.touchedBarColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      groupsSpace: 50,
      alignment: BarChartAlignment.center,
      maxY: 25,
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 150,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
      gridData: const FlGridData(show: false),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = Text(genreKeys[0].replaceAll(' ', '\n'), style: style);
        break;
      case 1:
        text = Text(genreKeys[1].replaceAll(' ', '\n'), style: style);
        break;
      case 2:
        text = Text(genreKeys[2].replaceAll(' ', '\n'), style: style);
        break;
      case 3:
        text =  Text(genreKeys[3].replaceAll(' ', '\n'), style: style);
        break;
      case 4:
        text =  Text(genreKeys[4].replaceAll(' ', '\n'), style: style);
        break;
      default:
        text = Text(genreKeys[0].replaceAll(' ', '\n'), style: style);
        break;
    }
    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: text,
    );
  }

  BarChartData randomData() {
    return BarChartData(
      groupsSpace: 50,
      alignment: BarChartAlignment.center,
      maxY: 25,
      barTouchData: const BarTouchData(
        enabled: false,
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 150,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: List.generate(5, (i) {
        switch (i) {
          case 0:
            return makeGroupData(
              0,
              Random().nextInt(10).toDouble()+4,
              barColor: widget.availableColors[
              Random().nextInt(widget.availableColors.length)],
            );
          case 1:
            return makeGroupData(
              1,
              Random().nextInt(10).toDouble()+4,
              barColor: widget.availableColors[
              Random().nextInt(widget.availableColors.length)],
            );
          case 2:
            return makeGroupData(
              2,
              Random().nextInt(10).toDouble()+4,
              barColor: widget.availableColors[
              Random().nextInt(widget.availableColors.length)],
            );
          case 3:
            return makeGroupData(
              3,
              Random().nextInt(10).toDouble()+4,
              barColor: widget.availableColors[
              Random().nextInt(widget.availableColors.length)],
            );
          case 4:
            return makeGroupData(
              4,
              Random().nextInt(4).toDouble()+4,
              barColor: widget.availableColors[
              Random().nextInt(widget.availableColors.length)],
            );
          default:
            return throw Error();
        }
      }),
      gridData: const FlGridData(show: false),
    );
  }

  Future<dynamic> refreshState() async {
    setState(() {});
    await Future<dynamic>.delayed(
      animDuration + const Duration(milliseconds: 50),
    );
    if (isPlaying) {
      await refreshState();
    }
  }
}