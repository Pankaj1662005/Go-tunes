// class Track {
//   final String name;
//   final String artist;
//   final String audioUrl;
//   final String albumImage;
//
//   Track({required this.name, required this.artist, required this.audioUrl, required this.albumImage});
//
//   factory Track.fromJson(Map<String, dynamic> json) {
//     return Track(
//       name: json['name'],
//       artist: json['artist_name'],
//       audioUrl: json['audio'],
//       albumImage: json['album_image'] ?? '',
//     );
//   }
// }
//



class Track {
  final String id;
  final String name;
  final int duration;
  final String artist;
  final String artistId;
  final String albumName;
  final String albumId;
  final String licenseUrl;
  final int position;
  final String releaseDate;
  final String albumImage;
  final String audioUrl;
  final String audioDownloadUrl;
  final String shortUrl;
  final String shareUrl;
  final String waveform;

  Track({
    required this.id,
    required this.name,
    required this.duration,
    required this.artist,
    required this.artistId,
    required this.albumName,
    required this.albumId,
    required this.licenseUrl,
    required this.position,
    required this.releaseDate,
    required this.albumImage,
    required this.audioUrl,
    required this.audioDownloadUrl,
    required this.shortUrl,
    required this.shareUrl,
    required this.waveform,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      name: json['name'],
      duration: json['duration'],
      artist: json['artist_name'],
      artistId: json['artist_id'],
      albumName: json['album_name'],
      albumId: json['album_id'],
      licenseUrl: json['license_ccurl'],
      position: json['position'],
      releaseDate: json['releasedate'],
      albumImage: json['album_image'] ?? '',
      audioUrl: json['audio'],
      audioDownloadUrl: json['audiodownload'],
      shortUrl: json['shorturl'],
      shareUrl: json['shareurl'],
      waveform: json['waveform'],
    );
  }
}
