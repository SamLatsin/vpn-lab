// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:localstore/localstore.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:vpn_lab/models/server_model.dart';

String domain = "PUT_YOUR_DOMAIN_HERE";

saveCurrentServer() async {
  final db = Localstore.instance;
  await db.collection('statistics').doc("0").set({});
}

saveCurrentServerState(Server selectedServer, VpnStatus data) async {
  final db = Localstore.instance;
  var result;

  db
      .collection("short-statisctics")
      .doc(data.connectedOn.toString().substring(0, 19))
      .get()
      .then((value) async {
    if (value == null) {
      result = {
        "ip": selectedServer.ip,
        "abbreviation": selectedServer.abbreviation,
      };
      db
          .collection("short-statisctics")
          .doc(data.connectedOn.toString().substring(0, 19))
          .set(result);
    }
  });

  db
      .collection("long-statisctics")
      .doc(data.connectedOn.toString().substring(0, 19))
      .get()
      .then((value) async {
    if (value == null) {
      result = {
        "data": [
          {
            "duration": data.duration.toString(),
            "byte_in": data.byteIn.toString(),
            "byte_out": data.byteOut.toString(),
            "packets_in": data.packetsIn.toString(),
            "packets_out": data.packetsOut.toString(),
          }
        ]
      };
      db
          .collection("long-statisctics")
          .doc(data.connectedOn.toString().substring(0, 19))
          .set(result);
    } else {
      value["data"].add({
        "duration": data.duration.toString(),
        "byte_in": data.byteIn.toString(),
        "byte_out": data.byteOut.toString(),
        "packets_in": data.packetsIn.toString(),
        "packets_out": data.packetsOut.toString(),
      });
      db
          .collection("long-statisctics")
          .doc(data.connectedOn.toString().substring(0, 19))
          .set(value);
    }
  });
}

getServerStats(String date) async {
  final db = Localstore.instance;
  var stats = await db.collection('long-statisctics').doc(date).get();
  return stats;
}

getServersStats() async {
  final db = Localstore.instance;
  var stats = await db.collection('short-statisctics').get();
  return stats;
}

deleteAllStats() async {
  final db = Localstore.instance;
  var stats = await db.collection('short-statisctics').get();
  if (stats != null) {
    stats.forEach((k, v) async {
      k = k.split("/").last;
      await db.collection('short-statisctics').doc(k).delete();
      await db.collection('long-statisctics').doc(k).delete();
    });
  }
}

deleteStat(String date) async {
  final db = Localstore.instance;
  await db.collection('short-statisctics').doc(date).delete();
  await db.collection('long-statisctics').doc(date).delete();
}

getUserData() async {
  final db = Localstore.instance;
  final account = await db.collection('account').doc("0").get();
  if (account != null) {
    var url = Uri.parse('https://$domain/api/is-token-valid');
    var response;
    try {
      response = await http.post(url, body: {
        'token': account['token'],
      });
    } catch (e) {
      return Future.error(e.toString());
    }
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    if (decodedResponse["result"] != false) {
      await db.collection('account').doc("0").set({
        'token': decodedResponse["result"]["token"],
        'email': decodedResponse["result"]["email"],
        'isPremium': decodedResponse["result"]["isPremium"],
        'subscriptionEndDate': decodedResponse["result"]["subscriptionEndDate"]
      });
      return account;
    }
    await db.collection('account').doc("0").delete();
    return false;
  }
  return false;
}

registerUser(String email, String password) async {
  var url = Uri.parse('https://$domain/api/sign-up');
  var response = await http.post(url, body: {
    'email': email,
    'password': password,
  });
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  return decodedResponse;
}

loginUser(String email, String password) async {
  var url = Uri.parse('https://$domain/api/sign-in');
  var response;
  response = await http.post(url, body: {
    'email': email,
    'password': password,
  });
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  return decodedResponse;
}

sendRestoreCode(String email) async {
  var url = Uri.parse('https://$domain/api/send-verification-code');
  var response = await http.post(url, body: {
    'email': email,
  });
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  return decodedResponse;
}

checkRestoreCode(String email, String code) async {
  var url = Uri.parse('https://$domain/api/check-verification-code');
  var response = await http.post(url, body: {
    'email': email,
    'code': code,
  });
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  return decodedResponse;
}

changePassword(String email, String code, String password) async {
  var url = Uri.parse('https://$domain/api/change-password');
  var response = await http.post(url, body: {
    'email': email,
    'code': code,
    'password': password,
  });
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  return decodedResponse;
}

assignUserToTransactionIdAppStore(String email, String? purchaseID) async {
  var url = Uri.parse('https://$domain/api/appstore/verify_purchase');
  var response = await http.post(url, body: {
    'email': email,
    'purchaseID': purchaseID,
  });
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  return decodedResponse;
}

restorePurchasesAppStore(String email) async {
  var url = Uri.parse('https://$domain/api/appstore/restore_purchases');
  var response = await http.post(url, body: {
    'email': email,
  });
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  return decodedResponse;
}

Future<List<Server>> getServers(String token) async {
  List<Server> serverlist = [];
  var url = Uri.parse('https://$domain/api/vpn/get/servers');
  var response;
  try {
    response = await http.post(url, body: {
      'token': token,
    });
  } catch (e) {
    return Future.error(e.toString());
  }

  var decodedResponse = jsonDecode(response.body);
  if (!decodedResponse["error"]) {
    decodedResponse["result"].forEach((n) {
      serverlist.add(Server.fromJson(n));
    });
    return serverlist;
  }
  return serverlist;
}

logoutUser() async {
  final db = Localstore.instance;
  await db.collection('account').doc("0").delete();
  return false;
}
