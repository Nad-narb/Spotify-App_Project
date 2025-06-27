import 'package:flutter/material.dart';
import './spotifyInteraction.dart';
import 'package:animated_button_bar/animated_button_bar.dart';
import 'tracks.dart';
import 'genres.dart';
import 'recentlyPlayed.dart';

class ArtistsPage extends StatefulWidget {
  ArtistsPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _ArtistsPageState createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  List<dynamic> _artistsShort = [];
  List<dynamic> _artistsMedium = [];
  List<dynamic> _artistsLong = [];
  int _selectedTimeRange = 0;
  bool _isLoading = false;
  String? _error;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadTopArtists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Then get top artists
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
    super.initState();
    _loadTopArtists();
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TracksPage(title: "Tracks")),
                );
              },
            ),
            ListTile(
              title: const Text('Artists'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
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
                : _currentArtists.isEmpty
                ? const Center(child: Text('No Artists found'))
                : ListView.builder(
              itemCount: _currentArtists.length,
              itemBuilder: (context, index) {
                final artist = _currentArtists[index] as Map<String, dynamic>;
                return ListTile(
                  leading: (artist['images'] as List?)?.isNotEmpty ?? false
                      ? Image.network((artist['images'][0] as Map)['url'])
                      : const Icon(Icons.person),
                  title: Text((artist['name'] as String?) ?? 'Unknown Artist'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}