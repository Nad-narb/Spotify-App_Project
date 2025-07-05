<!-- ABOUT THE PROJECT -->
## About The Project

[![Product Name Screen Shot][product-screenshot]](https://example.com)

This is an app I created to allow users to view their top songs, artists, genres, and recently played songs.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* Dart
* Flutter
<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

This app was created in Android Studio using the Flutter framework
* [Android Studio Setup](https://developer.android.com/studio/install)
* [Flutter Setup](https://docs.flutter.dev/tools/android-studio)

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/Nad-narb/Spotify-App_Project.git
   ```
2. Enter your API in `spotifyInteraction.dart`
   ```js
   const CLIENT_ID = 'ENTER YOUR API';
   const CLIENT_SECRET = 'ENTER YOUR API';
   ```
3. Change git remote url to avoid accidental pushes to base project
   ```sh
   git remote set-url origin github_username/repo_name
   git remote -v # confirm the changes
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

### Spotify Api Authentication
To use the app the user must grant the application access permissions to their Spotify data and features. This is done with the help of the oauth2_client pluggin.
First we have to create a client to interact with spotify
```dart
class SpotifyOAuth2Client extends OAuth2Client {
  SpotifyOAuth2Client({
    required String redirectUri,
    required String customUriScheme,
  }) : super(
    // Spotify's OAuth2 authorization endpoint
    authorizeUrl: 'https://accounts.spotify.com/authorize',
    // Spotify's token exchange endpoint
    tokenUrl: 'https://accounts.spotify.com/api/token',
    redirectUri: redirectUri,
    customUriScheme: customUriScheme,
  );
}
```

After creating the client the user then has to be redirected to obtain the access token
```dart
static Future<AccessTokenResponse?> authenticate() async {
      try {
        final client = SpotifyOAuth2Client(
          // Custom URI scheme for deep linking back to the app
          customUriScheme: 'my.music.app',
          // The redirect URI that Spotify will call after authorization
          redirectUri: 'my.music.app://callback',
        );

        // Step 1: Request user authorization
        final authResp = await client.requestAuthorization(
          clientId: CLIENT_ID,
          // Forces the approval dialog to show every time (good for testing)
          customParams: {'show_dialog': 'true'},
          // Required permissions/scopes for our application
          scopes: [
            'user-read-private',          // Read user's private info
            'user-read-playback-state',   // Read playback state
            'user-modify-playback-state',  // Control playback
            'user-read-currently-playing', // Get current track
            'user-read-email',             // Read user's email
            'user-top-read',               // Read user's top tracks/artists
            'user-read-recently-played',   // Read recently played tracks
          ],
        );
        final token = await client.requestAccessToken(
          code: authResp.code!,      
          clientId: CLIENT_ID,
          clientSecret: CLIENT_SECRET,
        );
        
        await _storage.write(key: 'access_token', value: token.accessToken);
        await _storage.write(key: 'refresh_token', value: token.refreshToken);

        return token;
      } catch (e) {
        debugPrint('Authentication error: $e');
        return null;
      }
    }
```

### Spotify API interaction
Once obtaining the access token we can now make calls to the Spotify Web API services to get user data.
Below is how we get the users top tracks
```dart
Future<List<dynamic>> getTopTracksShort() async {
  final ACCESS_TOKEN = await SpotifyService.getValidAccessToken();
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/tracks?time_range=short_term&limit=50'),
    headers: {
      "content-type": 'application/json',
      "authorization": 'Bearer $ACCESS_TOKEN',
    },
  );
  if (featuredData.statusCode == 200) {
    final featuredPlaylist = convert.jsonDecode(featuredData.body);
    return featuredPlaylist['items'] as List<dynamic>;
  }
  else {
    throw Exception('Failed to get tracks: ${featuredData.statusCode}');
  }
}
```
Api calls to get top artists, recently played tracks, and genres are very similar to this. The only part that changes is the endpoint

### Play/Pausing Tracks
Playing and pausing tracks requires a Device Id which we can get by calling the Spotify API with the endpoint [https://api.spotify.com/v1/me/player/devices](https://api.spotify.com/v1/me/player/devices)
The user must have spotify open in the background to obtain the spotify id. 
```dart
Future<String> getDeviceId() async {
  // Get valid access token
  final accessToken = await SpotifyService.getValidAccessToken();
  if (accessToken == null) {
    throw Exception('Not authenticated - please login again');
  }

  // Try to get device list
  final response = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/player/devices'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final data = convert.jsonDecode(response.body);
    final devices = data['devices'] as List<dynamic>;

    if (devices.isEmpty) {
      throw Exception('No active devices found. Please open Spotify on your device.');
    }

    // Get first active device or first available device
    final device = devices.firstWhere(
          (d) => d['is_active'] == true,
      orElse: () => devices.first,
    );

    final deviceId = device['id']?.toString();
    if (deviceId == null || deviceId.isEmpty) {
      throw Exception('Invalid device ID received');
    }

    // Store device ID for future use
    await _storage.write(key: 'device_id', value: deviceId);
    return deviceId;
  } else {
    throw Exception('Failed to get devices: ${response.statusCode}');
  }
}
```

After getting the Device Id we can use that in the endpoint to play/pause a song
```dart
Future<void> playTrack(String trackUri) async {
  try {
    int offset = random.nextInt(100) + 10;
    final accessToken = await SpotifyService.getValidAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final deviceId = await getDeviceId();

    final response = await http.put(
      Uri.parse('https://api.spotify.com/v1/me/player/play?device_id=$deviceId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: convert.jsonEncode({
        'uris': [trackUri],
        'position_ms': offset * 1000
      }),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to play track: Please have spotify opened');
    }
  } catch (e) {
    // Clear device ID cache if there's an error
    await _storage.delete(key: 'device_id');
    rethrow;
  }
}

Future<void> pauseTrack() async {
  try {
    final accessToken = await SpotifyService.getValidAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    // Try to get stored device ID first
    String? deviceId = await _storage.read(key: 'device_id');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = await getDeviceId();
    }

    final response = await http.put(
      Uri.parse('https://api.spotify.com/v1/me/player/pause?device_id=$deviceId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to pause playback: Please have spotify opened');
    }
  } catch (e) {
    await _storage.delete(key: 'device_id');
    rethrow;
  }
}

```


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/Nad-narb/Spotify-App_Project/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

Brandan Ly - brandanly0004@gmail.com

Project Link: [https://github.com/Nad-narb/Spotify-App_Project](https://github.com/Nad-narb/Spotify-App_Project)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments
Pluings
* [cupertino_icons](https://pub.dev/packages/cupertino_icons)
* [oauth2_client](https://pub.dev/packages/oauth2_client)
* [google_fonts](https://pub.dev/packages/google_fonts)
* [http](https://pub.dev/packages/http)
* [animated_button_bar](https://pub.dev/packages/animated_button_bar)
* [fl_chart](https://pub.dev/packages/fl_chart)
* [intl](https://pub.dev/packages/intl)
* [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
* [flutter_native_splash](https://pub.dev/packages/flutter_native_splash)
* [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)

<p align="right">(<a href="#readme-top">back to top</a>)</p>
