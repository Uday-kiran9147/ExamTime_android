import 'package:dio/dio.dart';
import 'package:examtime/model/handle_likes.dart';
import 'package:examtime/model/notes.dart';
import 'package:examtime/screens/landing_screen/popupdetail.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'navbar.dart';
import 'drawer.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class DashboardPage extends StatelessWidget {
  static const String routeName = '/dashboard';

  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  late FocusNode focusNode;
  bool isInFocus = false;
  List<dynamic> notes = [];
  List<dynamic> filteredNotes = [];
  User? user;
  bool isLoading = true;
  List<String> likedNotes = [];
  List<String> likedStatus = [];

  fetchNotes() async {
    if (SharedServices.isLoggedIn()) {
      Response res = await Apiservices.fetchNotes();
      notes = jsonDecode(jsonEncode(res.data));
      filteredNotes = notes;
      isLoading = false;
      setState(() {});
      if (kDebugMode) {
        print(notes);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error occurred : please logout and login again ")));
    }
  }

  getLikedNotes() {
    likedNotes =
        (preferences?.getStringList(SharedServices.LIKED_NOTES)) ?? likedNotes;
    likedStatus = likedNotes;
  }

  @override
  void initState() {
    super.initState();
    getLikedNotes();
    fetchNotes();
    focusNode = FocusNode();
    focusNode.addListener(() {
      setState(() {
        isInFocus = focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _searchController.dispose();
    focusNode.dispose();
  }

  void _filterNotes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredNotes = notes;
      } else {
        filteredNotes = notes.where((note) {
          return note['title'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _unfocusSearchBar() {
    focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> notes = [
      {
        "pdfUrl":
            "https://www.yesterdaysclassics.com/previews/burt_poems_preview.pdf",
        "title": "Note 1",
        "description": "Description of Note 1",
      },
      {
        "pdfUrl": "https://www.clickdimensions.com/links/TestPDFfile.pdf",
        "title": "Note 2",
        "description": "Description of Note 2",
      },
      {
        "pdfUrl":
            "https://www.yesterdaysclassics.com/previews/burt_poems_preview.pdf",
        "title": "Note 1",
        "description": "Description of Note 1",
      },
      {
        "pdfUrl": "https://www.clickdimensions.com/links/TestPDFfile.pdf",
        "title": "Note 2",
        "description": "Description of Note 2",
      },
      {
        "pdfUrl":
            "https://www.yesterdaysclassics.com/previews/burt_poems_preview.pdf",
        "title": "Note 1",
        "description": "Description of Note 1",
      },
      {
        "pdfUrl": "https://www.clickdimensions.com/links/TestPDFfile.pdf",
        "title": "Note 2",
        "description": "Description of Note 2",
      },
    ];

    List<bool> likedStatus = List.generate(notes.length, (index) => false);
    return WillPopScope(
      onWillPop: () async {
        return false; // Disables the back button
      },
      child: Scaffold(
        appBar: CommonNavBar(),
        drawer: AppDrawer(), // Use the CommonNavBar as the app bar
        body: ListView.builder(
          itemCount: notes.length,
          itemBuilder: (BuildContext context, int index) {
            if (likedStatus.length <= index) {
              likedStatus.add(false);
            }
            return GestureDetector(
              onTap: () {
                _showNoteDetails(context, notes[index]);
              },
              child: Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FadeInImage(
                      image: NetworkImage(
                          'https://i.postimg.cc/43FzYStQ/pexels-cottonbro-3831847.jpg'),
                      fit: BoxFit.cover,
                      placeholder: const NetworkImage(
                          'https://placehold.jp/3d4070/ffffff/300x300.png?css=%7B%22border-radius%22%3A%2215px%22%7D'),
                    ),
                    Divider(), // Horizontal line to separate notes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          notes[index]["title"],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            likedStatus[index]
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                likedStatus[index] ? Colors.red : Colors.grey,
                          ),
                          onPressed: () async {
                            if (await HandleLikes.isMarked(notes[index]["title"])) {
                              await HandleLikes.deleteLikes(notes[index]["title"]);
                              likedStatus[index] = !likedStatus[index];
                            }
                            else {
                              HandleLikes.addLikes(notes[index]);
                              likedStatus[index] = !likedStatus[index];
                            }
                          },
                        ),
                        // SizedBox(width: 18),
                        IconButton(
                            onPressed: () {
                              shareDownloadedPdf(notes[index]["pdfUrl"],
                                  notes[index]["title"]);
                            },
                            icon: Icon(Icons.share_outlined)),
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () async {
                            var status = await Permission.storage.status;
                            if (!status.isGranted) {
                              await Permission.storage.request();
                            }
                            var downloadPath = await getDownloadPath();
                            if (downloadPath != null) {
                              var filePath =
                                  '$downloadPath/${notes[index]["title"]}.pdf';
                              _sendDownloadNotification(
                                  filePath); // Show initial notification
                              await _startDownload(
                                  notes[index]["pdfUrl"], filePath);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Could not get download path')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> shareDownloadedPdf(String pdfUrl, String title) async {
    try {
      final fileName = "$title.pdf";
      final appDocDir = await getApplicationDocumentsDirectory();
      final filePath = "${appDocDir.path}/$fileName";

      final response = await Dio().download(pdfUrl, filePath);
      if (response.statusCode == 200) {
        final xFile = XFile(filePath);
        await Share.shareXFiles([xFile]);
      } else {
        print("Problem in Downloading a file For sharing");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _showNoteDetails(BuildContext context, Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PopupDetail(
          title: note["title"],
          description: note["description"],
          pdfUrl: note["pdfUrl"],
          setController: (PDFViewController, TextEditingController) {},
        );
      },
    );

    // void _showNoteDetails(BuildContext context, Map<String, dynamic> note) {
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return PopupDetail(
    //         title: note["title"],
    //         description: note["description"],
    //         pdfUrl: note["pdfUrl"],
    //       );
    //     },
    //   );
    // }
  }

  Future<void> initNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('notification_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Use the response object here
        // For example, to open a file:
        await OpenFile.open(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse:
          (NotificationResponse response) async {
        // Use the response object here
        // For example, to open a file:
        await OpenFile.open(response.payload);
      },
    );
  }

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await DashboardPage().initNotification(); // Initialize notifications
    runApp(MaterialApp(
      home: DashboardPage(),
    ));
  }

  void _toggleLikedStatus(int index, List<bool> likedStatus) {
    List<bool> updatedStatus = List.from(likedStatus);
    updatedStatus[index] = !updatedStatus[index];
    likedStatus.replaceRange(0, likedStatus.length, updatedStatus);
  }

  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');

        if (!await directory.exists())
          directory = await getExternalStorageDirectory();
      }
    } catch (err, stack) {
      print("Cannot get download folder path");
    }
    return directory?.path;
  }

  Future<void> _startDownload(String url, String filePath) async {
    var response = await http.get(Uri.parse(url));
    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    _sendDownloadCompleteNotification(
        filePath); // Show download complete notification
  }

  void _sendDownloadCompleteNotification(String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel_id',
      'Download Channel',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Cancel the ongoing download notification
    await flutterLocalNotificationsPlugin.cancel(0);

    // Show download complete notification
    await flutterLocalNotificationsPlugin.show(
      0,
      'Download Complete',
      'Your file has been downloaded',
      platformChannelSpecifics,
      payload: filePath,
    );
  }

  void _sendDownloadNotification(String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel_id',
      'Download Channel',

      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      // Specify the small icon resource here
      showProgress: true,
      // Show download progress
      maxProgress: 100,
      // Max progress value
      indeterminate: false, // Make the progress bar determinate
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show initial download notification
    await flutterLocalNotificationsPlugin.show(
      0,
      'Download in progress',
      'Your file is downloading...',
      platformChannelSpecifics,
      payload: filePath,
    );
  }
}
