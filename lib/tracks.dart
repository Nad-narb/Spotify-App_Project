import 'package:flutter/material.dart';
import 'package:spotifysdk/genres.dart';
import 'package:spotifysdk/main.dart';
import './spotifyInteraction.dart';
import 'package:animated_button_bar/animated_button_bar.dart';
import 'artists.dart';
import 'genres.dart';
import 'recentlyPlayed.dart';
import 'main.dart';
import 'package:gif/gif.dart';


class TracksPage extends StatefulWidget {
  TracksPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _TracksPageState createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> with TickerProviderStateMixin{
  late final GifController controller1;
  List<dynamic> _tracksShort = [];  //holds all song information for the past 4 weeks
  List<dynamic> _tracksMedium = []; //holds all song information for the past 6 months
  List<dynamic> _tracksLong = []; //holds all song information for tje past year
  String? _currentlyPlayingTrackUri; //holds the Uri of current track thats playing
  int _selectedTimeRange = 0; //Selected time range of songs
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _error;

  Future<void> _loadTopTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tracksShort = await getTopTracksShort(); //Get top songs from past 4 weeks
      final tracksMedium = await getTopTracksMedium(); // Get top songs from past 6 months
      final tracksLong = await getTopTracksLong(); // get top songs from past year
      setState(() {
        _tracksShort = tracksShort; // Put the songs in their respective lists
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
    controller1 = GifController(vsync: this);
    _loadTopTracks(); //Loads songs before showing the UI
    super.initState();
  }

  //This method determines that happens to the song when the user presses the play/pause button
  Future<void> playPause(String trackUri) async {
    try {
      if (_currentlyPlayingTrackUri == trackUri && _isPlaying) {
        //When the user presses the play/pause button and the buttons song is the same
        //as the current song thats playing it will call the pauseTrack() method to stop the song
        await pauseTrack();
        setState(() {
          _isPlaying = false; //isPlaying set to false because song paused
        });
      } else {
        //If the user presses the play/pause button and the current track, is different
        //than the buttons track, the buttons track will begin playing.
        await playTrack(trackUri);
        setState(() {
          _currentlyPlayingTrackUri = trackUri; //The currentPlayingTrack is now set to the new track thats playing
          _isPlaying = true; //_isPlaying set to true because song is playing
        });
      }
    } catch (e) {
      //Spotify Api requires the user to have Spotify open in the background to play/pause songs
      //If Spotify is not open a small error message will popup from the bottom of the app
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _currentlyPlayingTrackUri = null; //if error -> no song playing
        _isPlaying = false;
      });
    }
  }

  /*
  The user can select 3 different time ranges. 4 weeks, 6 months, and 12 months.
  Depending on which option the user selects, there is a switch which returns
  the correct track list.
   */
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
              onPressed: () { Scaffold.of(context).openDrawer();
              }, //When the user presses the burger icon the drawer will open
            );
          },
        ),
        //Refresh button at the top of the page which reloads calls the api
        //to get the top tracks again
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
            DrawerHeader(
              decoration: BoxDecoration(),
              //Displays a gif in the drawer header
              child: Gif(
                fps: 30,
                autostart: Autostart.loop,
                image: AssetImage('assets/cassette.gif'),
                fit: BoxFit.cover,
              ),
            ),
            //Drawer displays a list of pages that the user can select.
            ListTile(
              title: const Text('Tracks', style: TextStyle(color: Color(0xFF1ED760), fontWeight: FontWeight.bold, fontSize: 20)),
              onTap: () {
                Navigator.pop(context); //User already on track page so they will not move when they click this button
              },
            ),
            ListTile(
              title: const Text('Artists', style: TextStyle(color: Colors.white, fontSize: 20)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArtistsPage(title: "Artists")), //moves the user to the top artists page
                );
              },
            ),
            ListTile(
              title: const Text('Genres', style: TextStyle(color: Colors.white, fontSize: 20)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BarChartSample1(title: "Genres")), //move user to top genre page
                );
              },
            ),
            ListTile(
              title: const Text('Recently Played' , style: TextStyle(color: Colors.white, fontSize: 20)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecentlyPlayedPage(title: "Recently Played")), //move user to recently played page
                );
              },
            ),
            ListTile(
              title: const Text('Logout' , style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                SpotifyService.logout(); //deletes all information stored in secure_storage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage(title: "Spotilytics")), //logs the user out
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
                //This Button bar allows the user to select between ranges. When the user taps one of the buttons
                //The page will refresh and display the tracks in the respective time range.
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
              itemCount: _currentTracks.length, //get number of tracks returned by api call
              itemBuilder: (context, index) {
                final track = _currentTracks[index] as Map<String, dynamic>; //variable track gets current track in Map
                final rank = index + 1;
                //Extracts artists name from track object and formats them as a string. If no artists found return 'unknown artist'
                final artists = (track['artists'] as List?)?.map<String>((a) => (a as Map)['name'] as String? ?? '').join(', ') ?? 'Unknown artist';

                //creates a card for each track that is being displayed
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
                          //displays the rank of the song
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
                          //extracts the first album cover image, otherwise display music note
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
                        // Displays the name of the track along with the artist name
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
                                ? Icons.pause //if song is playing display a pause icon
                                : Icons.play_arrow, //if there is no track playing display a play arrow
                          ),
                          color: Color(0xFF1ED760),
                          onPressed: () async {
                            final trackUri = track["uri"] as String; //when button is pressed trackUri gets song that will be played
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