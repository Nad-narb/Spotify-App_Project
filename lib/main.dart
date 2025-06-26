import 'package:flutter/material.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracks.dart';
import './spotifyInteraction.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotilytics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Spotilytics'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AccessTokenResponse? _token;
  bool _isLoading = false;
  String? _error;

  Future<void> _authenticateWithSpotify() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await SpotifyService.authenticate();
      setState(() {
        _token = token;
        _isLoading = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TracksPage(title: "Tracks")),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to authenticate: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget> [
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_token != null)
                Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 50),
                    const SizedBox(height: 20),
                    Text(
                      'Successfully authenticated!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Access token: ${_token!.accessToken!.substring(0, 10)}...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const Icon(Icons.music_note, size: 50),
                    const SizedBox(height: 20),
                    Text(
                      'Connect to Spotify',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: _authenticateWithSpotify,
                      icon: const Icon(Icons.music_note),
                      label: const Text('Login with Spotify'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}