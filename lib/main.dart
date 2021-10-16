import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:billdetect/getBillDetect.dart';
import 'package:dio/dio.dart';
import 'package:soundpool/soundpool.dart';
import 'dart:convert' as convert;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  CameraController _controller;
  Future<void> _initController;
  var isCameraReady = false;
  XFile imageFile;
  List<GetBillDetect> billResult = [];


  final _keyForm = GlobalKey<FormState>(); // Our created key

  @override
  void initState() {
    super.initState();
    initCamera();
    WidgetsBinding.instance.addObserver(this);
  }

  var inputText = "";
  bool apiCall = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      _initController = _controller != null ? _controller.initialize() : null;
    if (!mounted) return;
    setState(() {
      isCameraReady = true;
    });
  }

  Widget cameraWidget(context) {
    var camera = _controller.value;
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * camera.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(_controller),
      ),
    );
  }

  //API
  final String uploadUrl =
      'https://8390-2001-fb1-82-c873-ccfe-4012-397e-5f0b.ngrok.io/upload-file/';

  Future<String> uploadImage(filepath) async {
    String fileName = filepath.split('/').last;
    print("filename " + fileName);
    print("filepath " + filepath);

    FormData data = FormData.fromMap({
      "uploaded_file": await MultipartFile.fromFile(
        filepath,
        filename: fileName,
      ),
    });

    Dio dio = new Dio();
    Soundpool pool = Soundpool(streamType: StreamType.notification);

    dio
        .post(uploadUrl, data: data)
        .then((response) => (response))
        .catchError((error) => print("err" + error));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initController,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                cameraWidget(context),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    color: Colors.transparent,
                    child: RaisedButton(
                        color: Colors.transparent,
                        onPressed: () {
                          captureImage(context);
                        }),
                    // child: Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   mainAxisSize: MainAxisSize.max,
                    //   children: [
                    //     IconButton(
                    //         iconSize: 40,
                    //         icon: Icon(Icons.camera_alt, color: Colors.white),
                    //         onPressed: () => captureImage(context))
                    //   ],
                    // ),
                  ),
                )
              ],
            );
          } else
            return Center(
              child: CircularProgressIndicator(),
            );
        },
      ),
    );
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.high);
    _initController = _controller.initialize();
    if (!mounted) return;
    setState(() {
      isCameraReady = true;
    });
  }

  captureImage(BuildContext context) {
    _controller.takePicture().then((file) {
      setState(() {
        imageFile = file;
      });
      if (mounted) {
        var res = uploadImage(imageFile.path);
        if (res == true) {
          print("hello");
        } else {
          print("loading..");
        }
        // print(res);
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //         builder: (context) => DisplayPictureScreen(image: imageFile)));
      }
    });
  }

  // audioplay(BuildContext context) {
  //   _controller.takePicture().then((file) {
  //     setState(() {
  //       imageFile = file;
  //     });
  //     if(imageFile == 'not found') {
  //
  //     }
  //   });
  // }
}

// class DisplayPictureScreen extends StatelessWidget {
//   final XFile image;

//   DisplayPictureScreen({Key key, this.image}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Display'),
//         actions: [
//           IconButton(icon: Icon(Icons.upload_file), onPressed: () {}),
//         ],
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         child: Image.file(
//           File(image.path),
//           fit: BoxFit.fill,
//         ),
//       ),
//     );
//   }
// }
