import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gdt5/GoogleAuthClient.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart' as signIn;
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<AssetEntity> picturesList = [];
  int pageNow = 0;
  int pageLast;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  _onScrollDown(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (pageNow != pageLast) {
        _fetchImages();
      }
    }
  }

  _fetchImages() async {
    pageLast = pageNow;
    var result = await PhotoManager.requestPermission();
    if (result) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(onlyAll: true);
      print(albums);
      List<AssetEntity> pictures =
          await albums[0].getAssetListPaged(pageNow, 60);
      print(pictures.length);
      if (pictures.length != 0)
        setState(() {
          picturesList.addAll(pictures);
          pageNow++;
          print(pageNow);
        });
    }
  }

  Future<void> _addPicturePressed(String title, List<int> bites) async {
    final googleSignIn =
        signIn.GoogleSignIn.standard(scopes: [drive.DriveApi.DriveScope]);
    final signIn.GoogleSignInAccount account = await googleSignIn.signIn();
    print("User account $account");

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    var driveFile = new drive.File();
    driveFile.name = '12.txt';
    driveFile.parents = ["appDataFolder"];

    final Stream<List<int>> mediaStream =
        Future.value([103, 104]).asStream().asBroadcastStream();
    var media = new drive.Media(mediaStream, 2);
    final result = await driveApi.files.create(driveFile, uploadMedia: media);
    print("Upload result: $result");
  }

  Future<void> _singIn() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Text(
            'Image translator',
            style: TextStyle(fontSize: 20),
          ),
          leading: Icon(Icons.image),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _onScrollDown(notification);
          return;
        },
        child: GridView.builder(
          itemCount: picturesList.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemBuilder: (context, index) {
            return FutureBuilder(
              future: picturesList[index].thumbData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done)
                  return FlatButton(
                    child: Image.memory(snapshot.data),
                    onPressed: () {
                      _onButtonPressed(
                          context, snapshot, picturesList[index].title);
                    },
                  );
                return Container();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _singIn,
        tooltip: 'sign in',
        child: Icon(Icons.people),
      ),
    );
  }

  Future _onButtonPressed(
      BuildContext context, AsyncSnapshot snapshot, String title) {
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Oh sheet, you pressed button'),
          content: Image.memory(snapshot.data),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('Add'),
              onPressed: () => _addPicturePressed(title, snapshot.data),
            ),
            CupertinoDialogAction(
              child: Text('Back'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }
}
