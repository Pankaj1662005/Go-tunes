
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class MusicService {
  final String apiKey = '6562a568';
  final String apiUrl = "https://api.jamendo.com/v3.0";

  Future<List<Track>> fetchMusicTracks({required String query}) async {
    try {
      final suggestions = await fetchAutocompleteMatches(query: query);
      if (suggestions.isEmpty) return [];

      final tracks = await fetchTracksByNames(suggestions);
      return tracks;
    } catch (e) {
      throw Exception('Smart search failed: $e');
    }
  }


  Future<List<String>> fetchAutocompleteMatches({required String query}) async {
    final url = Uri.parse(
      '$apiUrl/autocomplete/?client_id=$apiKey'
          '&format=json'
          '&prefix=$query'
          '&limit=5'
          '&entity=tracks'
          '&matchcount=true',
    );

    final response = await http.get(url);
    print('🔍 Autocomplete URL: $url');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final trackMatches = data['results']['tracks'] as List;
      return trackMatches.map<String>((match) => match['match'] as String).toList();
    } else {
      throw Exception('Failed to fetch autocomplete suggestions');
    }
  }

  Future<List<Track>> fetchTracksByNames(List<String> names) async {
    List<Track> allResults = [];

    for (String name in names) {
      final url = Uri.parse(
        '$apiUrl/tracks/?client_id=$apiKey'
            '&format=json'
            '&namesearch=$name'
            '&limit=3', // limit per name
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracksJson = data['results'];
        final tracks = tracksJson.map<Track>((json) => Track.fromJson(json)).toList();
        allResults.addAll(tracks);
      }
    }

    return allResults;
  }


  Future<List<Map<String, dynamic>>> fetchFeaturedArtists() async {
    final response = await http.get(Uri.parse(
      '$apiUrl/tracks/?client_id=$apiKey&format=jsonpretty&limit=7&order=popularity_week',
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final trackResults = data['results'];

      // Extract unique artists
      final Map<String, Map<String, dynamic>> artistMap = {};
      for (var track in trackResults) {
        final artistId = track['artist_id'];
        if (!artistMap.containsKey(artistId)) {
          artistMap[artistId] = {
            'id': artistId,
            'name': track['artist_name'],
            'image': track['album_image'] ?? '', // fallback empty string

          };
        }
      }

      return artistMap.values.toList();
    } else {
      throw Exception('Failed to fetch featured artists');
    }
  }








  Future<List<Track>> fetchTrendingTracks() async {
    final response = await http.get(Uri.parse(
      '$apiUrl/tracks/?client_id=$apiKey&format=jsonpretty&limit=30&order=popularity_total',
    ));
    return _parseTracks(response);
  }

  Future<List<Track>> fetchNewReleases() async {
    final response = await http.get(Uri.parse(
      '$apiUrl/tracks/?client_id=$apiKey&format=jsonpretty&limit=10&order=releasedate',
    ));
    print('$apiUrl/tracks/?client_id=$apiKey&format=jsonpretty&limit=10&order=date_desc');
    return _parseTracks(response);
  }

  Future<List<Track>> fetchTracksByGenre(String genre) async {
    final response = await http.get(Uri.parse(
      '$apiUrl/tracks/?client_id=$apiKey&format=jsonpretty&limit=10&tags=$genre',
    ));
    print('$apiUrl/tracks/?client_id=$apiKey&format=jsonpretty&limit=10&tags=$genre');
    return _parseTracks(response);
  }

  Future<List<Map<String, dynamic>>> fetchArtists() async {
    final response = await http.get(Uri.parse(
      '$apiUrl/artists/?client_id=$apiKey&format=jsonpretty&limit=30',
    ));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw Exception('Failed to load artists');
    }
  }
  Future<List<Track>> fetchTracksByArtist(String artistId) async {
    final url = Uri.parse(
      '$apiUrl/tracks/?client_id=$apiKey&format=jsonpretty&limit=50&artist_id=$artistId',
    );
    print('🎤 Artist Tracks URL: $url');
    final response = await http.get(url);
    print('🎤 Artist Tracks Response: ${response.body}');
    return _parseTracks(response);
  }


  Future<List<Map<String, dynamic>>> fetchRadios() async {
    final response = await http.get(Uri.parse(
      '$apiUrl/radios/?client_id=$apiKey&format=jsonpretty&limit=10',
    ));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw Exception('Failed to load radios');
    }
  }


  Future<List<String>> fetchGenres() async {
    final response = await http.get(Uri.parse(
      '$apiUrl/tags/?client_id=$apiKey&format=jsonpretty',
    ));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['results'].map((e) => e['name']));
    } else {
      throw Exception('Failed to load genres');
    }
  }

  Future<List<Track>> _parseTracks(http.Response response) async {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Track>.from(data['results'].map((json) => Track.fromJson(json)));
    } else {
      throw Exception('Failed to load tracks');
    }
  }
}
