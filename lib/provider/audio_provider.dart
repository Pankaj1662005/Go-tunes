import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track_model.dart';

enum RepeatMode { off, repeatOne, repeatAll }

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Track> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isShuffling = false;
  RepeatMode _repeatMode = RepeatMode.off;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  AudioProvider() {
    _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_repeatMode == RepeatMode.repeatOne) {
        _play();
      } else {
        next();
      }
    });

    _loadLikedTracks(); // Load liked songs on init
  }

  AudioPlayer get audioPlayer => _audioPlayer;
  Track? get currentTrack => _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  List<Track> get playlist => _playlist;
  bool get isPlaying => _isPlaying;
  bool get isShuffling => _isShuffling;
  RepeatMode get repeatMode => _repeatMode;
  Duration get duration => _duration;
  Duration get position => _position;

  final Set<String> _likedTrackIds = {};
  final List<Track> _likedTracks = [];

  List<Track> get likedTracks => List.unmodifiable(_likedTracks);

  Future<void> _loadLikedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final likedIds = prefs.getStringList('likedTrackIds') ?? [];
    final likedJson = prefs.getStringList('likedTracks') ?? [];

    _likedTrackIds.addAll(likedIds);

    _likedTracks.clear();
    _likedTracks.addAll(likedJson.map((trackStr) {
      final trackMap = jsonDecode(trackStr);
      return Track.fromJson(trackMap);
    }));

    notifyListeners();
  }

  Future<void> toggleLike(Track track) async {
    final prefs = await SharedPreferences.getInstance();

    if (_likedTrackIds.contains(track.id)) {
      _likedTrackIds.remove(track.id);
      _likedTracks.removeWhere((t) => t.id == track.id);
    } else {
      _likedTrackIds.add(track.id);
      _likedTracks.add(track);
    }

    // Save updated data
    await prefs.setStringList('likedTrackIds', _likedTrackIds.toList());
    await prefs.setStringList(
      'likedTracks',
      _likedTracks.map((t) => jsonEncode(_trackToMap(t))).toList(),
    );

    notifyListeners();
  }

  bool isLiked(String trackId) {
    return _likedTrackIds.contains(trackId);
  }

  Map<String, dynamic> _trackToMap(Track t) => {
    'id': t.id,
    'name': t.name,
    'duration': t.duration,
    'artist_name': t.artist,
    'artist_id': t.artistId,
    'album_name': t.albumName,
    'album_id': t.albumId,
    'license_ccurl': t.licenseUrl,
    'position': t.position,
    'releasedate': t.releaseDate,
    'album_image': t.albumImage,
    'audio': t.audioUrl,
    'audiodownload': t.audioDownloadUrl,
    'shorturl': t.shortUrl,
    'shareurl': t.shareUrl,
    'waveform': t.waveform,
  };

  void setPlaylist(List<Track> tracks, {int startIndex = 0}) {
    _playlist = tracks;
    _currentIndex = startIndex;
    _play();
  }

  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    notifyListeners();
  }

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.repeatAll;
        break;
      case RepeatMode.repeatAll:
        _repeatMode = RepeatMode.repeatOne;
        break;
      case RepeatMode.repeatOne:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void _play() async {
    final track = currentTrack;
    if (track == null) return;

    try {
      final file = await DefaultCacheManager().getSingleFile(track.audioUrl);
      await _audioPlayer.play(DeviceFileSource(file.path));
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
    notifyListeners();
  }

  void seek(Duration pos) {
    _audioPlayer.seek(pos);
    notifyListeners();
  }

  void next() {
    int nextIndex;

    if (_isShuffling) {
      nextIndex = Random().nextInt(_playlist.length);
    } else if (_currentIndex + 1 < _playlist.length) {
      nextIndex = _currentIndex + 1;
    } else if (_repeatMode == RepeatMode.repeatAll) {
      nextIndex = 0;
    } else {
      _isPlaying = false;
      notifyListeners();
      return;
    }

    if (nextIndex != _currentIndex) {
      _currentIndex = nextIndex;
      _play();
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _play();
    }
  }

  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  void playNext() => next();
  void playPrevious() => previous();
}
