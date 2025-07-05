import 'dart:ffi';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Custom OAuth2 client for Spotify's authentication flow
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

//ID and Secreet should be in their own .env file
//Ran into problems and couldnt get that to work
//Will try again later
const String CLIENT_ID = 'f211c4add0944080bda55bd11f40dd17';
const String CLIENT_SECRET = 'd520773dd34343a2b2b795913796c5a8';
// Secure storage for persisting tokens
final FlutterSecureStorage _storage = const FlutterSecureStorage();

// Random number generator (though not currently used in this snippet)
Random random = new Random();

  class SpotifyService {
    /// Handles the complete Spotify OAuth2 authentication flow:
    /// 1. Requests user authorization
    /// 2. Exchanges authorization code for tokens
    /// 3. Stores tokens securely
    /// Returns [AccessTokenResponse] on success, null on failure
    static Future<AccessTokenResponse?> authenticate() async {
      //await dotenv.load(fileName: ".env");
      //final CLIENT_ID = dotenv.env['CLIENT_ID'].toString();
      //final CLIENT_SECRET = dotenv.env['CLIENT_SECRET'].toString();
      try {
        // Initialize the custom OAuth2 client with our app's redirect URI
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

        // Step 2: Exchange authorization code for access/refresh tokens
        final token = await client.requestAccessToken(
          code: authResp.code!,            // The authorization code from step 1
          clientId: CLIENT_ID,
          clientSecret: CLIENT_SECRET,
        );

        // Step 3: Securely store the tokens for future use
        await _storage.write(key: 'access_token', value: token.accessToken);
        await _storage.write(key: 'refresh_token', value: token.refreshToken);

        return token;
      } catch (e) {
        // Log any errors during the authentication process
        debugPrint('Authentication error: $e');
        return null;
      }
    }

  //Method for getting a new access token
  static Future<AccessTokenResponse?> refreshAccessToken() async {
    //await dotenv.load(fileName: ".env");
    //final CLIENT_ID = dotenv.env['CLIENT_ID'].toString();
    //final CLIENT_SECRET = dotenv.env['CLIENT_SECRET'].toString();
    try {
      final refreshToken = await _storage.read(key: 'refresh_token'); // get refresh token from storage
      if (refreshToken == null) {
        debugPrint('No refresh token available');
        return null;
      }

      final client = SpotifyOAuth2Client(
        customUriScheme: 'my.music.app',
        redirectUri: 'my.music.app://callback',
      );

      //Use the refresh token to get the new access token
      final token = await client.refreshToken(
        refreshToken,
        clientId: CLIENT_ID,
        clientSecret: CLIENT_SECRET,
      );

      // Update stored tokens
      await _storage.write(key: 'access_token', value: token.accessToken);
      if (token.refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: token.refreshToken);
      }
      return token;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      // If refresh fails, clear tokens (user will need to login again)
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      return null;
    }
  }

  //If access token is already stored that means user has logged in already
  //and will not be required to authenticate again
  static Future<bool> isLoggedIn() async {
    final accessToken = await _storage.read(key: 'access_token');
    return accessToken != null;
  }


  static Future<String?> getValidAccessToken() async {
    final ACCESS_TOKEN = await _storage.read(key: 'access_token'); //get access token from storage

    //make a random api call
    var accessCode = await http.get(
      Uri.parse('https://api.spotify.com/v1/artists/213zHiFZwtDVEqyxeCbk07'),
      headers: {
        "content-type": 'application/json',
        "authorization": 'Bearer $ACCESS_TOKEN',
      },
    );
    //if spotify returns an error 401 that means access token is no longer valid
    if(accessCode.statusCode == 401)
      {
        final refreshed = await refreshAccessToken(); //get new access token
        if (refreshed != null) {
          return refreshed.accessToken; //return new access token
        }
        return null;//if refresh failed return null
    }
    return ACCESS_TOKEN;//if access token is valid return the current access token
  }

  static Future<void> logout() async {
    await _storage.deleteAll(); //deletes all information in storage if user logs out
  }
}

