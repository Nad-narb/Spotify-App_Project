import 'package:flutter/material.dart';
import './spotifyInteraction.dart';
import 'package:animated_button_bar/animated_button_bar.dart';
import 'package:gif/gif.dart';
import 'tracks.dart';
import 'genres.dart';
import 'recentlyPlayed.dart';
import 'main.dart';

class ArtistsPage extends StatefulWidget {
  ArtistsPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _ArtistsPageState createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> with TickerProviderStateMixin{
  late final GifController controller1;
  int _fps = 30;
  List<dynamic> _artistsShort = [];
  List<dynamic> _artistsMedium = [];
  List<dynamic> _artistsLong = [];
  int _selectedTimeRange = 0;
  bool _isLoading = false;
  String? _error;

  Future<void> _loadTopArtists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final artistsShort = await getTopArtistsShort();
      final artistsMedium = await getTopArtistsMedium();
      final artistsLong = await getTopArtistsLong();
      setState(() {
        _artistsShort = artistsShort;
        _artistsMedium = artistsMedium;
        _artistsLong = artistsLong;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    controller1 = GifController(vsync: this);
    _loadTopArtists();
    super.initState();
  }

  List<dynamic> get _currentArtists {
    switch (_selectedTimeRange) {
      case 0:
        return _artistsShort;
      case 1:
        return _artistsMedium;
      case 2:
        return _artistsLong;
      default:
        return _artistsShort;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [IconButton(
          icon:Icon(Icons.refresh),
          onPressed: _loadTopArtists,
        ),
        ],
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
              title: const Text('Tracks', style: TextStyle(color: Colors.white, fontSize: 20)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TracksPage(title: "Top Tracks")),
                );
              },
            ),
            ListTile(
              title: const Text('Artists', style: TextStyle(color: Color(0xFF1ED760), fontWeight: FontWeight.bold, fontSize: 20)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Genres', style: TextStyle(color: Colors.white, fontSize: 20)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BarChartSample1(title: "Top Genres")),
                );
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
      body: Column(
        children: [
          // Time range selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedButtonBar(
              radius: 8.0,
              padding: const EdgeInsets.all(16.0),
              backgroundColor: const Color(0xFF202020),
              foregroundColor: Color(0xFF1ED760),
              elevation: 2,
              borderColor: const Color(0xFF1ED760),
              borderWidth: 2,
              innerVerticalPadding: 8,
              children: [
                ButtonBarEntry(
                  onTap: () => setState(() => _selectedTimeRange = 0),
                  child: Text('4 Weeks', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),),
                ),
                ButtonBarEntry(
                  onTap: () => setState(() => _selectedTimeRange = 1),
                  child: Text('6 Months', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),),
                ),
                ButtonBarEntry(
                  onTap: () => setState(() => _selectedTimeRange = 2),
                  child: Text('12 Months', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),),
                ),
              ],
            ),
          ),
          // Artist list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color:Color(0xFF1ED760)))
                : _error != null
                ? Center(child: Text(_error!))
                : _currentArtists.isEmpty
                ? const Center(child: Text('No artists found'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _currentArtists.length,
              itemBuilder: (context, index) {
                final artist = _currentArtists[index] as Map<String, dynamic>;
                final rank = index + 1;
                final genres = (artist['genres'] as List<dynamic>?)?.join(', ') ?? 'No genres listed';

                return Card(
                  color: Color(0xFF252525),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Rank number
                        Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1ED760),
                            ),
                          ),
                        ),
                        // Artist image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (artist['images'] as List?)?.isNotEmpty ?? false
                              ? Image.network(
                            (artist['images'][0] as Map)['url'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Artist info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (artist['name'] as String?) ?? 'Unknown Artist',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFFFFF),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                genres,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}