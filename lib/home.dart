import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/all.dart';
import 'package:m3u8_downloader/m3u8_downloader.dart';
import 'package:need_resume/need_resume.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'database.dart';
import 'encrypt_data.dart';

final hiveDatabaseProvider = ChangeNotifierProvider<Database>((ref) {
  return Database();
});

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ResumableState<MyApp> {
  ReceivePort _port = ReceivePort();
  TextEditingController _videoUrlController = TextEditingController();
  String deleteVideo = '';
  double progress = 0.0;
  static String videoStatus = '';

  static String get getVideoStatus => videoStatus;
  VideoPlayerController _videoPlayerController1;
  ChewieController _chewieController;
  static String videoName = '';

  static String get getVideoName => videoName;

  @override
  void initState() {
    super.initState();
    //Listening for the data is coming other isolates
    _port.listen((message) {
      progress = message[1];

      if (progress > 0.93) {
        setState(() {
          progress = 100;
          videoStatus = 'Encrypting...';
          Timer(Duration(seconds: 55), () {
            setState(() {
              videoStatus = 'Done';
            });
          });
        });
        return;
      }
      print(progress);
      if (!mounted) return;
      setState(() {});
    });

    initAsync();
    displayDownloadedVideo();
  }

  void initAsync() async {
    print("INIT");
    String saveDir = '/sdcard/Download';
    M3u8Downloader.initialize(
      saveDir: saveDir,
      debugMode: false,
    );
    if (IsolateNameServer.lookupPortByName('downloader_send_port') != null) {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
    }
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
  }

  Future displayDownloadedVideo() async {
    var encryptedVidFromSharedPref;
    await context.read(hiveDatabaseProvider).getVideoName();
    encryptedVidFromSharedPref = context.read(hiveDatabaseProvider).videoName;
    if (encryptedVidFromSharedPref.length != 0) {
      initializePlayer(savedIds: encryptedVidFromSharedPref.last);
    }
  }

  @override
  void onPause() {
    deleteWatchedVideo();
  }

  Future<void> initializePlayer({String savedIds}) async {
    print("Decrypting...");
    final status = await Permission.storage.request();
    if (status.isGranted) {
      //------encrypted Path----------//
      String subSave = savedIds.substring(0, 17);
      String replace = savedIds.replaceAll(subSave, "");
      // String newSaveIds = "/storage/emulated/0/Download/$replace";
      String newSaveIds = "/sdcard/download/$replace";

      var decryptedVideo = decryptionVideo(newSaveIds);
      //----decrypted path for deleting the saved video------//
      String unWantedPath = decryptedVideo.substring(0, 17);
      String wantedPath = decryptedVideo.replaceAll(unWantedPath, "");
      String conca = subSave + wantedPath;
      deleteVideo = conca;
      print("deleteVideo $deleteVideo");
      var myNewFile = new File(decryptedVideo);
      _videoPlayerController1 = VideoPlayerController.file(myNewFile);
      await _videoPlayerController1.initialize();
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController1,
          autoPlay: false,
          looping: false,
        );
      });
    }
  }

  static progressCallback(dynamic args) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    args["status"] = 1;
    send.send([args["status"], args["progress"]]);
    print(
        'args["progress"]args["progress"]args["progress"]args["progress"] ${args["progress"]}');
  }

  static successCallback(dynamic args) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send({
      "status": 2,
      "url": args["url"],
      "filePath": args["filePath"],
      "dir": args["dir"]
    });
    videoName = args["filePath"];
    downloadEncryptedFileInfo();
  }

  static errorCallback(dynamic args) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send({"status": 3, "url": args["url"]});
  }

  m3u8DownloaderVideo(String url) async {
    M3u8Downloader.download(
        url: url,
        name: "video",
        progressCallback: progressCallback,
        successCallback: successCallback,
        errorCallback: errorCallback);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('hls Downloader'),
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _videoUrlController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent))),
              ),
            ),
            Text(
              "$progress",
              style: TextStyle(fontSize: 40),
            ),
            Text(
              "$videoStatus",
              style: TextStyle(fontSize: 40),
            ),
            RaisedButton(
                child: Text("Download"),
                onPressed: () async {
                  final status = await Permission.storage.request();
                  if (status.isGranted) {
                    m3u8DownloaderVideo(_videoUrlController.text);
                  }
                }),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                child: Center(
                  child: _chewieController != null &&
                          _chewieController
                              .videoPlayerController.value.initialized
                      ? Chewie(
                          controller: _chewieController,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text('Loading'),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String encryptionVideo(String videoToEncrypt) {
    var encryptedVideo = EncryptionClass().encryptFactory(videoToEncrypt);
    return encryptedVideo;
  }

  static String decryptionVideo(String videoToDecrypt) {
    var decryptedVideo = EncryptionClass().decryptFactory(videoToDecrypt);
    return decryptedVideo;
  }

  static Future downloadEncryptedFileInfo() async {
    String fileToEncrypt = getVideoName.replaceRange(0, 17, "");
    String encryptedVideo = encryptionVideo("/sdcard/Download/$fileToEncrypt");
    print("ENCRYPTED VIDEO IS:::::::::::::  $encryptedVideo");
    await Database().saveVideoName(encryptedVideo);
    videoStatus = 'Done!';
    print("DONEEEEEEEEEEEEE");
  }

  deleteWatchedVideo() async {
    var myFile = new File(deleteVideo);
    var fileToDelete = File(myFile.path);
    bool isExist = await fileToDelete.exists();
    if (isExist) {
      await fileToDelete.delete();
    }
  }
}