Future<void> login() async {
  if (await SpotifyService.isLoggedIn()) {
    // User is already logged in
    return;
  }

  final token = await SpotifyService.authenticate();
  if (token != null) {
    // Login successful
    // Fetch user profile if needed
  } else {
    // Handle login failure
  }
}

Future<void> logout() async {
  await SpotifyService.logout();
  // Update UI to show logged out state
}

/*
All of the getTopTracks methods basically do the same thing
1. get access token from storage
2. make a call to the api with their respective endpoints
3. If the access code is 200 (success), decode the json file and return a list of the songs
 */
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

Future<List<dynamic>> getTopTracksMedium() async {
  final ACCESS_TOKEN = await SpotifyService.getValidAccessToken();
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/tracks?time_range=medium_term&limit=50'),
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

Future<List<dynamic>> getTopTracksLong() async {
  final ACCESS_TOKEN = await SpotifyService.getValidAccessToken();
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/tracks?time_range=long_term&limit=50'),
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

Future<List<dynamic>> getTopArtistsShort() async {
  final ACCESS_TOKEN = await SpotifyService.getValidAccessToken();
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/artists?time_range=short_term&limit=50'),
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
    throw Exception('Failed to get artists: ${featuredData.statusCode}');
  }
}

Future<List<dynamic>> getTopArtistsMedium() async {
  final ACCESS_TOKEN = await SpotifyService.getValidAccessToken();
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/artists?time_range=medium_term&limit=50'),
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
    throw Exception('Failed to get artists: ${featuredData.statusCode}');
  }
}

Future<List<dynamic>> getTopArtistsLong() async {
  final ACCESS_TOKEN = await SpotifyService.getValidAccessToken();
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/artists?time_range=long_term&limit=50'),
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
    throw Exception('Failed to get artists: ${featuredData.statusCode}');
  }
}

Future<List<dynamic>> getRecentlyPlayed() async {
  final ACCESS_TOKEN = await SpotifyService.getValidAccessToken(); //get access token from storage

  //call the api with the endpoint for recently played tracks
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/player/recently-played?limit=50'),
    headers: {
      "content-type": 'application/json',
      "authorization": 'Bearer $ACCESS_TOKEN',
    },
  );
  if (featuredData.statusCode == 200) {
    final featuredPlaylist = convert.jsonDecode(featuredData.body);
    final items = featuredPlaylist['items'] as List<dynamic>; //items gets the list of recently played songs

    //Filters out if a song has been played consecutively, will only show the most recently played song
    final uniqueItems = <dynamic>[];
    String? lastTrackId;

    for (final item in items) {
      final currentTrackId = item['track']['id'] as String?;
      if (currentTrackId != lastTrackId) {
        uniqueItems.add(item);
        lastTrackId = currentTrackId;
      }
    }

    return uniqueItems;
  }
  else {
    throw Exception('Failed to get artists: ${featuredData.statusCode}');
  }
}

Future<Map<String, List<String>>> getTopGenres() async {
  final topArtists = await getTopArtistsMedium();
  final Map<String, int> genreCount = {};
  final Map<String, List<String>> genreArtists = {};

  // Process artists and count genres
  for (final artist in topArtists) {
    final artistName = artist['name'] as String;
    final genres = artist['genres'] as List<dynamic>? ?? [];

    for (final genre in genres) {
      // Update genre count
      genreCount[genre] = (genreCount[genre] ?? 0) + 1;

      // Add artist to genre's list (no duplicates)
      if(!genreArtists.containsKey(genre)){
        genreArtists[genre] = [];
      }
      if (!genreArtists[genre]!.contains(artistName)) {
        genreArtists[genre]!.add(artistName);
      }
    }
  }
  var sortedEntries = genreCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  // Create the sorted map with genres as keys and artists as values
  final Map<String, List<String>> sortedGenreArtists = {};
  for (var entry in sortedEntries) {
    final genre = entry.key;
    sortedGenreArtists[genre] = genreArtists[genre] ?? [];
  }
  return sortedGenreArtists;
}

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


