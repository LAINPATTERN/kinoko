
import 'dart:async';
import 'dart:io' as io;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:file/src/interface/file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';
import 'package:file/local.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:file/file.dart';
import 'package:http/http.dart' as http;


class SizeResult {
  int cached = 0;
  int other = 0;
}

// class ProviderKey {
//   ImageConfiguration configuration;
//   NeoImageProvider provider;
//
//   ProviderKey(this.provider, this.configuration);
//
//   @override
//   bool operator ==(Object other) {
//     if (other is ProviderKey) {
//       return configuration == other.configuration && provider == other.provider;
//     }
//     return false;
//   }
//
//   @override
//   int get hashCode => 0x88fa000 | provider.hashCode | configuration.hashCode;
// }

class NeoError extends Error {
  final String msg;

  NeoError(this.msg);

  @override
  String toString() => msg;
}

const String dir_key = "neo_directory";

class NeoCacheManager {

  static Future<Directory> _root;
  Future<Directory> _directory;

  static Map<String, NeoCacheManager> _managers = {};

  NeoCacheManager._(String key) {
    _directory = _getDirectory(key);
  }

  static NeoCacheManager _defaultManager;
  static NeoCacheManager get defaultManager {
    if (_defaultManager == null) {
      _defaultManager = NeoCacheManager._("default");
    }
    return _defaultManager;
  }

  factory NeoCacheManager(String key) {
    NeoCacheManager manager = _managers[key];
    if (manager == null)
      manager = _managers[key] = NeoCacheManager._(key);
    return manager;
  }

  static Future<Directory> get root {
    if (_root == null) {
      _root = getRoot();
    }
    return _root;
  }
  static Future<Directory> getRoot() async {
    String path = KeyValue.get(dir_key);
    if (path != null && path.isNotEmpty) {
      Directory root = LocalFileSystem().directory(path);
      if (await root.exists())
        return root;
    }
    try {
      var temp = await getExternalStorageDirectory();
      if (temp != null) {
        String path = p.join(temp.path, "pic");
        Directory root = LocalFileSystem().directory(path);
        if (!await root.exists()) {
          await root.create(recursive: true);
        }
        KeyValue.set(dir_key, path);
        return root;
      }
    } catch (e) {

    }

    try {
      var temp = await getApplicationSupportDirectory();
      if (temp != null) {
        String path = p.join(temp.path, "pic");
        Directory root = LocalFileSystem().directory(path);
        if (!await root.exists()) {
          await root.create(recursive: true);
        }
        KeyValue.set(dir_key, path);
        return root;
      }
    } catch (e) {

    }

    try {
      var temp = await getTemporaryDirectory();
      if (temp != null) {
        String path = p.join(temp.path, "pic");
        Directory root = LocalFileSystem().directory(path);
        if (!await root.exists()) {
          await root.create(recursive: true);
        }
        KeyValue.set(dir_key, path);
        return root;
      }
    } catch (e) {

    }
    return null;
  }

  Future<Directory> _getDirectory(String key) async {
    return LocalFileSystem().directory(p.join((await root).path, key));
  }

  Future<File> getFileFromCache(Uri uri) async {
    return (await _directory).childFile(NeoImageProvider.getFilename(uri));
  }

  Future<File> getSingleFile(Uri uri, {Map<String, String> headers}) async {
    var file = (await _directory).childFile(NeoImageProvider.getFilename(uri));
    if (!await file.exists()) {
      var provider = NeoImageProvider(
        cacheManager: this,
        uri: uri,
        headers: headers
      );
      var stream = provider.resolve(ImageConfiguration.empty);
      Completer<void> completer = Completer();
      ImageStreamListener listener;
      listener = ImageStreamListener((image, info) {
        stream.removeListener(listener);
        completer.complete();
      }, onError: (e, stack) {
        stream.removeListener(listener);
        completer.completeError(e, stack);
      });
      stream.addListener(listener);
      await completer.future;
    }
    return file;
  }

  static String _generateMd5(String input) => md5.convert(utf8.encode(input)).toString();
  static String cacheKey(DataItem item) => "${item.projectKey}/${_generateMd5(item.link)}";

  static Future<SizeResult> calculateCacheSize({Set<String> cached}) async {
    if (cached == null) cached = Set();
    String path = (await root).path;
    var dir = io.Directory(path);
    SizeResult result = SizeResult();
    await for (var entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is io.File) {
        var segs = entry.path.replaceFirst("$path/", "").split('/');
        if (segs.length > 2) {
          var key = "${segs[0]}/${segs[1]}";
          if (cached.contains(key)) {
            result.cached += (await entry.stat()).size;
          } else {
            result.other += (await entry.stat()).size;
          }
        }  else {
          result.other += (await entry.stat()).size;
        }
      }
    }
    return result;
  }

  static Future<void> clearCache({Set<String> without}) async {
    if (without == null) without = Set();
    String path = (await root).path;
    var dir = io.Directory(path);
    await for (var firstEntry in dir.list(followLinks: false)) {
      if (firstEntry is io.Directory) {
        String firstName = p.basename(firstEntry.path);
        await for (var secondEntry in firstEntry.list(followLinks: false)) {
          String secondName = p.basename(secondEntry.path);
          String key = "$firstName/$secondName";
          if (!without.contains(key)) {
            await secondEntry.delete(recursive: true);
          }
        }
        try {
          await firstEntry.delete();
        } catch (e) {
          // not empty
        }
      } else {
        await firstEntry.delete();
      }
    }
  }

  // Map<ProviderKey, NeoImageProvider> _providers = {};
}

