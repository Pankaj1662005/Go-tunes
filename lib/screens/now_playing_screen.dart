import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:provider/provider.dart';
import '../provider/audio_provider.dart';
import '../widgets/ArtistProfileScreen.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late Duration randomDuration;

  @override
  void initState() {
    super.initState();
    final random = Random();
    final seconds = 2 + random.nextInt(9); // 2 to 10 (inclusive of 10)
    randomDuration = Duration(seconds: seconds);
  }

  @override
  Widget build(BuildContext context) {
    return MovingBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.black87,
        extendBodyBehindAppBar: true, // 👈 makes background go behind AppBar
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Now Playing"),
        ),
        body: Consumer<AudioProvider>(
          builder: (context, audioProvider, _) {
            final track = audioProvider.currentTrack;

            if (track == null) {
              return const Center(child: Text("No track playing", style: TextStyle(color: Colors.white)));
            }

            return GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 300) {
                  Navigator.pop(context);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: track.albumImage,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                        const CircularProgressIndicator(color: Colors.white),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          width: 200,
                          color: Colors.grey[900],
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.white54, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(track.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtistProfileScreen(
                              artistId: track.artistId,
                              artistName: track.artist,
                              artistImage: track.albumImage,
                            ),
                          ),
                        );
                      },
                      child: Text(track.artist,
                          style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                    const SizedBox(height: 32),
                    Slider(
                      value: audioProvider.position.inSeconds.toDouble(),
                      min: 0,
                      max: audioProvider.duration.inSeconds.toDouble().clamp(1, double.infinity),
                      onChanged: (value) {
                        audioProvider.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(audioProvider.position),
                            style: const TextStyle(color: Colors.white)),
                        Text(_formatDuration(audioProvider.duration),
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          color: Colors.white,
                          onPressed: audioProvider.hasPrevious ? audioProvider.playPrevious : null,
                        ),
                        IconButton(
                          icon: Icon(audioProvider.isPlaying ? Icons.pause : Icons.play_arrow),
                          iconSize: 48,
                          color: Colors.white,
                          onPressed: audioProvider.isPlaying
                              ? audioProvider.pause
                              : audioProvider.resume,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          color: Colors.white,
                          onPressed: audioProvider.hasNext ? audioProvider.playNext : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            audioProvider.isLiked(track.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: audioProvider.isLiked(track.id)
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: () {
                            audioProvider.toggleLike(track);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            audioProvider.isShuffling
                                ? Icons.shuffle_on
                                : Icons.shuffle,
                            color: Colors.white,
                          ),
                          onPressed: audioProvider.toggleShuffle,
                        ),
                        IconButton(
                          icon: Icon(
                            _repeatIcon(audioProvider.repeatMode),
                            color: Colors.white,
                          ),
                          onPressed: audioProvider.toggleRepeatMode,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static IconData _repeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.repeatOne:
        return Icons.repeat_one;
      case RepeatMode.repeatAll:
        return Icons.repeat;
      case RepeatMode.off:
      default:
        return Icons.repeat;
    }
  }
}

class MovingBackgroundWrapper extends StatefulWidget {
  final Widget child;
  const MovingBackgroundWrapper({super.key, required this.child});

  @override
  State<MovingBackgroundWrapper> createState() => _MovingBackgroundWrapperState();
}

class _MovingBackgroundWrapperState extends State<MovingBackgroundWrapper> {
  late Duration randomDuration;

  @override
  void initState() {
    super.initState();
    final random = Random();
    randomDuration = Duration(seconds: 2 + random.nextInt(9)); // 2 to 10
  }

  @override
  Widget build(BuildContext context) {
    return MovingBackground(
      backgroundColor: Colors.black,
      duration: randomDuration,
      circles: const [
        MovingCircle(color: Colors.deepPurpleAccent),
        MovingCircle(color: Colors.blueAccent),
        //
        // MovingCircle(color: Colors.amberAccent),
        // MovingCircle(color: Colors.amber),
        //
        // MovingCircle(color: Colors.redAccent),
        // MovingCircle(color: Colors.deepOrangeAccent),
      ],
      child: widget.child,
    );
  }

  @override
  void dispose() {
    // Just for clarity, although MovingBackground should auto-dispose,
    // if it exposed a controller, we would dispose it here.
    super.dispose();
  }
}

