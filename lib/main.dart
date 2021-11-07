import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:billdetect/getBillDetect.dart';
import 'package:dio/dio.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:soundpool/soundpool.dart';
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart';
import 'package:billdetect/model.dart';

Soundpool _soundpool;

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
      debugShowCheckedModeBanner: false,
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
  int _cheeringStreamId = -1;
  File img;
  final _keyForm = GlobalKey<FormState>(); // Our created key
  File imgResize;

  @override
  void initState() {
    super.initState();
    initCamera();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<int> _loadCheering() async {
    _soundpool = Soundpool(maxStreams: 2);
    return await _soundpool.loadUri(_cheeringUrl);
  }

  double _rate = 1.0;
  Future<int> _cheeringId;
  Future<void> _playCheering() async {
    var _sound = await _cheeringId;
    _cheeringStreamId = await _soundpool.play(
      _sound,
      rate: _rate,
    );
  }

  Future<void> _loadSounds() async {
    _cheeringId = _loadCheering();
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
      'https://6f12-2001-fb1-132-4bb6-7df8-b7b9-9841-760d.ngrok.io/upload-file/';
  String soundLink = "";
  Future<String> uploadImage(filepath) async {
    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(filepath);
    File compressedFile = await FlutterNativeImage.compressImage(filepath,
        quality: 80, percentage: 60);
    String filepath2 = compressedFile.path;
    String fileName = filepath2.split('/').last;
    // print("filepath "+filepath2);
    // print("sound link"+soundLink);
    FormData data = FormData.fromMap({
      "uploaded_file": await MultipartFile.fromFile(
        filepath2,
        filename: fileName,
      ),
    });

    Result result;

    Dio dio = new Dio();
    Soundpool pool = Soundpool(streamType: StreamType.notification);
    // void res(response){
    //   Map<String, dynamic> user = jsonDecode(response);
    //   print('Howdy, ${user['Detect']}!');
    // }
    try {
      Response resultData = await dio.post(uploadUrl, data: data);
      // final userMap = jsonDecode(resultData.data);
      result = Result.fromJson(resultData.data);
      // print(result.link);
      soundLink = result.link;
      // print(soundLink);
      _loadSounds();
      _playCheering();
    } catch (e) {
      print('Error creating user: $e');
    }
    // .then((response) => (response))
    // .catchError((error) => print("err" + error));
  }

  String get _cheeringUrl => kIsWeb ? soundLink.split('/').last : soundLink;

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

  // Future<void> resizeImg(File img) async {
  //   print('HelloPath :' + img.path);
  //   imgResize = await FlutterNativeImage.compressImage(img.path,
  //       quality: 100, percentage: 70);
  //   // print('Resize :'+imgResize.path);
  // }

  captureImage(BuildContext context) {
    _controller.takePicture().then((file) {
      setState(() {
        imageFile = file;
        img = File(imageFile.path);
      });
      if (mounted) {
        var res = uploadImage(img.path);
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
