import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../models/track_model.dart';
import '../provider/audio_provider.dart';
import '../widgets/mini_player.dart'; // Make sure your MiniPlayer is in the correct path

class LikedScreen extends StatefulWidget {
  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  String _sortOption = 'Name';

  List<Track> _getSortedTracks(List<Track> tracks) {
    List<Track> sorted = [...tracks];
    if (_sortOption == 'Name') {
      sorted.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortOption == 'Artist') {
      sorted.sort((a, b) => a.artist.compareTo(b.artist));
    } else if (_sortOption == 'Release Date') {
      sorted.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final likedTracks = _getSortedTracks(audioProvider.likedTracks);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Liked Songs',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.grey[900],
              value: _sortOption,
              icon: const Icon(Icons.sort, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              items: ['Name', 'Artist', 'Release Date'].map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _sortOption = val);
              },
            ),
          ),
        ],
      ),


      body: likedTracks.isEmpty
          ? Column(
        children: [
          _buildHeaderCard(),
          const Expanded(
            child: Center(
              child: Text(
                'No liked songs yet.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
        ],
      )
          : ListView.builder(
        itemCount: likedTracks.length + 1,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeaderCard(); // Top Card
          final track = likedTracks[index - 1];
          return Dismissible(
            key: ValueKey(track.id),
            direction: DismissDirection.endToStart,
            background: Container(
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              audioProvider.toggleLike(track);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Removed "${track.name}" from liked songs')),
              );
            },
            child: GestureDetector(
              onTap: () =>
                  audioProvider.setPlaylist(likedTracks, startIndex: index - 1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),

                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: track.albumImage.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: track.albumImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          // placeholder: (context, url) => const Center(
                          //   child: CircularProgressIndicator(strokeWidth: 2),
                          // ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )

                            : const Icon(Icons.music_note, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                            Text(track.artist,
                                style: const TextStyle(color: Colors.grey),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      audioProvider.currentTrack?.id == track.id
                          ? Lottie.asset(
                        'assets/Animation - 1745462207749.json', // Replace with your actual Lottie animation path
                        width: 24, // Match the size of the heart icon
                        height: 24,
                        fit: BoxFit.cover,
                      )
                          : IconButton(
                        icon: Icon(
                          audioProvider.isLiked(track.id) ? Icons.favorite : Icons.favorite_border,
                          color: audioProvider.isLiked(track.id) ? Colors.pinkAccent : Colors.grey,
                        ),
                        onPressed: () => audioProvider.toggleLike(track),
                      ),
                    ],
                  )
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildHeaderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF7F00FF), Color(0xFF00C9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.thumb_up_alt_rounded, size: 64, color: Colors.white),
            SizedBox(height: 10),
            Text(
              "Liked music",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
