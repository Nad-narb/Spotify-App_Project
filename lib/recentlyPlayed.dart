import 'package:flutter/material.dart';
import 'package:spotifysdk/genres.dart';
import './spotifyInteraction.dart';
import 'package:animated_button_bar/animated_button_bar.dart';
import 'artists.dart';
import 'genres.dart';
import 'tracks.dart';
import 'package:intl/intl.dart';

class RecentlyPlayedPage extends StatefulWidget {
  RecentlyPlayedPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _RecentlyPlayedPageState createState() => _RecentlyPlayedPageState();
}

class _RecentlyPlayedPageState extends State<RecentlyPlayedPage> {
  List<dynamic> _recentTracks = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _loadRecentlyPlayed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final recentTracks = await getRecentlyPlayed();
      setState(() {
        _recentTracks = recentTracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatTimeAgo(String playedAt) {
    try {
      final dateTime = DateTime.parse(playedAt).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds} seconds ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours == 1){
        return '${difference.inHours} hour ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1){
        return '${difference.inDays} day ago';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, y').format(dateTime);
      }
    } catch (e) {
      return playedAt;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecentlyPlayed();
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
              title: const Text('Tracks', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TracksPage(title: "Tracks")),
                );
              },
            ),
            ListTile(
              title: const Text('Artists', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArtistsPage(title: "Artists")),
                );
              },
            ),
            ListTile(
              title: const Text('Genres', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BarChartSample1(title: "Genres")),
                );
              },
            ),
            ListTile(
              title: const Text('Recently Played', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Track list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _recentTracks.isEmpty
                ? const Center(child: Text('No tracks found'))
                : ListView.builder(
              itemCount: _recentTracks.length,
              itemBuilder: (context, index) {
                final track = _recentTracks[index] as Map<String, dynamic>;
                final trackItem = track['track'] ?? track;
                final playedAt = track['played_at'] as String? ?? '';

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading:(trackItem['album'] as Map<String, dynamic>?)?['images'] is List
                          ? (trackItem['album']['images'] as List).isNotEmpty
                          ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        (trackItem['album']['images'][0] as Map)['url'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(Icons.music_note, size: 50)
                        : const Icon(Icons.music_note, size: 50),

                    title: Text(
                      (trackItem['name'] as String?) ?? 'Unknown track',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (trackItem['artists'] as List?)?.map<String>((a) => (a as Map)['name'] as String? ?? '').join(', ') ?? 'Unknown artist',
                        ),
                        if (playedAt.isNotEmpty)
                          Text(
                            _formatTimeAgo(playedAt),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: Icon(Icons.play_arrow),
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