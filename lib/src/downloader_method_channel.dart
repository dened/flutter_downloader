import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/src/exceptions.dart';

import 'callback_dispatcher.dart';
import 'downloader_platform_interface.dart';
import 'models.dart';

/// Singature for a function which is called when the download state of a task
/// with [id] changes.
typedef DownloadCallback = void Function(
  String id,
  DownloadTaskStatus status,
  int progress,
);

/// An implementation of [DownloaderPlatformInterface] that uses method channels.
class DownloaderMethodChannel extends DownloaderPlatformInterface {
  static const _channel = MethodChannel('vn.hunghd/downloader');

  static bool _initialized = false;

  /// Whether the plugin is initialized. The plugin must be initialized before
  /// use.
  static bool get initialized => _initialized;

  static bool _debug = false;

  /// If true, more logs are printed.
  static bool get debug => _debug;

  @override
  Future<void> initialize({
    bool debug = false,
    bool ignoreSsl = false,
  }) async {
    assert(
      !_initialized,
      'plugin flutter_downloader has already been initialized',
    );

    _debug = debug;

    WidgetsFlutterBinding.ensureInitialized();

    final callback = PluginUtilities.getCallbackHandle(callbackDispatcher)!;
    await _channel.invokeMethod<void>('initialize', <dynamic>[
      callback.toRawHandle(),
      if (debug) 1 else 0,
      if (ignoreSsl) 1 else 0,
    ]);

    _initialized = true;
  }

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
    assert(_initialized, 'plugin flutter_downloader is not initialized');
    assert(Directory(savedDir).existsSync(), 'savedDir does not exist');

    try {
      final taskId = await _channel.invokeMethod<String>('enqueue', {
        'url': url,
        'saved_dir': savedDir,
        'file_name': fileName,
        'headers': jsonEncode(headers),
        'show_notification': showNotification,
        'open_file_from_notification': openFileFromNotification,
        'requires_storage_not_low': requiresStorageNotLow,
        'save_in_public_storage': saveInPublicStorage,
      });

      if (taskId == null) {
        throw const FlutterDownloaderException(
          message: '`enqueue` returned null taskId',
        );
      }

      return taskId;
    } on FlutterDownloaderException catch (err) {
      _log('Failed to enqueue. Reason: ${err.message}');
    } on PlatformException catch (err) {
      _log('Failed to enqueue. Reason: ${err.message}');
    }

    return null;
  }

  @override
  Future<List<DownloadTask>?> loadTasks() async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    try {
      final result = await _channel.invokeMethod<List<dynamic>>('loadTasks');

      if (result == null) {
        throw const FlutterDownloaderException(
          message: '`loadTasks` returned null',
        );
      }

      return result.map(
        (dynamic item) {
          // item as Map<String, dynamic>; // throws

          return DownloadTask(
            taskId: item['task_id'] as String,
            status: DownloadTaskStatus(item['status'] as int),
            progress: item['progress'] as int,
            url: item['url'] as String,
            filename: item['file_name'] as String?,
            savedDir: item['saved_dir'] as String,
            timeCreated: item['time_created'] as int,
          );
        },
      ).toList();
    } on FlutterDownloaderException catch (err) {
      _log('Failed to load tasks. Reason: ${err.message}');
    } on PlatformException catch (err) {
      _log(err.message);
      return null;
    }
    return null;
  }

  @override
  Future<List<DownloadTask>?> loadTasksWithRawQuery({
    required String query,
  }) async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'loadTasksWithRawQuery',
        {'query': query},
      );

      if (result == null) {
        throw const FlutterDownloaderException(
          message: '`loadTasksWithRawQuery` returned null',
        );
      }

      return result.map(
        (dynamic item) {
          // item as Map<String, dynamic>; // throws

          return DownloadTask(
            taskId: item['task_id'] as String,
            status: DownloadTaskStatus(item['status'] as int),
            progress: item['progress'] as int,
            url: item['url'] as String,
            filename: item['file_name'] as String?,
            savedDir: item['saved_dir'] as String,
            timeCreated: item['time_created'] as int,
          );
        },
      ).toList();
    } on PlatformException catch (err) {
      _log('Failed to loadTasksWithRawQuery. Reason: ${err.message}');
      return null;
    }
  }

  @override
  Future<void> cancel({required String taskId}) async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    try {
      await _channel.invokeMethod<void>('cancel', {'task_id': taskId});
    } on PlatformException catch (err) {
      _log(err.message);
    }
  }

  @override
  Future<void> cancelAll() async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    try {
      return await _channel.invokeMethod('cancelAll');
    } on PlatformException catch (err) {
      _log(err.message);
    }
  }

  @override
  Future<void> pause({required String taskId}) async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    try {
      return await _channel.invokeMethod('pause', {'task_id': taskId});
    } on PlatformException catch (e) {
      _log(e.message);
    }
  }

  @override
  Future<String?> resume({
    required String taskId,
    bool requiresStorageNotLow = true,
  }) async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    try {
      return await _channel.invokeMethod('resume', {
        'task_id': taskId,
        'requires_storage_not_low': requiresStorageNotLow,
      });
    } on PlatformException catch (e) {
      _log(e.message);
      return null;
    }
  }

  @override
  Future<String?> retry({
    required String taskId,
    bool requiresStorageNotLow = true,
  }) async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    try {
      return await _channel.invokeMethod('retry', {
        'task_id': taskId,
        'requires_storage_not_low': requiresStorageNotLow,
      });
    } on PlatformException catch (e) {
      _log(e.message);
      return null;
    }
  }

  @override
  Future<void> remove({
    required String taskId,
    bool shouldDeleteContent = false,
  }) async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    try {
      return await _channel.invokeMethod('remove', {
        'task_id': taskId,
        'should_delete_content': shouldDeleteContent,
      });
    } on PlatformException catch (e) {
      _log(e.message);
    }
  }

  @override
  Future<bool> open({required String taskId}) async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    try {
      final result = await _channel.invokeMethod<bool>(
        'open',
        {'task_id': taskId},
      );

      if (result == null) {
        throw const FlutterDownloaderException(message: '`open` returned null');
      }
    } on PlatformException catch (err) {
      _log('Failed to open downloaded file. Reason: ${err.message}');
      return false;
    }

    return false;
  }

  @override
  Future<void> registerCallback(
    DownloadCallback callback, {
    int step = 10,
  }) async {
    assert(_initialized, 'plugin flutter_downloader is not initialized');

    final callbackHandle = PluginUtilities.getCallbackHandle(callback);
    assert(
      callbackHandle != null,
      'callback must be a top-level or static function',
    );

    assert(
      0 <= step && step <= 100,
      'step size is not in the inclusive <0;100> range',
    );

    await _channel.invokeMethod<void>(
      'registerCallback',
      <dynamic>[callbackHandle!.toRawHandle(), step],
    );
  }

  /// Prints [message] to console if [_debug] is true.
  static void _log(String? message) {
    if (_debug) {
      // ignore: avoid_print
      print(message);
    }
  }
}
