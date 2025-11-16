import 'dart:typed_data';
import 'package:flutter/material.dart';

class WriterArticleDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String status;
  final String date;
  final String? rejectionReason;
  final Uint8List? imageBytes;

  const WriterArticleDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.status,
    required this.date,
    this.rejectionReason,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Submission"),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            imageBytes != null
                ? Image.memory(imageBytes!,
                fit: BoxFit.cover, width: double.infinity, height: 250)
                : Container(
              color: Colors.grey[300],
              width: double.infinity,
              height: 250,
              child: const Icon(Icons.image_not_supported, size: 50),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Text(
                    "Status: $status",
                    style: TextStyle(
                      fontSize: 14,
                      color: status.toLowerCase() == "approved"
                          ? Colors.green
                          : status.toLowerCase() == "rejected"
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text("Submitted on: $date",
                      style:
                      const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 16),

                  if (status.toLowerCase() == "rejected" &&
                      rejectionReason != null &&
                      rejectionReason!.isNotEmpty) ...[
                    const Text(
                      "Reason for Rejection:",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rejectionReason!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text(
                    "Content:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content.isNotEmpty ? content : "No content provided",
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
