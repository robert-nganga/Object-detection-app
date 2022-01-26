// ignore: file_names
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ml/main.dart';
import 'package:tflite/tflite.dart';

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? cameraController;
  CameraImage? imgCamera;
  bool isworking = false;
  double? imgHeight;
  double? imgWidth;
  List? recognitionsList;


  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  runModelOnStreamFrame() async{
    imgHeight = imgCamera!.height + 0.0;
    imgWidth = imgCamera!.width + 0.0;
    try {
      recognitionsList = await Tflite.detectObjectOnFrame(
        bytesList: imgCamera!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        model: "SSDMobileNet",
        imageHeight: imgCamera!.height,
        imageWidth: imgCamera!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numResultsPerClass: 1,
        threshold: 0.4,
      );
    } on PlatformException{
      print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
    }

    isworking = false;
    setState(() {
      imgCamera;
    });
  }

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.max);
    cameraController!.initialize().then((value) {
      if(!mounted){
        return;
      }
      setState(() {
        cameraController!.startImageStream((imageFromStream) => {
          if(!isworking){
            print('mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm is working'),
            isworking = true,
            imgCamera = imageFromStream,
            runModelOnStreamFrame(),
          }
        });
      });
    });
  }

  Future loadModel() async{
    Tflite.close();

    try{
      String response;
      response = (await Tflite.loadModel(
          model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt",
      ))!;
      print(response);
    } on PlatformException{
      print("unable to model");
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if(recognitionsList == null) return [];
    if(imgHeight == null || imgWidth == null) return [];

    double factorY = screen.width;
    double factorX = imgHeight!;
    Color colorPick = Colors.lightGreen;

    return recognitionsList!.map((result) {
      return Positioned(
        left: result["rect"]["x"] * factorX,
        top: result["rect"]["y"] * factorY,
        width: result["rect"]["w"] * factorX,
        height: result["rect"]["h"] * factorY,

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.lightGreen, width: 2.0),
          ),
          child: Text(
              "${result['detectedClass']} ${(result['confidenceInClass'] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              backgroundColor: colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();

  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController!.stopImageStream();
    Tflite.close();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildrenWidgets = [];
    var size = MediaQuery.of(context).size;
    stackChildrenWidgets.add(
      Positioned(
        left: 0.0,
        top: 0.0,
        width: size.width,
        height: size.height - 100.0,
        child: Container(
          height: size.height - 100.0,
          child: (!cameraController!.value.isInitialized)
              ? Container()
              : AspectRatio(
            aspectRatio: cameraController!.value.aspectRatio,
            child: CameraPreview(cameraController),
          ),
        ),
      ),
    );

    if(imgCamera != null){
      stackChildrenWidgets.addAll(displayBoxesAroundRecognizedObjects(size));
    }
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.blueAccent,
        body: Container(
          margin: EdgeInsets.only(top: 30.0),
          color: Colors.blueAccent,
          child: Stack(
            children: stackChildrenWidgets,
          ),
        ),
      ),
    );
  }
}
