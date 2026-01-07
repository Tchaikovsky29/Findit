import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final List<Map<String, dynamic>> foundItems = [];

Response _addItem(Request request) async {
  final body = await request.readAsString();
  final data = jsonDecode(body);

  foundItems.add({
    "itemName": data["itemName"],
    "imageUrl": data["imageUrl"],
    "date": DateTime.now().toIso8601String()
  });

  return Response.ok(
    jsonEncode({"message": "Item added successfully"}),
    headers: {"Content-Type": "application/json"},
  );
}

Response _getItems(Request request) {
  return Response.ok(
    jsonEncode(foundItems),
    headers: {"Content-Type": "application/json"},
  );
}

void main() async {
  final router = Router()
    ..post('/add-item', _addItem)
    ..get('/items', _getItems);

  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Server running on http://localhost:${server.port}');
}
