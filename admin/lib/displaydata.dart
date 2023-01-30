import 'dart:io';
import 'package:csv/csv.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class Displaydata extends StatefulWidget {
  final date;

  Displaydata({Key? key, required this.date}) : super(key: key);

  @override
  State<Displaydata> createState() => _DisplaydataState();
}

class _DisplaydataState extends State<Displaydata> {
  var u = FirebaseAuth.instance.currentUser?.uid;
  @override
  initState() {
    super.initState();
  }

  void _openFile(filename) {
    OpenFile.open(filename);
  }

  getCsv(
    onlyDate,
    DatabaseReference ref,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        );
      },
    );

    List<List<dynamic>> messdata = List<List<dynamic>>.empty(growable: true);
    List<dynamic> row = List.empty(growable: true);

    row.add("ScholarId");
    row.add("Name");
    row.add("Remarks");
    row.add("Email ID");
    messdata.add(row);
    print('called');

    await ref.once().then((value) {
      DataSnapshot snapshot = value.snapshot;

      for (var snapChild in snapshot.children) {
        List<dynamic> row = List.empty(growable: true);

        row.add(snapChild.child('scholarid').value.toString());
        row.add(snapChild.child('name').value.toString());
        row.add(snapChild.child('remarks').value.toString());
        row.add(snapChild.child('email').value.toString());

        messdata.add(row);
      }
    });
    if (await Permission.storage.request().isGranted) {
      Directory? directory;
      directory = Directory('/storage/emulated/0/Download');
      String dir = directory.path + "/messdata$onlyDate.csv";

      String file = "$dir";
      File f = new File(file);

      String csv = const ListToCsvConverter().convert(messdata);
      await f.writeAsString(csv);
      CircularProgressIndicator(
        value: 100,
        strokeWidth: 20,
      );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 30),
          content: Text(
            "File Downloaded.",
            style: GoogleFonts.openSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              _openFile(file);
            },
          ),
        ),
      );
    } else {}
  }

  Widget build(BuildContext context) {
    final onlyDate = DateFormat('yyyy-MM-dd').format(widget.date);
    final databaseRef = FirebaseDatabase.instance
        .ref()
        .child(u!)
        .child("logs")
        .child(onlyDate.toString());

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Students Data',
            style: GoogleFonts.openSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
          backgroundColor: Colors.black.withOpacity(0.85),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            getCsv(DateFormat('dd_MM_yy').format(widget.date).toString(),
                databaseRef);
          },
          child: Icon(Icons.download),
          backgroundColor: Colors.black,
        ),
        body: SafeArea(
          child: FirebaseAnimatedList(
            query: databaseRef,
            padding: EdgeInsets.all(8.0),
            itemBuilder: (BuildContext context, DataSnapshot snapshot,
                Animation<double> animation, int index) {
              return Container(
                decoration: new BoxDecoration(
                    border: new Border(bottom: new BorderSide())),
                child: ListTile(
                  isThreeLine: false,
                  title: Text(
                    snapshot.child('scholarid').value.toString(),
                    style: GoogleFonts.openSans(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: .3,
                    ),
                  ),
                  subtitle: Text(
                    snapshot.child('name').value.toString() +
                        "\n" +
                        snapshot.child('remarks').value.toString() +
                        "\n" +
                        snapshot.child('email').value.toString(),
                    style: GoogleFonts.openSans(
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      letterSpacing: .3,
                    ),
                  ),
                ),
              );
            },
          ),
        ));
  }
}
