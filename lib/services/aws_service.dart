// lib/services/aws_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class AwsService {
  static const String apiUrl =
      'https://azatadbeb2.execute-api.ap-east-1.amazonaws.com/prod';

  static const String questionnaireApiUrl =
      'https://dq5v5khoak.execute-api.ap-east-1.amazonaws.com/prod';

  static const String scoringApiUrl =
      'https://bskyyt1o26.execute-api.ap-east-1.amazonaws.com/score';

  /// Base URL for your PDF‐URL Lambda/API
  static const String pdfApiBase =
      'https://tow2vfzaej.execute-api.ap-east-1.amazonaws.com/prod';

  static String? currentUserId;
  static String? currentUserEmail;
  static String? currentUserFirstName;

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<Map<String, dynamic>> registerUser(
    String email,
    String password,
  ) async {
    final hashedPassword = hashPassword(password);
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': hashedPassword}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user_id'] != null) {
          currentUserId = data['user_id'];
          currentUserEmail = email;
          currentUserFirstName = data['first_name'] ?? 'Guest';
        }
        return data;
      } else {
        return {'success': false, 'message': 'Failed to register.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    final hashedPassword = hashPassword(password);
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': hashedPassword}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user_id'] != null) {
          currentUserId = data['user_id'];
          currentUserEmail = email;
          currentUserFirstName = data['first_name'] ?? 'Guest';
        }
        return data;
      } else {
        return {'success': false, 'message': 'Invalid login credentials.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    if (currentUserId == null || currentUserEmail == null) {
      return {
        'success': false,
        'message': 'No logged-in user. Please login first.',
      };
    }
    profileData['user_id'] = currentUserId;
    profileData['email'] = currentUserEmail;
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/updateProfile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(profileData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to update profile.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfilePicture(
    String base64Image,
  ) async {
    if (currentUserId == null) {
      return {'success': false, 'message': 'No logged-in user.'};
    }
    final payload = {'user_id': currentUserId, 'profile_picture': base64Image};
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/updateProfilePicture'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to update profile picture.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProfileDetails(String userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/getProfile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch profile details.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> saveQuestionnaireResponses(
    Map<int, String> answers,
  ) async {
    if (currentUserId == null) {
      return {'success': false, 'message': 'No logged-in user.'};
    }
    final Map<int, int> indexedAnswers = {};
    answers.forEach((index, value) {
      final int? intVal = int.tryParse(value);
      if (intVal != null) {
        indexedAnswers[index] = intVal;
      }
    });
    final payload = {
      'user_id': currentUserId!,
      'timestamp': DateTime.now().toIso8601String(),
      'answers': indexedAnswers.map((k, v) => MapEntry(k.toString(), v)),
    };
    try {
      final response = await http
          .post(
            Uri.parse('$questionnaireApiUrl/saveQuestionnaireResponse'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to save responses.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getScoredResults() async {
    if (currentUserId == null) {
      return {'success': false, 'message': 'No logged-in user.'};
    }
    try {
      final response = await http
          .post(
            Uri.parse(scoringApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': currentUserId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch results.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Fetches the public PDF URL for the given S3 key
  static Future<String?> fetchPdfUrl(String key) async {
    try {
      final resp = await http.post(
        Uri.parse('$pdfApiBase/getGuideUrl'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': key}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Fetches the public video URL for the given key
  static Future<String?> fetchVideoUrlFromApi(String videoKey) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://7vtuejho81.execute-api.ap-east-1.amazonaws.com/prod_v2/getVideoUrl',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': videoKey}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
