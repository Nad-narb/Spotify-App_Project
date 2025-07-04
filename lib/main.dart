import 'package:flutter/material.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracks.dart';
import './spotifyInteraction.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await SpotifyService.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color:Color(0xFF1ED760))),
      );
    }

    return _isLoggedIn ? TracksPage(title: "Tracks") : const MyHomePage(title: 'Spotilytics');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  String? _error;

  Future<void> _authenticateWithSpotify() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await SpotifyService.authenticate();
      if (token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TracksPage(title: "Tracks")),
        );
      } else {
        setState(() {
          _error = 'Authentication failed. Please try again.';
          _isLoading = false;
        });
      }
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
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Color(0x000000F2),
        title: Text(widget.title,
          style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 30,),),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    const Icon(Icons.music_note, size: 50, color: Color(0xFF1ED760)),
                    const SizedBox(height: 20),
                    Text(
                      'Connect to Spotify',
                      style: TextStyle(color: Color(0xFF1ED760)),
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
                      icon: const Icon(Icons.music_note,
                      color: Colors.white),
                      label: const Text('Login with Spotify', style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1ED760),
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