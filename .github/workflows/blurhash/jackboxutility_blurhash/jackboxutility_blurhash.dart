import "dart:convert";
import "dart:io";

import "package:dio/dio.dart";
import 'package:image/image.dart' as img;
import 'package:blurhash_dart/blurhash_dart.dart';

void main(List<String> arguments) {
  String packJsonLink = arguments[0];
  String assetsUri = arguments[1];
  getAllBlurHash(packJsonLink, assetsUri);
}

void getAllBlurHash(String link, String assetsUri) async {
  List<Map<String, dynamic>> blurHashes = [];
  var response = await Dio().get(link);
  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.data);
    for (var pack in jsonResponse["packs"]) {
      if (pack["background"] != null) {
        blurHashes.add(await doBlurHashProcess(pack["background"], assetsUri));
      }
      if (pack["icon"] != null) {
        blurHashes.add(await doBlurHashProcess(pack["icon"], assetsUri));
      }
      for (var game in pack["games"]) {
        if (game["background"] != null) {
          blurHashes
              .add(await doBlurHashProcess(game["background"], assetsUri));
        }
        if (game["game_info"] != null && game["game_info"]["images"] != null) {
          for (var image in game["game_info"]["images"]) {
            blurHashes.add(await doBlurHashProcess(image, assetsUri));
          }
        }
      }
    }
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
  File("./out/blurHashes.json").writeAsStringSync(jsonEncode(blurHashes));
}

Future<Map<String, dynamic>> doBlurHashProcess(url, assetsUri) async {
  try {
    print("Getting blurhash for " + url.toString());
    String path = await saveToFile(url, assetsUri);
    Map<String, dynamic> blurHash = getBlurHash(File(path));
    print("Getting blurhash success for " + url.toString()+" : "+blurHash["hash"]);
    return {"url": url, "blurHash": blurHash["hash"], "width": blurHash["width"], "height": blurHash["height"]};
  } catch (e) {
    return {"url": url, "blurHash": "", "width": 0, "height": 0};
  }
}

Future<String> saveToFile(url, assetsUri) async {
  if (url.startsWith("http")) {
    await Dio().download(url, "./out/tmp." + url.split(".").last);
  } else {
    await Dio()
        .download(assetsUri + "/" + url, "./out/tmp." + url.split(".").last);
  }
  return "./out/tmp." + url.split(".").last;
}

Map<String, dynamic> getBlurHash(File file) {
  final data = file.readAsBytesSync();
  final image = img.decodeImage(data);
  final blurHash = BlurHash.encode(image!, numCompX: 4, numCompY: 3);
  return {
    "hash": blurHash.hash,
    "width": image.width,
    "height": image.height
  };
}

