import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultService {
  static const String _detailsKey = 'vault_details';
  static const String _docsMetadataKey = 'vault_docs_metadata';

  // --- Personal Details ---

  // Get all details
  Future<List<Map<String, String>>> getDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? detailsJson = prefs.getString(_detailsKey);
    if (detailsJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(detailsJson);
      return decoded.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      debugPrint('Error decoding details: $e');
      return [];
    }
  }

  // Save new detail (or update existing if key matches - handled by caller logic usually, but here we just append or replace)
  // For simplicity, let's just save the whole list
  Future<void> saveDetails(List<Map<String, String>> details) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(details);
    await prefs.setString(_detailsKey, encoded);
  }

  // --- Documents ---

  Future<String> _getDocsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/vault_docs');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir.path;
  }

  // Get all documents metadata
  Future<List<Map<String, dynamic>>> getDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? docsJson = prefs.getString(_docsMetadataKey);
    if (docsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(docsJson);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Error decoding docs: $e');
      return [];
    }
  }

  Future<void> _saveDocsMetadata(List<Map<String, dynamic>> docs) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(docs);
    await prefs.setString(_docsMetadataKey, encoded);
  }

  // Add document
  Future<Map<String, dynamic>> addDocument(File file, String name) async {
    final vaultPath = await _getDocsPath();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final String newPath = '$vaultPath/$fileName';
    
    await file.copy(newPath);
    
    final int sizeBytes = await file.length();
    String sizeStr = '';
    if (sizeBytes < 1024) {
      sizeStr = '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      sizeStr = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      sizeStr = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    final newDoc = {
      'name': name,
      'path': newPath,
      'size': sizeStr,
      'date': DateTime.now().toIso8601String(),
    };

    final docs = await getDocuments();
    docs.insert(0, newDoc);
    await _saveDocsMetadata(docs);
    return newDoc;
  }

  // Delete document
  Future<void> deleteDocument(int index) async {
    final docs = await getDocuments();
    if (index >= 0 && index < docs.length) {
      final doc = docs[index];
      final File file = File(doc['path']);
      if (await file.exists()) {
        await file.delete();
      }
      docs.removeAt(index);
      await _saveDocsMetadata(docs);
    }
  }

  // Rename document
  Future<void> renameDocument(int index, String newName) async {
    final docs = await getDocuments();
    if (index >= 0 && index < docs.length) {
      docs[index]['name'] = newName;
      await _saveDocsMetadata(docs);
    }
  }
}
