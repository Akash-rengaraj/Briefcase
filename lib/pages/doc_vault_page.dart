import 'package:flutter/material.dart';

class DocVaultPage extends StatefulWidget {
  const DocVaultPage({super.key});

  @override
  State<DocVaultPage> createState() => _DocVaultPageState();
}

class _DocVaultPageState extends State<DocVaultPage> {
  // Mock data for documents
  final List<Map<String, dynamic>> _documents = [
    {'name': 'Project Proposal', 'date': DateTime.now().subtract(const Duration(days: 1)), 'size': '2.4 MB'},
    {'name': 'Financial Report', 'date': DateTime.now().subtract(const Duration(days: 3)), 'size': '1.1 MB'},
    {'name': 'Meeting Notes', 'date': DateTime.now().subtract(const Duration(days: 5)), 'size': '500 KB'},
  ];

  // Function to show "Add Document" dialog
  Future<void> _addDocument() async {
    String? docName;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upload Document'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Document Name',
              hintText: 'Enter document name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              docName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (docName != null && docName!.isNotEmpty) {
                   Navigator.pop(context);
                   setState(() {
                     _documents.insert(0, {
                       'name': docName!,
                       'date': DateTime.now(),
                       'size': '0 KB', // Mock size
                     });
                   });
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Document "$docName" uploaded successfully')),
                   );
                }
              },
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  // Function to rename document
  Future<void> _renameDocument(int index) async {
    String docName = _documents[index]['name'];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Document'),
          content: TextField(
            autofocus: true,
            controller: TextEditingController(text: docName),
            decoration: const InputDecoration(
              labelText: 'New Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              docName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                 if (docName.isNotEmpty) {
                   setState(() {
                     _documents[index]['name'] = docName;
                   });
                   Navigator.pop(context);
                 }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

   // Function to delete document
  void _deleteDocument(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: Text('Are you sure you want to delete "${_documents[index]['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  _documents.removeAt(index);
                });
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Document deleted')),
                 );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Generic action placeholder
  void _viewDocument(int index) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Viewing "${_documents[index]['name']}"...')),
      );
  }

   void _downloadDocument(int index) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Downloading "${_documents[index]['name']}"...')),
      );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doc Vault'),
        // ensure plus symbol is at the top right corner in the left of the setting button
        actions: [
          IconButton(
            onPressed: _addDocument,
            icon: const Icon(Icons.add),
            tooltip: 'Upload Document',
          ),
          IconButton(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Settings clicked')),
               );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8), 
        ],
      ),
      body: _documents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   Text(
                     'No documents yet',
                     style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                   ),
                   const SizedBox(height: 8),
                   TextButton.icon(
                     onPressed: _addDocument,
                     icon: const Icon(Icons.add),
                     label: const Text('Upload your first document'),
                   )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return Card(
                  elevation: 0,
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text(
                      doc['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${doc['size']} • ${_formatDate(doc['date'])}'),
                    onTap: () => _viewDocument(index),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                         switch (value) {
                           case 'view': _viewDocument(index); break;
                           case 'download': _downloadDocument(index); break;
                           case 'rename': _renameDocument(index); break;
                           case 'delete': _deleteDocument(index); break;
                         }
                      },
                      itemBuilder: (context) => [
                         const PopupMenuItem(
                           value: 'view',
                           child: Row(children: [Icon(Icons.visibility, size: 20), SizedBox(width: 8), Text('View')]),
                         ),
                         const PopupMenuItem(
                           value: 'download',
                           child: Row(children: [Icon(Icons.download, size: 20), SizedBox(width: 8), Text('Download')]),
                         ),
                         const PopupMenuItem(
                           value: 'rename',
                           child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Rename')]),
                         ),
                         const PopupMenuItem(
                           value: 'delete',
                           child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                         ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