class NeoImageProvider extends ImageProvider<NeoImageProvider> {

  final Uri uri;
  final Map<String, String> headers;
  NeoCacheManager cacheManager;
  String filename;
  final Duration timeout;

  NeoImageProvider({
    this.cacheManager,
    @required this.uri,
    this.headers,
    this.timeout = const Duration(seconds: 20),
  }) {
    if (cacheManager == null) {
      cacheManager = NeoCacheManager.defaultManager;
    }
    filename = getFilename(uri);
  }

  @override
  ImageStreamCompleter load(NeoImageProvider key, decode) => NeoImageStreamCompleter(key, decode);

  @override
  Future<NeoImageProvider> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  static String getFilename(Uri uri) {
    String ext = p.extension(uri.path);
    String name = hex.encode(md5.convert(utf8.encode(uri.toString())).bytes);
    return "$name$ext";
  }

  @override
  bool operator ==(Object other) {
    if (other is NeoImageProvider) {
      return uri == other.uri && cacheManager == other.cacheManager;
    }
    return super == other;
  }

  @override
  int get hashCode => 0x928300 | uri.hashCode | cacheManager.hashCode;
}

class _ImageFrameDecoder {
  final NeoImageStreamCompleter _streamCompleter;
  bool validate = true;

  _ImageFrameDecoder(this._streamCompleter);

  void run() async {
    ui.Codec codec = await _streamCompleter.getCodec();
    if (!validate || codec == null) return;
    if (codec.frameCount > 1) {
      while (true) {
        if (!validate) return;
        var image = await codec.getNextFrame();
        if (!validate) return;
        _streamCompleter._emitImage(ImageInfo(image: image.image));
        await Future.delayed(image.duration);
      }
    } else {
      var image = await codec.getNextFrame();
      if (!validate) return;
      _streamCompleter._emitImage(ImageInfo(
        image: image.image
      ));
    }
  }

  void stop() => validate = false;
}

class NeoImageStreamCompleter extends ImageStreamCompleter {

  final NeoImageProvider provider;
  final DecoderCallback decoder;

  static Map<NeoImageProvider, Future<Uint8List>> fetching = {};

  NeoImageStreamCompleter(this.provider, this.decoder);

  void run() {
    getCodec();
  }

  Future<Uint8List> fetch() async {
    var req = http.Request("GET", provider.uri);
    if (provider.headers != null) req.headers.addAll(provider.headers);
    var response = await req.send();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      io.BytesBuilder builder = io.BytesBuilder();
      await for (var chunk in response.stream) {
        builder.add(chunk);
        reportImageChunkEvent(ImageChunkEvent(
            cumulativeBytesLoaded: builder.length,
            expectedTotalBytes: response.contentLength
        ));
      }
      var bytes = builder.toBytes();
      if (bytes.length == 0) {
        throw NeoError("Empty body");
      } else {
        return bytes;
      }
    } else {
      throw NeoError("Status code ${response.statusCode}");
    }
  }

  Future<Uint8List> startFetch() {

    var async = fetch().timeout(provider.timeout);
    fetching[provider] = async;
    void _wait() async {
      try {
        await async;
      }
      catch (e) {
        reportError(exception: e);
      }
      finally {
        fetching.remove(provider);
      }
    }
    _wait();
    return async;
  }

  Future<ui.Codec> getCodec() async {
    var dir = await provider.cacheManager._directory;
    File file = dir.childFile(provider.filename);
    if ((await file.stat()).size > 0) {
      return decoder(await file.readAsBytes());
    } else {
      Future<Uint8List> asyncBytes;
      if (fetching.containsKey(provider)) {
        asyncBytes = fetching[provider];
      } else {
        asyncBytes = startFetch();
      }

      var bytes = await asyncBytes;
      var parent = file.parent;
      if (!await parent.exists())
        await parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return decoder(bytes);
    }
  }

  _ImageFrameDecoder _frameDecoder;
  @override
  void addListener(ImageStreamListener listener) {
    super.addListener(listener);
    if (_frameDecoder == null) {
      _frameDecoder = _ImageFrameDecoder(this);
      _frameDecoder.run();
    }
  }

  @override
  void removeListener(ImageStreamListener listener) {
    super.removeListener(listener);
    if (_frameDecoder != null) {
      _frameDecoder.stop();
      _frameDecoder = null;
    }
  }

  void _emitImage(ImageInfo image) => setImage(image);
}