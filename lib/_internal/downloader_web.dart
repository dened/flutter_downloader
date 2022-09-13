// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:html' as html show window;

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A web implementation of the DownloaderPlatformInterface of the FlutterDownloader plugin.
class DownloaderWeb extends DownloaderPlatformInterface {
  /// Constructs a DownloaderWeb
  DownloaderWeb() {
    print('create DownloaderWeb');
  }

  ///
  static void registerWith(Registrar registrar) {
    DownloaderPlatformInterface.instance = DownloaderWeb();
  }

  @override
  Future<void> initialize({
    bool debug = false,
    bool ignoreSsl = false,
  }) =>
      Future.value();

  @override
  Future<String?> enqueue({
    required String url,
    required String savedDir,
    String? fileName,
    Map<String, String> headers = const {},
    bool showNotification = true,
    bool openFileFromNotification = true,
    bool requiresStorageNotLow = true,
    bool saveInPublicStorage = false,
  }) async {
    await html.window.open(url, '_blank');

    return null;
  }

  @override
  Future<void> registerCallback(DownloadCallback callback, {int step = 10}) async {}

  @override
  Future<bool> open({required String taskId}) => Future.value(false);

  @override
  Future<void> remove({required String taskId, bool shouldDeleteContent = false}) => Future.value();

  @override
  Future<String> retry({required String taskId, bool requiresStorageNotLow = true}) =>
      Future.value(taskId);

  @override
  Future<String> resume({required String taskId, bool requiresStorageNotLow = true}) =>
      Future.value(taskId);

  @override
  Future<void> pause({required String taskId}) => Future.value();

  @override
  Future<void> cancelAll() => Future.value();

  @override
  Future<void> cancel({required String taskId}) => Future.value();

  @override
  Future<List<DownloadTask>> loadTasksWithRawQuery({required String query}) => Future.value([]);

  @override
  Future<List<DownloadTask>> loadTasks() => Future.value([]);
}
