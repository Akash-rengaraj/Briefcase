import 'dart:io';
import 'package:briefcase/services/vault_service.dart';
import 'package:briefcase/widgets/detail_item.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class DocVaultPage extends StatefulWidget {
  const DocVaultPage({super.key});

  @override
  State<DocVaultPage> createState() => _DocVaultPageState();
}

class _DocVaultPageState extends State<DocVaultPage> {
  final VaultService _vaultService = VaultService();
  List<Map<String, String>> _details = [];
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final details = await _vaultService.getDetails();
    final docs = await _vaultService.getDocuments(); // Fix: method name was missing in service? checking service code... 
    // Wait, I implemented getDocuments in service.
    setState(() {
      _details = details;
      _documents = docs;
      _isLoading = false;
    });
  }

  // --- Details Logic ---

  Future<void> _addOrEditDetail({int? index}) async {
    String key = index != null ? _details[index].keys.first : '';
    String value = index != null ? _details[index].values.first : '';
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index != null ? 'Edit Detail' : 'Add Detail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: key),
                decoration: const InputDecoration(labelText: 'Label (e.g., Passport)'),
                onChanged: (v) => key = v,
                enabled: index == null, // Allow editing key only if new? Or allow both. Let's allow both.
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: value),
                decoration: const InputDecoration(labelText: 'Value (e.g., A1234567)'),
                onChanged: (v) => value = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (key.isNotEmpty && value.isNotEmpty) {
                  Navigator.pop(context);
                  if (index != null) {
                    _details[index] = {key: value};
                  } else {
                    _details.add({key: value});
                  }
                  await _vaultService.saveDetails(_details); // Need this method in service
                  setState(() {});
                }
              },
              child: Text(index != null ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDetail(int index) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Detail'),
        content: const Text('Are you sure you want to delete this detail?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              _details.removeAt(index);
              await _vaultService.saveDetails(_details);
              setState(() {});
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- Document Logic ---

  Future<void> _pickAndAddDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final name = result.files.single.name;
      
      await _vaultService.addDocument(file, name);
      _loadData(); // Reload to get updated list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded "$name"')),
        );
      }
    }
  }

  Future<void> _deleteDocument(int index) async {
     await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${_documents[index]['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _vaultService.deleteDocument(index);
              _loadData();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameDocument(int index) async {
     String newName = _documents[index]['name'];
     await showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Rename Document'),
         content: TextField(
           controller: TextEditingController(text: newName),
           onChanged: (v) => newName = v,
           decoration: const InputDecoration(labelText: 'New Name'),
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
           FilledButton(
             onPressed: () async {
               if (newName.isNotEmpty) {
                 Navigator.pop(context);
                 await _vaultService.renameDocument(index, newName);
                 _loadData();
               }
             },
             child: const Text('Rename'),
           ),
         ],
       ),
     );
  }

  void _openDocument(int index) {
    final path = _documents[index]['path'];
    if (path != null) {
      OpenFile.open(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doc Vault'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Details Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _addOrEditDetail(),
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Add Detail',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_details.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: const Text('No details added yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    )
                  else if (!_showDetails)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            setState(() {
                              _showDetails = true;
                            });
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Show Details'),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _details.length,
                          itemBuilder: (context, index) {
                            final detail = _details[index];
                            final key = detail.keys.first;
                            final value = detail.values.first;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DetailItem(
                                label: key,
                                value: value,
                                onTap: () => _addOrEditDetail(index: index),
                                onDelete: () => _deleteDetail(index),
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showDetails = false;
                            });
                          },
                          icon: const Icon(Icons.visibility_off),
                          label: const Text('Hide Details'),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // --- Documents Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Documents',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: _pickAndAddDocument,
                        icon: const Icon(Icons.upload_file),
                        tooltip: 'Upload Document',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_documents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No documents uploaded', style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: _pickAndAddDocument,
                            child: const Text('Upload Now'),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.description, color: Theme.of(context).primaryColor),
                            ),
                            title: Text(doc['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(doc['size'] ?? ''),
                            onTap: () => _openDocument(index),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'rename') _renameDocument(index);
                                if (value == 'delete') _deleteDocument(index);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  // Add extra padding at bottom for FAB or just visual spacing
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
