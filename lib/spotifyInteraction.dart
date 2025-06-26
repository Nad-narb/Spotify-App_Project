import 'package:flutter/material.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

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
String? ACCESS_TOKEN = "";
String? REFRESH_TOKEN = "";

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
        ],
      );

      final token = await client.requestAccessToken(
        code: authResp.code!,
        clientId: CLIENT_ID,
        clientSecret: CLIENT_SECRET,
      );
      ACCESS_TOKEN = token.accessToken;
      REFRESH_TOKEN = token.refreshToken;
      return token;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return null;
    }
  }
}

Future<List<dynamic>> getTopTracksShort() async {
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/tracks?time_range=short_term'),
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
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/tracks?time_range=medium_term'),
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
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/tracks?time_range=long_term'),
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
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/artists?time_range=short_term'),
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
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/artists?time_range=medium_term'),
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
  var featuredData = await http.get(
    Uri.parse('https://api.spotify.com/v1/me/top/artists?time_range=long_term'),
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
  // Create the sorted map
  final Map<String, List<String>> sortedGenreArtists = {};
  for (var entry in sortedEntries) {
    final genre = entry.key;
    sortedGenreArtists[genre] = genreArtists[genre] ?? [];
  }
  debugPrint("Genre Count error");
  return sortedGenreArtists;
}




