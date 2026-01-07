import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const LostFoundApp());
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost & Found',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  List items = [];

  Future<void> fetchItems() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/items'),
    );
    setState(() {
      items = jsonDecode(response.body);
    });
  }

  Future<void> addItem() async {
    await http.post(
      Uri.parse('http://localhost:8080/add-item'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "itemName": itemController.text,
        "imageUrl": imageController.text,
      }),
    );

    itemController.clear();
    imageController.clear();
    fetchItems();
  }

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: itemController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: addItem,
              child: const Text('Upload Found Item'),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: Image.network(
                        item['imageUrl'],
                        width: 50,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                      title: Text(item['itemName']),
                      subtitle: Text(item['date']),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
