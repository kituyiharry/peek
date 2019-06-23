import 'package:http/http.dart' as Http;
import 'dart:convert' as Convert;

class UnSplashApiProxy {
  static String sEndpoint = 'https://api.unsplash.com';
  static String sAuthorizationHeader = '';
  static String sSecretKey = '';
  static String sRandomEndpoint = '/photos/random';
  static UnSplashApiProxy _unSplashApiProxy;
  final Http.Client httpClient = Http.Client();

  static getInstance() {
    if (_unSplashApiProxy != null) {
      return _unSplashApiProxy;
    } else {
      return UnSplashApiProxy();
    }
  }

  Future<UnSplashPhotoModel> fetch(String query) async {
    UnSplashPhotoModel unSplashPhotoModel;

    await httpClient
        .get(Uri.parse('$sEndpoint$sRandomEndpoint?query=$query'),
            headers: {"Authorization": sAuthorizationHeader})
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
          unSplashPhotoModel = UnSplashPhotoModel.fromJson(data);
        });
    return unSplashPhotoModel;
  }
}

class UnSplashPhotoModel {
  final String iD;
  final DateTime createdAt;
  final int width;
  final int height;
  final String color;
  final int likes;
  final bool likedByUser;
  final String description;
  final UnSplashUris unSplashUris;
  final UnSplashLinks unSplashLinks;

  UnSplashPhotoModel(
      this.iD,
      this.createdAt,
      this.width,
      this.height,
      this.color,
      this.likes,
      this.likedByUser,
      this.description,
      this.unSplashUris,
      this.unSplashLinks);

  UnSplashPhotoModel.fromJson(Map unSplashData)
      : iD = unSplashData['id'],
        createdAt = DateTime.parse(unSplashData['created_at']),
        width = unSplashData['width'],
        height = unSplashData['height'],
        color = unSplashData['color'],
        likes = unSplashData['likes'],
        likedByUser = unSplashData['liked_by_user'],
        description = unSplashData['description'],
        unSplashLinks = UnSplashLinks.fromJsonMap(unSplashData['links']),
        unSplashUris = UnSplashUris.fromJsonMap(unSplashData['urls']);
}

class UnSplashUris {
  final String raw;
  final String full;
  final String regular;
  final String small;
  final String thumb;

  UnSplashUris(this.raw, this.full, this.regular, this.small, this.thumb);

  UnSplashUris.fromJsonMap(Map uriData)
      : raw = uriData['raw'],
        full = uriData['full'],
        regular = uriData['regular'],
        thumb = uriData['thumb'],
        small = uriData['small'];
}

class UnSplashLinks {
  final String self;
  final String html;
  final String download;
  final String downloadLocation;

  UnSplashLinks(this.self, this.html, this.download, this.downloadLocation);

  UnSplashLinks.fromJsonMap(Map linkData)
      : self = linkData['self'],
        html = linkData['html'],
        download = linkData['download'],
        downloadLocation = linkData['download_location'];
}
