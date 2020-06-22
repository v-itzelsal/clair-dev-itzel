import 'dart:async';
import 'debug/logging.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/material.dart';


List<CameraDescription> cameras = [];
Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(ClairApp());
}

class ClairApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clair App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ClairHomePage(title: 'Clair'),
    );
  }
}

class ClairHomePage extends StatefulWidget {
  ClairHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ClairHomePageState createState() => _ClairHomePageState();
}

class _ClairHomePageState extends State<ClairHomePage> {
  //camera
  CameraController controller;
  bool isDetecting = false;
  bool isStreaming = false;

  //tflite
  bool isModelLoaded = false;
  List outputs = List();

  //Text
  var outputText = 'none';
  bool updateText = true;

  @override
  void initState() {
    super.initState();
    initializeModel();
    initializeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: !controller.value.isInitialized ? Container() :
        Container(
          //TODO Change to widget 
          child: Column(
            children: <Widget>[
              Expanded(
                child : Container(
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Center(
                      child: CameraPreview(controller)
                      )
                    ),
                    decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: Colors.green,
                              width: 2.0,
                            ),
                          )
                  )
              ),
              const SizedBox(height: 30),
              outputText == 'none' ? 
                Container(
                  alignment: Alignment.center,
                  child: Center(
                    child: new Text("Loading...", textDirection: TextDirection.ltr),
                  ),
                ) : Container(
                  child: Text(outputText,textDirection: TextDirection.ltr),
                ),
              const SizedBox(height: 30),
              RaisedButton(
                onPressed: () { 
                  setState(() {
                    updateText = false;
                  });},
                child: const Text("I'm done", style: TextStyle(fontSize: 20)),
                                    
              ),
          ],),
        )
    );
  }

  initializeModel(){

    loadModel().then((value){
      setState((){
        isModelLoaded = true;
      });
    });
  }

  initializeCamera(){
    controller = CameraController(cameras.last, ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      classifyImage();
    });
  }

  // Starts streaming and call the model to detect images
  classifyImage() async{
    controller.startImageStream((CameraImage image) {
        if (!isModelLoaded) return;
        if(!isDetecting){
          try {
            runModelOnImage(image);
            getTextOutput();
          } catch (e) {
            print(e);
          }
        }
        isDetecting = false;
    });
    
  }

  //Appends new letter to final word
  getTextOutput(){
    var output = '';
    var newText = outputText;
    if(!updateText) return;

    try{
      // Get label from model
      // Parsing to string. Original format index, result [0A]
      var label = outputs[0]["label"].toString();
      output = label[label.length-1];
      if(newText == 'none'){
        newText = output;
      }
      else{
        // Avoids repeating letters
        // I wanted to avoid this output: aaaaaaaaaccccccc
        // However, we can improve this by predicting words. Not for Amir's submission
        if(output != outputText[outputText.length-1])
          newText = newText + output;
      }
    }catch (e) {
      print(e);
    }

    //Update the state to render new value
    setState(() {
      outputText = newText;
    });
  }

  //Runs every frame
  runModelOnImage(CameraImage image) async{
    var recognitions = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) {return plane.bytes;}).toList(),// required
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5,   // defaults to 127.5
        imageStd: 127.5,    // defaults to 127.5
        rotation: 90,       // defaults to 90, Android only
        numResults: 5,      // defaults to 5
        threshold: 0.1,     // defaults to 0.1
        asynch: true        // defaults to true
    );
    // Update outputs list with recognition results
    setState(() {
      isDetecting = true;
      outputs = recognitions;
    });
  }
  //Loading model resources
  loadModel() async{
    await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt"
    );
  }
}
