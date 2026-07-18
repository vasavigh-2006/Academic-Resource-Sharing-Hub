import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../config/secrets.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  // Cloudinary Configuration — credentials stored in lib/config/secrets.dart (gitignored)
  final String _cloudName = AppSecrets.cloudinaryCloudName;
  final String _uploadPreset = AppSecrets.cloudinaryUploadPreset;

  Future<Map<String, String>?> uploadMaterial(String userId) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
    } catch (pickerErr) {
      throw Exception('Failed to open file picker: $pickerErr');
    }

    if (result == null || result.files.isEmpty) {
      return null; // User cancelled
    }

    String? path = result.files.single.path;
    if (path == null) {
      throw Exception('Could not resolve file path. If you are picking a cloud file, please copy it locally first.');
    }

    File file = File(path);
    String fileName = result.files.single.name;
    
    try {
      var url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

      var request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'materials/$userId';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var client = http.Client();
      var response = await client.send(request).timeout(const Duration(seconds: 45));
      var responseData = await response.stream.bytesToString();
      client.close();
      
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        String downloadUrl = jsonResponse['secure_url'];
        String publicId = jsonResponse['public_id'];

        return {
          'url': downloadUrl,
          'fileName': fileName,
          'filePath': publicId,
        };
      } else {
        String errMsg = jsonResponse['error']?['message'] ?? 'Status code ${response.statusCode}';
        throw Exception('Cloudinary error: $errMsg');
      }
    } catch (e) {
      throw Exception('Upload connection error: $e');
    }
  }

  Future<Map<String, String>?> uploadChatAttachment(String userId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        
        var url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

        var request = http.MultipartRequest('POST', url);
        request.fields['upload_preset'] = _uploadPreset;
        request.fields['folder'] = 'chats/$userId';
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        // Send Request with a 45-second timeout to prevent infinite hanging
        var client = http.Client();
        var response = await client.send(request).timeout(const Duration(seconds: 45));
        var responseData = await response.stream.bytesToString();
        client.close();
        var jsonResponse = json.decode(responseData);

        if (response.statusCode == 200) {
          String downloadUrl = jsonResponse['secure_url'];
          String publicId = jsonResponse['public_id'];
          String extension = fileName.split('.').last.toLowerCase();
          String fileType = ['png', 'jpg', 'jpeg', 'gif'].contains(extension) ? 'image' : 'document';

          return {
            'url': downloadUrl,
            'fileName': fileName,
            'fileType': fileType,
            'filePath': publicId,
          };
        } else {
          print('Cloudinary Chat Upload Error: ${jsonResponse['error']['message']}');
        }
      }
    } catch (e) {
      print('General Chat Upload Error: $e');
    }
    return null;
  }

  Future<bool> deleteFile(String filePath) async {
    // Note: Unsigned presets usually don't support deletion for security.
    // Deletion would require a signed request with API Secret, which shouldn't be in a mobile app.
    print('Manual cleanup required in Cloudinary console for: $filePath');
    return true; // Return true to avoid breaking the UI flow
  }

  Future<int?> getFileSize(String fileUrl) async {
    try {
      final response = await http.head(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        return int.tryParse(response.headers['content-length'] ?? '');
      }
    } catch (e) {
      print('Get File Size Error: $e');
    }
    return null;
  }
}