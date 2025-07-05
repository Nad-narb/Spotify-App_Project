import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'artists.dart';
import 'tracks.dart';
import 'spotifyInteraction.dart';
import 'recentlyPlayed.dart';
import 'main.dart';
import 'package:gif/gif.dart';

class BarChartSample1 extends StatefulWidget {
  BarChartSample1({Key? key, required this.title}) : super(key: key);
  final String title;

  List<Color> get availableColors => const <Color>[
    Color(0xFFa8e6cf),
    Color(0xFFdcedc1),
    Color(0xFFffd3b6),
    Color(0xFFc4f6ff),
    Color(0xFFffaaa5),
    Color(0xFFff8b94),
  ];

  final Color barBackgroundColor = Color(0xFF303030);
  final Color barColor = Colors.green;
  final Color touchedBarColor = Color(0xFF1ED760);

@override
State<StatefulWidget> createState() => BarChartSample1State();
}
class BarChartSample1State extends State<BarChartSample1> with TickerProviderStateMixin {
  late final GifController controller1;
  Map<String, List<String>> genreMap = {}; //Will hold the genre along with the artists associated with the genres
  List<String> genreKeys = []; //List that will hold the top genres
  final Duration animDuration = const Duration(milliseconds: 250);
  bool isLoading = true;
  int touchedIndex = -1;
  bool isPlaying = false;


  @override
  void initState() {
    controller1 = GifController(vsync: this);
    _loadGenreData();
    super.initState();
  }

  Future<void> _loadGenreData() async {
    try {
      final loadedGenreMap = await getTopGenres(); //getTopGenres will return a Map with genres as keys and artists as values
      setState(() {
        genreMap = loadedGenreMap;
        genreKeys = loadedGenreMap.keys.toList(); //genreKeys will just get the list of genres
                                                  // (so I can access them via indexes without knowing the genres)
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

  /*
  When the user clicks in the bar it will display some of their top artists
  This method just selects which artists to display
   */
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
      return const Center(child: CircularProgressIndicator(color:Color(0xFF1ED760)));
    }
    if(genreKeys.isEmpty){
      return const Center(child: Text("No genre data available"));
    }
    return Scaffold(
        backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Color(0x000000F2),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(widget.title,
          style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 30,),),
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
      backgroundColor: Color(0xFF181818),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(),
            child: Gif(
              fps: 30,
              autostart: Autostart.loop,
              image: AssetImage('assets/cassette.gif'),
              fit: BoxFit.cover,
            ),
          ),
          ListTile(
            title: const Text('Top Tracks', style: TextStyle(color: Colors.white, fontSize: 20)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TracksPage(title: "Tracks")),
              );
            },
          ),
          ListTile(
            title: const Text('Top Artists', style: TextStyle(color: Colors.white, fontSize: 20)),
            onTap: () {
              Navigator.push(
              context,
                MaterialPageRoute(builder: (context) => ArtistsPage(title: "Artists")),
              );
            },
          ),
          ListTile(
            title: const Text('Top Genres', style: TextStyle(color: Color(0xFF1ED760), fontWeight: FontWeight.bold, fontSize: 20)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Recently Played', style: TextStyle(color: Colors.white, fontSize: 20)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecentlyPlayedPage(title: "Recently Played")),
              );
            },
          ),
          ListTile(
            title: const Text('Logout' , style: TextStyle(color: Colors.white, fontSize: 16)),
            onTap: () {
              logout;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage(title: "Spotilytics")),
              );
            },
          ),
        ],
      ),
    ),
      /*
      This part of the code was copied from the fl_chart source code. They had premade
      bar charts which I wanted to use and I just changed some parts of the code
      to make it work with the data I wanted to display
      Im will add comments to the code which I modified
       */
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
                Text(
                  'Past 6 Months',
                  style: TextStyle(
                    color: Color(0xFF1ED760),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 38,
                ),
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
                  color: Color(0xFF1ED760),
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
              : const BorderSide(color: Colors.black, width: 0),
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
    //The size of each bar group will be determined by the number of artist in each genre
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
                genre = getArtists(genreMap[genreKeys[0]] as List<String>); //Gets the top artists from each genre
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
              'Top Artists:\n$genre\n', //displays the artists when user clicks on the bar
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
        text = Text(genreKeys[0].replaceAll(' ', '\n'), style: style); //Displays the genre names under each bar group
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