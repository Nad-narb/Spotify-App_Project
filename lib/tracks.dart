import 'package:flutter/material.dart';
import 'package:spotifysdk/genres.dart';
import './spotifyInteraction.dart';
import 'package:animated_button_bar/animated_button_bar.dart';
import 'artists.dart';
import 'genres.dart';
import 'recentlyPlayed.dart';

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
  int _selectedTimeRange = 0;
  bool _isLoading = false;
  String? _error;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
              title: const Text('Tracks'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Artists'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArtistsPage(title: "Artists")),
                );
              },
            ),
            ListTile(
              title: const Text('Genres'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BarChartSample1(title: "Genres")),
                );
              },
            ),
            ListTile(
              title: const Text('Recently Played'),
              selected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecentlyPlayedPage(title: "Recently Played")),
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
              backgroundColor: Theme.of(context).colorScheme.background,
              foregroundColor: Theme.of(context).colorScheme.primary,
              elevation: 2,
              borderColor: Theme.of(context).colorScheme.primary,
              borderWidth: 2,
              innerVerticalPadding: 8,
              children: [
                ButtonBarEntry(
                  onTap: () => setState(() => _selectedTimeRange = 0),
                  child: Text('4 Weeks'),
                ),
                ButtonBarEntry(
                  onTap: () => setState(() => _selectedTimeRange = 1),
                  child: Text('6 Months'),
                ),
                ButtonBarEntry(
                  onTap: () => setState(() => _selectedTimeRange = 2),
                  child: Text('12 Months'),
                ),
              ],
            ),
          ),
          // Track list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                              color: Colors.grey[600],
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
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                artists,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Play button
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            // Add play functionality here
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