import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Home Automation'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final log1 = Logger(
      printer: PrettyPrinter(
    printEmojis: true,
    colors: true,
    printTime: true,
  ));

  final REQUEST_ADDRESS = "192.168.1.150:80";
  String _deviceStatus;
  bool _isLoading;

  Map<String, String> _roomState = {
    "Motor": "0",
    "Bulb1": "0",
    "Bulb2": "0",
    "Fan": "0"
  };

  void initState() {
    super.initState();

    _deviceStatus = "Offline";
    _isLoading = true;

    initDeviceStates();

    // request for the current state of the devices
    // when app starts to for the first time

    Timer.periodic(Duration(milliseconds: 2900), (time) {
      checkConnection();
      // in future try to utilize connection package for conection related activity
    });
  } // end initState Method

  Future<void> checkConnection() async {
    try {
      bool isTimeOut = false;
      log1.d("checkConnection called");
      Response response = await get(Uri.http(REQUEST_ADDRESS, "/check"))
          .timeout(Duration(milliseconds: 2000), onTimeout: () {
        log1.d("checkConnection time out called");
        isTimeOut = true;
        // no response from server
        if (_deviceStatus == "Online") {
          log1.d("checkConnection device status online block called");
          resetStates();
          Fluttertoast.showToast(
              msg: "Your Device is Offline",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.orange,
              fontSize: 16.0);
        } // end if
        return null;
      });
      if (!isTimeOut) {
        isTimeOut = false;
        if (_deviceStatus == "Offline") {
          if (response.statusCode == 200) {
            log1.d(
                "checkConnection device status offline block called with 200 status");
            // device is  working fine
            // change current status of device
            setState(() {
              _deviceStatus = "Online";
              String data = response.body;
              List<String> dl = data.split("*");
              dl.forEach((deviceData) {
                // now we have some thing like this Motor:1
                List<String> singleKeyValuePair = deviceData.split(":");
                _roomState[singleKeyValuePair[0]] = singleKeyValuePair[1];
              });
            });
          } else {
            // device is not working fine
            Fluttertoast.showToast(
                msg: "There is some problem with device",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                backgroundColor: Colors.orange,
                fontSize: 16.0);

            log1.d("status code != 200 block of checkconnection method");
            resetStates();
          }
        }
      }
    } on Exception catch (_) {
      resetStates();
      // log1.e("exception block of checkconnection method");
    }
  } // end check connection function

  Future<void> sendCommand(
    String deviceKey,
  ) async {
    if (_deviceStatus == "Offline") {
      Fluttertoast.showToast(msg: "Your Device is currently offline");
      return null;
    }

    try {
      bool isTimeOut = false;
      Map<String, String> post_data = {
        deviceKey: _roomState[deviceKey],
      };

      Response response = await post(
        Uri.http(REQUEST_ADDRESS, "/"),
        body: post_data,
      ).timeout(Duration(milliseconds: 2000), onTimeout: () {
        isTimeOut = true;
        resetStates();
        return null;
      });
      if (!isTimeOut) {
        if (response.statusCode == 200) {
          // successful response
          isTimeOut = false;
          String data = response.body;

          setState(() {
            _roomState[deviceKey] = data;
          });
          Fluttertoast.showToast(
              msg: data,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              fontSize: 16.0);
        }
      }
    } on Exception catch (e) {
      resetStates();
      Fluttertoast.showToast(
          msg: e.toString(),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          fontSize: 16.0);
    }
  } // end function sendCommand

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(bottom: 5),
                    child: RaisedButton(
                      textColor: Colors.white,
                      color: _roomState["Motor"] == "0"
                          ? Colors.red
                          : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(13.0),
                        side: BorderSide(color: Colors.black),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 22.0),
                      elevation: 5,
                      onPressed: () => sendCommand("Motor"),
                      child: Text(
                        "Motor",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 5),
                    child: RaisedButton(
                      textColor: Colors.white,
                      color: _roomState["Bulb1"] == "0"
                          ? Colors.red
                          : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(13.0),
                        side: BorderSide(color: Colors.black),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 22.0),
                      elevation: 5,
                      onPressed: () => sendCommand("Bulb1"),
                      child: Text(
                        "Bulb1",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 5),
                    child: RaisedButton(
                      textColor: Colors.white,
                      color: _roomState["Bulb2"] == "0"
                          ? Colors.red
                          : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(13.0),
                        side: BorderSide(color: Colors.black),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 22.0),
                      elevation: 5,
                      onPressed: () => sendCommand("Bulb2"),
                      child: Text(
                        "Bulb2",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 5),
                    child: RaisedButton(
                      textColor: Colors.white,
                      color:
                          _roomState["Fan"] == "0" ? Colors.red : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(13.0),
                        side: BorderSide(color: Colors.black),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 22.0),
                      elevation: 5,
                      onPressed: () => sendCommand("Fan"),
                      child: Text(
                        "Fan",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 5),
                    child: RaisedButton(
                      textColor: Colors.white,
                      color:
                          _deviceStatus == "Online" ? Colors.green : Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(13.0),
                        side: BorderSide(color: Colors.black),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 22.0),
                      elevation: 5,
                      onPressed: () => {},
                      child: Text(
                        "",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> initDeviceStates() async {
    try {
      log1.d("initDeviceStates called");
      bool isTimeOut = false;

      Response response = await get(Uri.http(REQUEST_ADDRESS, "/init"))
          .timeout(Duration(milliseconds: 2000), onTimeout: () {
        isTimeOut = true;
        log1.d("initDeviceStates timeout called");
        resetStates();
        return null;
      });

      if (!isTimeOut) {
        if (response.statusCode == 200) {
          log1.d("initDeviceStates block with 200 status called");
          isTimeOut = false;
          String data = response.body;
          // sample incoming string
          // "Motor:1*Bulb1:0*Bulb2:1*Fan:1"
          setState(() {
            _deviceStatus = "Online";
            _isLoading = false;
            List<String> dl = data.split("*");
            dl.forEach((deviceData) {
              // now we have some thing like this Motor:1
              List<String> singleKeyValuePair = deviceData.split(":");
              _roomState[singleKeyValuePair[0]] = singleKeyValuePair[1];
            });
          });
        } else {
          Fluttertoast.showToast(
              msg: "reset state called 1", toastLength: Toast.LENGTH_LONG);
          resetStates();
        }
      }
    } on Exception catch (_) {
      resetStates();
    }
  }

  void resetStates() {
    setState(() {
      _isLoading = false;
      _roomState.forEach((k, v) {
        _roomState[k] = "0";
      });

      _deviceStatus = "Offline";
    });
  } // end method
}
