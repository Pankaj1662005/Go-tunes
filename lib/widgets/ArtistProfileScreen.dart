import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../models/track_model.dart';
import '../provider/audio_provider.dart';
import '../screens/now_playing_screen.dart';
import '../services/music_service.dart';
import 'mini_player.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String artistId;
  final String artistName;
  final String? artistImage;

  const ArtistProfileScreen({
    required this.artistId,
    required this.artistName,
    this.artistImage,
    super.key,
  });

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  Widget _buildStatTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  int _calculateTotalDownloads(List<Track> tracks) {
    // Dummy logic (replace with actual if available in model)
    return tracks.length * 1000; // Fake metric
  }

  late Future<List<Track>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _tracksFuture = MusicService().fetchTracksByArtist(widget.artistId);
  }

  void _playTrack(List<Track> tracks, int index) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.setPlaylist(tracks, startIndex: index);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          FutureBuilder<List<Track>>(
            future: _tracksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No tracks found.', style: TextStyle(color: Colors.white)));
              }

              final tracks = snapshot.data!;
              final latest = tracks.first;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.artistImage != null)
                            CachedNetworkImage(
                              imageUrl: widget.artistImage!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.white)),
                            ),

                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black54, Colors.transparent, Colors.black87],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.artistName,
                                  style: const TextStyle(
                                    fontSize: 35,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                //const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _buildStatTile(Icons.date_range, 'Release Year',
                                        DateFormat.y().format(DateTime.tryParse(latest.releaseDate ?? '') ?? DateTime.now())),
                                    _buildStatTile(Icons.album, 'Latest Album', latest.albumName),
                                    _buildStatTile(Icons.library_music, 'Tracks', '${tracks.length}'),
                                    _buildStatTile(Icons.download, 'Downloads', '${_calculateTotalDownloads(tracks)}+'),
                                  ],
                                )

                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {}, // TODO: share logic
                      ),
                    ],
                  ),
                  // Latest release
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              latest.albumImage,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("LATEST RELEASE", style: TextStyle(color: Colors.grey)),
                                Text(
                                  latest.name,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Single • ${DateFormat.y().format(DateTime.tryParse(latest.releaseDate ?? '') ?? DateTime.now())}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Songs list
                  Consumer<AudioProvider>(
                    builder: (context, audioProvider, child) {
                      return SliverList(
                        delegate: SliverChildListDelegate(
                          tracks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final track = entry.value;

                            return GestureDetector(
                              onTap: () => _playTrack(tracks, index),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          track.albumImage,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(track.name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white),
                                                overflow: TextOverflow.ellipsis),
                                            Text(track.albumName,
                                                style: const TextStyle(color: Colors.grey),
                                                overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      audioProvider.currentTrack?.id == track.id
                                          ? Lottie.asset(
                                        'assets/Animation - 1745462207749.json',
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.cover,
                                      )
                                          : Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                    ],
                                  )

                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  )

                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
