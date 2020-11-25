import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool fullscreen = false;

  TextEditingController _videoUrlController = TextEditingController();
  VideoPlayerController _videoPlayerController1;
  ChewieController _chewieController;

  @override
  void dispose() {
    _videoUrlController?.dispose();
    _videoPlayerController1?.dispose();
    _chewieController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "HLS Demo",
            style: TextStyle(fontSize: 15),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _videoUrlController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent))),
              ),
            ),
            FlatButton(
                child: Text("Play Video"),
                color: Colors.blue,
                textColor: Colors.white,
                onPressed: () {
                  initializePlayer(_videoUrlController.text);
                  FocusScope.of(context).unfocus();
                }),
            SizedBox(
              height: 20,
            ),
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

  Future<void> initializePlayer(String url) async {
    _videoPlayerController1 = VideoPlayerController.network(url);
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
