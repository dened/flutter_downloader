import 'dart:async';

import 'downloader_platform_interface.dart';
import 'models.dart';

/// Singature for a function which is called when the download state of a task
/// with [id] changes.
typedef DownloadCallback = void Function(
  String id,
  DownloadTaskStatus status,
  int progress,
);

/// Provides access to all functions of the plugin in a single place.
class FlutterDownloader {
  /// Initializes the plugin. This must be called before any other method.
  ///
  /// If [debug] is true, then verbose logging is printed to the console.
  ///
  /// To ignore SSL-related errors on Android, set [ignoreSsl] to true. This may
  /// be useful when connecting to a test server which is not using SSL, but
  /// should be never used in production.
  static Future<void> initialize({
    bool debug = false,
    bool ignoreSsl = false,
  }) =>
      DownloaderPlatformInterface.instance.initialize(
        debug: debug,
        ignoreSsl: ignoreSsl,
      );

  /// Creates a new task which downloads a file from [url] to [savedDir] and
  /// returns a unique identifier of that new download task.
  ///
  /// Name of the downloaded file is determined from the HTTP response and from
  /// the [url]. Set [fileName] if you want a custom filename.
  ///
  /// [savedDir] must be an absolute path.
  ///
  /// [headers] are HTTP headers that will be sent with the request.
  ///
  /// ### Android-only
  ///
  /// If [showNotification] is true, a notification with the current download
  /// progress will be shown.
  ///
  /// If [requiresStorageNotLow] is true, the download won't run unless the
  /// device's available storage is at an acceptable level.
  ///
  /// If [openFileFromNotification] is true, the user can tap on the
  /// notification to open the downloaded file. If it is false, nothing happens
  /// when the tapping the notification.
  ///
  /// Android Q (API 29) changed the APIs for accessing external storage. This
  /// means that apps must store their data in an app-specific directory on
  /// external storage. If you want to save the file in the public Downloads
  /// directory instead, set [saveInPublicStorage] to true. In that case,
  /// [savedDir] will be ignored.
  static Future<String?> enqueue({
    required String url,
    required String savedDir,
    String? fileName,
    Map<String, String> headers = const {},
    bool showNotification = true,
    bool openFileFromNotification = true,
    bool requiresStorageNotLow = true,
    bool saveInPublicStorage = false,
  }) =>
      DownloaderPlatformInterface.instance.enqueue(
        url: url,
        savedDir: savedDir,
        fileName: fileName,
        headers: headers,
        showNotification: showNotification,
        openFileFromNotification: openFileFromNotification,
        requiresStorageNotLow: requiresStorageNotLow,
        saveInPublicStorage: saveInPublicStorage,
      );

  /// Loads all tasks from SQLite database.
  static Future<List<DownloadTask>?> loadTasks() =>
      DownloaderPlatformInterface.instance.loadTasks();

  /// Loads tasks from SQLite database using raw [query].
  ///
  /// **parameters:**
  ///
  /// * `query`: SQL statement. Note that the plugin will parse loaded data from
  ///   database into [DownloadTask] object, in order to make it work, you
  ///   should load tasks with all fields from database. In other words, using
  ///   `SELECT *` statement.
  ///
  /// Example:
  ///
  /// ```dart
  /// FlutterDownloader.loadTasksWithRawQuery(
  ///   query: 'SELECT * FROM task WHERE status=3',
  /// );
  /// ```
  static Future<List<DownloadTask>?> loadTasksWithRawQuery({
    required String query,
  }) =>
      DownloaderPlatformInterface.instance.loadTasksWithRawQuery(
        query: query,
      );

  /// Cancels download task with id [taskId].
  static Future<void> cancel({required String taskId}) =>
      DownloaderPlatformInterface.instance.cancel(
        taskId: taskId,
      );

  /// Cancels all enqueued and running download tasks.
  static Future<void> cancelAll() => DownloaderPlatformInterface.instance.cancelAll();

  /// Pauses a running download task with id [taskId].
  ///
  static Future<void> pause({required String taskId}) => DownloaderPlatformInterface.instance.pause(
        taskId: taskId,
      );

  /// Resumes a paused download task with id [taskId].
  ///
  /// Returns a new [DownloadTask] that is created to continue the partial
  /// download progress. The new [DownloadTask] has a new [taskId].
  static Future<String?> resume({
    required String taskId,
    bool requiresStorageNotLow = true,
  }) =>
      DownloaderPlatformInterface.instance.resume(
        taskId: taskId,
        requiresStorageNotLow: requiresStorageNotLow,
      );

  /// Retries a failed download task.
  ///
  /// **parameters:**
  ///
  /// * `taskId`: unique identifier of a failed download task
  ///
  /// **return:**
  ///
  /// An unique identifier of a new download task that is created to start the
  /// failed download progress from the beginning
  static Future<String?> retry({
    required String taskId,
    bool requiresStorageNotLow = true,
  }) =>
      DownloaderPlatformInterface.instance.retry(
        taskId: taskId,
        requiresStorageNotLow: requiresStorageNotLow,
      );

  /// Deletes a download task from the database. If the given task is running,
  /// it is also canceled. If the task is completed and [shouldDeleteContent] is
  /// true, the downloaded file will be deleted.
  ///
  /// **parameters:**
  ///
  /// * `taskId`: unique identifier of a download task
  /// * `shouldDeleteContent`: if the task is completed, set `true` to let the
  ///   plugin remove the downloaded file. The default value is `false`.
  static Future<void> remove({
    required String taskId,
    bool shouldDeleteContent = false,
  }) =>
      DownloaderPlatformInterface.instance.remove(
        taskId: taskId,
        shouldDeleteContent: shouldDeleteContent,
      );

  /// Opens the file downloaded by download task with [taskId]. Returns true if
  /// the downloaded file can be opened, false otherwise.
  ///
  /// On Android, there are two requirements for opening the file:
  /// - The file must be saved in external storage where other applications have
  ///   permission to read the file
  /// - There must be at least 1 application that can read the files of type of
  ///   the file.
  static Future<bool> open({required String taskId}) => DownloaderPlatformInterface.instance.open(
        taskId: taskId,
      );

  /// Registers a [callback] to track the status and progress of a download
  /// task.
  ///
  /// [callback] must be a top-level or static function of [DownloadCallback]
  /// type which is called whenever the status or progress value of a download
  /// task has been changed.
  ///
  /// Your UI is rendered on the main isolate, while download events come from a
  /// background isolate (in other words, code in [callback] is run in the
  /// background isolate), so you have to handle the communication between two
  /// isolates.
  ///
  /// Example:
  ///
  /// ```dart
  ///ReceivePort _port = ReceivePort();
  ///
  ///@override
  ///void initState() {
  ///  super.initState();
  ///
  ///  IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
  ///  _port.listen((dynamic data) {
  ///     String id = data[0];
  ///     DownloadTaskStatus status = data[1];
  ///     int progress = data[2];
  ///     setState((){ });
  ///  });
  ///
  ///  FlutterDownloader.registerCallback(downloadCallback);
  ///}
  ///
  ///static void downloadCallback(
  ///  String id,
  ///  DownloadTaskStatus status,
  ///  int progress,
  ///  ) {
  ///    final SendPort send = IsolateNameServer.lookupPortByName(
  ///    'downloader_send_port',
  ///  );
  ///  send.send([id, status, progress]);
  ///}
  ///```
  static Future<void> registerCallback(
    DownloadCallback callback, {
    int step = 10,
  }) =>
      DownloaderPlatformInterface.instance.registerCallback(
        callback,
        step: step,
      );
}
