
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/audio_provider.dart';
import '../services/music_service.dart';
import '../models/track_model.dart';
import '../widgets/mini_player.dart';
import '../widgets/ArtistProfileScreen.dart';
import 'likedscreen.dart';
import 'now_playing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();

  List<String> _suggestions = [];
  bool _showSuggestions = false;


  List<Track> trendingTracks = [];
  List<Track> newReleases = [];
  Map<String, List<Track>> genreTracks = {};
  List<Map<String, dynamic>> radios = [];
  List<Map<String, dynamic>> artists = [];
  List<Track> searchResults = [];
  late PageController _artistPageController;
  int _currentArtistPage = 0;
  List<Map<String, dynamic>> featuredArtists = [];
  Timer? _autoScrollTimer;


  bool _loading = true;
  String _searchQuery = '';

  final List<String> _genres = [
    'rock', 'pop', 'jazz', 'hiphop', 'electronic',
    'chillout', 'classical', 'blues', 'folk', 'ambient'
  ];

  @override
  void initState() {
    super.initState();
    _artistPageController = PageController(viewportFraction: 0.9);

    _artistPageController.addListener(() {
      final newPage = _artistPageController.page?.round() ?? 0;
      if (_currentArtistPage != newPage) {
        setState(() {
          _currentArtistPage = newPage;
        });
      }
    });

    _loadAllContent();
    _startAutoScroll();

  }

  Future<void> _loadAllContent() async {
    try {
      trendingTracks = await _musicService.fetchTrendingTracks();
      newReleases = await _musicService.fetchNewReleases();
      radios = await _musicService.fetchRadios();
      artists = await _musicService.fetchArtists();
      featuredArtists = await _musicService.fetchFeaturedArtists();

      final genreFutures = _genres.map((genre) async {
        final tracks = await _musicService.fetchTracksByGenre(genre);
        return MapEntry(genre, tracks);
      }).toList();

      final results = await Future.wait(genreFutures);
      genreTracks = Map.fromEntries(results);

    } catch (e) {
      debugPrint('Error loading content: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (featuredArtists.isEmpty) return;

      _currentArtistPage++;
      if (_currentArtistPage >= featuredArtists.length) _currentArtistPage = 0;

      _artistPageController.animateToPage(
        _currentArtistPage,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }



  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      final suggestions = await _musicService.fetchAutocompleteMatches(query: query);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = true;
      });
    } catch (e) {
      debugPrint('Autocomplete fetch error: $e');
    }
  }


  Future<void> _searchTracks(String query) async {
    setState(() {
      _searchQuery = query;
      searchResults = [];
      _loading = true;
    });

    try {
      final matches = await _musicService.fetchAutocompleteMatches(query: query);
      final tracks = await _musicService.fetchTracksByNames(matches);
      setState(() => searchResults = tracks);
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }


  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchQuery = '';
      searchResults.clear();
    });
  }



  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }




  //ui of all searching 1
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Go Tunes', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _fetchSuggestions(value);
                    },
                    onSubmitted: (value) {
                      _searchTracks(value);
                      setState(() => _showSuggestions = false);
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: _clearSearch,
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomScrollView(
                    slivers: [
                      if (_searchQuery.isEmpty)
                        SliverToBoxAdapter(child: _buildFeaturedArtists()),
                      if (_searchQuery.isEmpty)
                        buildHorizontalTrackSliver('Trending Tracks', trendingTracks),
                      if (_searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildLikedPlaylistCard(),
                          ),
                        ),
                      if (_searchQuery.isEmpty)
                        buildHorizontalTrackSliver('New Releases', newReleases),
                      if (_searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildGenresSection(),
                          ),
                        ),
                      if (_searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildArtistsSection(),
                          ),
                        ),
                      if (_searchQuery.isEmpty)
                        ...genreTracks.entries.map((entry) =>
                            buildHorizontalTrackSliver('${_capitalize(entry.key)} Radio', entry.value)),
                      if (_searchQuery.isNotEmpty && searchResults.isNotEmpty) ...[
                        buildSliverHeader('Tracks'),
                        buildSearchTrackSliver(searchResults, context),
                        buildSliverHeader('Albums'),
                        buildAlbumSliver(searchResults),
                        //buildSliverHeader('Artists'),
                       // buildArtistSliver(searchResults),
                        //buildSliverHeader('Albums'),
                        //buildAlbumSliver(extractUniqueAlbums(searchResults)),
                        buildSliverHeader('Artists'),
                        buildArtistSliver(extractUniqueArtists(searchResults)),
                      ],

                    ],
                  ),
                ),
              ],
            ),

            // 👇 Suggestion Box Floating
            if (_showSuggestions)
              Positioned(
                left: 16,
                right: 16,
                top: 72, // Adjust based on TextField vertical padding
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _suggestions.map((suggestion) {
                          return GestureDetector(
                            onTap: () {
                              _searchController.text = suggestion;
                              _searchTracks(suggestion);
                              setState(() => _showSuggestions = false);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Text(
                                suggestion,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Consumer<AudioProvider>(
          builder: (context, audioProvider, _) {
            if (audioProvider.currentTrack == null) return const SizedBox();
            return const MiniPlayer();
          },
        ),
      ),
    );
  }


  //searchig 2 working
  SliverList buildSearchTrackSliver(List<Track> tracks, BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final track = tracks[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                track.albumImage,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 40, color: Colors.white),
              ),
            ),
            title: Text(track.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(track.artist, style: const TextStyle(color: Colors.white70)),
            onTap: () {
              context.read<AudioProvider>().setPlaylist([track]);
            },
          );
        },
        childCount: tracks.length,
      ),
    );
  } //search track

  // Set<Map<String, dynamic>> extractUniqueAlbums(List<Track> tracks) {
  //   final albumSet = <Map<String, dynamic>>{};
  //   final albumIds = <String>{};
  //
  //   for (var track in tracks) {
  //     if (!albumIds.contains(track.albumId)) {
  //       albumIds.add(track.albumId);
  //       albumSet.add({
  //         'id': track.albumId,
  //         'name': track.albumName,
  //         'image': track.albumImage,
  //       });
  //     }
  //   }
  //   return albumSet;
  // }

  SliverList buildAlbumSliver(List<Track> tracks) {
    final Map<String, Map<String, dynamic>> albums = {};
    final Set<String> seen = {};

    for (var track in tracks) {
      if (!seen.contains(track.albumId)) {
        albums[track.albumId] = {
          'name': track.albumName,
          'image': track.albumImage,
          'artist': track.artist,
        };
        seen.add(track.albumId);
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final album = albums.values.elementAt(index);
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                album['image'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.album, size: 40, color: Colors.white),
              ),
            ),
            title: Text(album['name'], style: const TextStyle(color: Colors.white)),
            subtitle: Text(album['artist'], style: const TextStyle(color: Colors.white70)),
            onTap: () {
              // Navigate to Album page
            },
          );
        },
        childCount: albums.length,
      ),
    );
  } //album

  SliverList buildArtistSliver(Set<Map<String, dynamic>> artists) {
    final artistList = artists.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final artist = artistList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(artist['image']),
              radius: 25,
            ),
            title: Text(
              artist['name'],
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistProfileScreen(
                    artistId: artist['id'],
                    artistName: artist['name'],
                    artistImage: artist['image'],
                  ),
                ),
              );
            },
          );
        },
        childCount: artistList.length,
      ),
    );
  }// when clicked then singer profile must be played
  Set<Map<String, dynamic>> extractUniqueArtists(List<Track> tracks) {
    final artistSet = <Map<String, dynamic>>{};
    final artistIds = <String>{};

    for (var track in tracks) {
      if (!artistIds.contains(track.artistId)) {
        artistIds.add(track.artistId);
        artistSet.add({
          'id': track.artistId,
          'name': track.artist,
          'image': track.albumImage, // Fallback, or set a default
        });
      }
    }
    return artistSet;
  }


  SliverToBoxAdapter buildSliverHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  } //to display thir name  in search




  Widget _buildFeaturedArtists() {
    if (featuredArtists.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12,left: 16),
          child: Text(
            'Featured Artists',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(
          height: 200, // slightly increased for more content
          child: PageView.builder(
            controller: _artistPageController,
            itemCount: featuredArtists.length,
            //itemExtent: 200, // Helps optimize PageView rendering if items have fixed height
            itemBuilder: (context, index) {
              final artist = featuredArtists[index];
              final artistId = artist['id'] ?? 'no known';
              final artistName = artist['name'] ?? 'Unknown Artist';
              final artistImage = artist['image'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistProfileScreen(
                        artistId: artistId,
                        artistName: artistName,
                        artistImage: artistImage,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: artistImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade800),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white),
                          memCacheWidth: 600, // optional: control memory usage if needed
                          useOldImageOnUrlChange: true, // ensures cached image stays during updates
                        ),
                        Container(
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '#${int.tryParse(artistId)?.remainder(1000) ?? 0}', // short id
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artistName,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(featuredArtists.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentArtistPage == index ? 10 : 6,
              height: _currentArtistPage == index ? 10 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentArtistPage == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
      ],
    );
  }




  Widget buildHorizontalTrackSliver(String title, List<Track> tracks) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(title, style: _sectionTitle),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return GestureDetector(
                  onTap: () => _openNowPlaying(tracks, index),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            track.albumImage,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(track.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        Text(track.artist,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  } //card for trrnding,new relsease,


  Widget _buildLikedPlaylistCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  LikedScreen()),
              );
            },
            child: Container(
              width: 140,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F00FF), Color(0xFF00C9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.thumb_up_alt_rounded, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Liked music",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 4),
                  Text("📌 Auto playlist",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 140,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.radio_outlined, color: Colors.white70,size: 50,),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildGenresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Genres', style: _sectionTitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genres.map((genre) => Chip(label: Text(genre, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.grey[800])).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  } //made for hard codesd genere

  Widget _buildArtistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Artists', style: _sectionTitle),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistProfileScreen(
                        artistId: artist['id'],
                        artistName: artist['name'],
                        artistImage: artist['image'],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage: (artist['image'] != null && artist['image'].toString().trim().isNotEmpty)
                            ? CachedNetworkImageProvider(artist['image']) as ImageProvider
                            : null,
                        child: (artist['image'] == null || artist['image'].toString().trim().isEmpty)
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),

                      const SizedBox(height: 6),
                      Text(
                        artist['name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }  //similar like featured section to view singer profile screen




  void _openNowPlaying(List<Track> playlist, int index) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (playlist.isEmpty) return;

    audioProvider.setPlaylist(playlist, startIndex: index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NowPlayingScreen(),
      ),
    );
  }

  TextStyle get _sectionTitle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}



