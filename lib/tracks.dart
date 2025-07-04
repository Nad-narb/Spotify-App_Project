import 'package:flutter/material.dart';
import 'package:spotifysdk/genres.dart';
import 'package:spotifysdk/main.dart';
import './spotifyInteraction.dart';
import 'package:animated_button_bar/animated_button_bar.dart';
import 'artists.dart';
import 'genres.dart';
import 'recentlyPlayed.dart';
import 'main.dart';


class TracksPage extends StatefulWidget {
  TracksPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _TracksPageState createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
  List<dynamic> _tracksShort = [];
  List<dynamic> _tracksMedium = [];
  List<dynamic> _tracksLong = [];
  String? _currentlyPlayingTrackUri;
  int _selectedTimeRange = 0;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _error;

  Future<void> _loadTopTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tracksShort = await getTopTracksShort();
      final tracksMedium = await getTopTracksMedium();
      final tracksLong = await getTopTracksLong();
      setState(() {
        _tracksShort = tracksShort;
        _tracksMedium = tracksMedium;
        _tracksLong = tracksLong;
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
    super.initState();
    _loadTopTracks();
  }

  Future<void> playPause(String trackUri) async {
    try {
      if (_currentlyPlayingTrackUri == trackUri && _isPlaying) {
        // Pause if currently playing this track
        await pauseTrack();
        setState(() {
          _isPlaying = false;
        });
      } else {
        // Play if different track or not playing
        await playTrack(trackUri);
        setState(() {
          _currentlyPlayingTrackUri = trackUri;
          _isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _currentlyPlayingTrackUri = null;
        _isPlaying = false;
      });
    }
  }

  List<dynamic> get _currentTracks {
    switch (_selectedTimeRange) {
      case 0:
        return _tracksShort;
      case 1:
        return _tracksMedium;
      case 2:
        return _tracksLong;
      default:
        return _tracksShort;
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
              onPressed: () {                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [IconButton(
          icon:Icon(Icons.refresh),
          onPressed: _loadTopTracks,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Color(0xFF181818),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Tracks', style: TextStyle(color: Color(0xFF1ED760), fontWeight: FontWeight.bold, fontSize: 20)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Artists', style: TextStyle(color: Colors.white, fontSize: 20)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArtistsPage(title: "Artists")),
                );
              },
            ),
            ListTile(
              title: const Text('Genres', style: TextStyle(color: Colors.white, fontSize: 20)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BarChartSample1(title: "Genres")),
                );
              },
            ),
            ListTile(
              title: const Text('Recently Played' , style: TextStyle(color: Colors.white, fontSize: 20)),
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
                SpotifyService.logout();
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
          // Track list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color:Color(0xFF1ED760)))
                : _error != null
                ? Center(child: Text(_error!))
                : _currentTracks.isEmpty
                ? const Center(child: Text('No tracks found'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _currentTracks.length,
              itemBuilder: (context, index) {
                final track = _currentTracks[index] as Map<String, dynamic>;
                final rank = index + 1;
                final artists = (track['artists'] as List?)?.map<String>((a) => (a as Map)['name'] as String? ?? '').join(', ') ?? 'Unknown artist';

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
                        // Track image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (track['album'] as Map<String, dynamic>?)?['images'] is List
                              ? (track['album']['images'] as List).isNotEmpty
                              ? Image.network(
                            (track['album']['images'][0] as Map)['url'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: Icon(Icons.music_note, size: 30, color: Colors.grey[600]),
                          )
                              : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: Icon(Icons.music_note, size: 30, color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Track info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (track['name'] as String?) ?? 'Unknown track',
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
                                artists,
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
                        // Play button
                        IconButton(
                          icon: Icon(
                            _currentlyPlayingTrackUri == track['uri'] && _isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          color: Color(0xFF1ED760),
                          onPressed: () async {
                            final trackUri = track["uri"] as String;
                            await playPause(trackUri);
                          },
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