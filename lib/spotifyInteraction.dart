import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SpotifyOAuth2Client extends OAuth2Client {
  SpotifyOAuth2Client({
    required String redirectUri,
    required String customUriScheme,
  }) : super(
    authorizeUrl: 'https://accounts.spotify.com/authorize',
    tokenUrl: 'https://accounts.spotify.com/api/token',
    redirectUri: redirectUri,
    customUriScheme: customUriScheme,
  );
}

const String CLIENT_ID = 'f211c4add0944080bda55bd11f40dd17';
const String CLIENT_SECRET = 'd520773dd34343a2b2b795913796c5a8';
final FlutterSecureStorage _storage = const FlutterSecureStorage();

class SpotifyService {

  static Future<AccessTokenResponse?> authenticate() async {
    try {
      final client = SpotifyOAuth2Client(
        customUriScheme: 'my.music.app',
        redirectUri: 'my.music.app://callback',
      );

      final authResp = await client.requestAuthorization(
        clientId: CLIENT_ID,
        customParams: {'show_dialog': 'true'},
        scopes: [
          'user-read-private',
          'user-read-playback-state',
          'user-modify-playback-state',
          'user-read-currently-playing',
          'user-read-email',
          'user-top-read',
          'user-read-recently-played',
        ],
      );

      final token = await client.requestAccessToken(
        code: authResp.code!,
        clientId: CLIENT_ID,
        clientSecret: CLIENT_SECRET,
      );

      // Save tokens securely
      await _storage.write(key: 'access_token', value: token.accessToken);
      await _storage.write(key: 'refresh_token', value: token.refreshToken);
      await _storage.write(key: 'expires_at',
          value: DateTime.now().add(Duration(seconds: token.expiresIn!)).toIso8601String());

      return token;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return null;
    }
  }

  static Future<AccessTokenResponse?> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        debugPrint('No refresh token available');
        return null;
      }

      final client = SpotifyOAuth2Client(
        customUriScheme: 'my.music.app',
        redirectUri: 'my.music.app://callback',
      );

      final token = await client.refreshToken(
        _storage.read(key: 'refresh_token').toString(),
        clientId: CLIENT_ID,
        clientSecret: CLIENT_SECRET,
      );

      // Update stored tokens
      await _storage.write(key: 'access_token', value: token.accessToken);
      if (token.refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: token.refreshToken);
      }
      await _storage.write(key: 'expires_at',
          value: DateTime.now().add(Duration(seconds: token.expiresIn!)).toIso8601String());

      return token;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      // If refresh fails, clear tokens (user will need to login again)
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'expires_at');
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final accessToken = await _storage.read(key: 'access_token');
    return accessToken != null;
  }

  static Future<String?> getValidAccessToken() async {
    final expiresAt = await _storage.read(key: 'expires_at');
    if (expiresAt != null) {
      final expiryDate = DateTime.parse(expiresAt);
      if (expiryDate.isBefore(DateTime.now())) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed != null) {
          return refreshed.accessToken;
        }
        return null;
      }
    }

    return await _storage.read(key: 'access_token');
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'expires_at');
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

Future<void> makeSpotifyApiCall() async {
  final accessToken = await SpotifyService.getValidAccessToken();

  if (accessToken == null) {
    // Not logged in or token refresh failed
    await login(); // Show login screen
    return;
  }

  try {
    // Make your API call with the accessToken
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 401) {
      // Token might be invalid, try to refresh
      final newToken = await SpotifyService.refreshAccessToken();
      if (newToken != null) {
        // Retry the request with new token
        return makeSpotifyApiCall();
      } else {
        // Force login
        await login();
      }
    }
    // Process successful response
  } catch (e) {
    debugPrint('API call error: $e');
  }
}

Future<void> logout() async {
  await SpotifyService.logout();
  // Update UI to show logged out state
}

Future<List<dynamic>> getTopTracksShort() async {
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
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
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
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
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
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
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
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
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
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
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
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
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/player/recently-played?limit=50'),
    headers: {
      "content-type": 'application/json',
      "authorization": 'Bearer $ACCESS_TOKEN',
    },
  );
  if (featuredData.statusCode == 200) {
    final featuredPlaylist = convert.jsonDecode(featuredData.body);
    final items = featuredPlaylist['items'] as List<dynamic>;

    // Filter out consecutive duplicates
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
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
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
  // Create the sorted map
  final Map<String, List<String>> sortedGenreArtists = {};
  for (var entry in sortedEntries) {
    final genre = entry.key;
    sortedGenreArtists[genre] = genreArtists[genre] ?? [];
  }
  debugPrint("Genre Count error");
  return sortedGenreArtists;
}

Future<dynamic> getID() async {
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
  var deviceData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/player/devices'),
    headers: {
      "content-type": 'application/json',
      "authorization": 'Bearer $ACCESS_TOKEN',
    },
  );
  if (deviceData.statusCode == 200) {
    final data = convert.jsonDecode(deviceData.body);
    final devices = data['devices'] as List<dynamic>;
    final android = devices[0]["id"];
    if (devices.isEmpty) {
      throw Exception('Please have spotify running in the background');
    }
    await _storage.write(key: 'device_id', value: android.toString());
    return android.toString();
  }
}


Future<void> playTrack(String trackUri) async {
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
  String device_id = _storage.read(key: 'device_id').toString();
  if(device_id.isEmpty){
    device_id = await getID();
  }
  final response = await http.put(
    Uri.parse('https://api.spotify.com/v1/me/player/play?device_id=' + device_id),
    headers: {
      "Authorization": 'Bearer $ACCESS_TOKEN',
      "Content-Type": 'application/json',
    },
    body: convert.jsonEncode({
      "uris": [trackUri],
      "position_ms": 5000
    }),
  );

  if (response.statusCode != 204) {
    throw Exception('Please have spotify running in the background');
  }
}

Future<void> pauseTrack() async {
  makeSpotifyApiCall;
  final ACCESS_TOKEN = await _storage.read(key: 'access_token');
  String device_id = _storage.read(key: 'device_id').toString();
  if (device_id.isEmpty) {
    device_id = await getID();
  }
  final response = await http.put(
    Uri.parse('https://api.spotify.com/v1/me/player/pause?device_id=$device_id'),
    headers: {
      "Authorization": 'Bearer $ACCESS_TOKEN',
      "Content-Type": 'application/json',
    },
  );

  if (response.statusCode != 204 && response.statusCode != 200) {
    throw Exception('Please have spotify running in the background');
  }
}



