// lib/services/supabase_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

final supa = Supabase.instance.client;

class SupabaseService {
  // ---------- AUTH ----------
  static String? get authUserId => supa.auth.currentUser?.id;
  static String? get authEmail => supa.auth.currentUser?.email;
  static bool get isLoggedIn => supa.auth.currentUser != null;

  static Future<AuthResponse> registerUser(
    String email,
    String password,
  ) async {
    final res = await supa.auth.signUp(email: email, password: password);

    if (res.user != null) {
      final uid = res.user!.id;

      // Create user profile
      await supa.from('users').upsert({
        'supabase_id': uid,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });

      // ✅ Seed default skill_progress (avoid duplicates with onConflict)
      await supa.from('skill_progress').upsert([
        {
          'user_id': uid,
          'module_id': 'programming_fundamentals',
          'lessons_completed': 0,
          'lessons_total': 20,
        },
        {
          'user_id': uid,
          'module_id': 'problem_solving',
          'lessons_completed': 0,
          'lessons_total': 20,
        },
        {
          'user_id': uid,
          'module_id': 'communication_skills',
          'lessons_completed': 0,
          'lessons_total': 20,
        },
      ], onConflict: 'user_id,module_id');

      // ✅ Seed default quiz_progress (avoid duplicates with onConflict)
      await supa.from('quiz_progress').upsert([
        {
          'user_id': uid,
          'quiz_id': 'basic_programming_quiz',
          'status': 'unlocked',
          'score': null,
          'answers': null,
        },
        {
          'user_id': uid,
          'quiz_id': 'logic_algorithms',
          'status': 'locked',
          'score': null,
          'answers': null,
        },
        {
          'user_id': uid,
          'quiz_id': 'advanced_concepts',
          'status': 'locked',
          'score': null,
          'answers': null,
        },
      ], onConflict: 'user_id,quiz_id');
    }
    return res;
  }

  static Future<AuthResponse> loginUser(String email, String password) async {
    return await supa.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await supa.auth.signOut();
  }

  // ---------- USERS ----------
  static Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = authUserId;
    if (uid == null) return null;

    return await supa
        .from('users')
        .select()
        .eq('supabase_id', uid)
        .maybeSingle();
  }

  static Future<void> upsertMyProfile(Map<String, dynamic> patch) async {
    final uid = authUserId;
    if (uid == null) throw 'Not logged in';

    patch['supabase_id'] = uid;
    await supa.from('users').upsert(patch);
  }

  // ---------- QUESTIONNAIRE ----------
  static Future<void> saveQuestionnaireResponses(Map<int, int> answers) async {
    final uid = authUserId;
    if (uid == null) throw 'Not logged in';

    await supa.from('questionnaireresponses').insert({
      'response_id': "${uid}_${DateTime.now().millisecondsSinceEpoch}",
      'user_id': uid,
      'timestamp': DateTime.now().toIso8601String(),
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
    });
  }

  static Future<Map<String, dynamic>?> getLatestResponse() async {
    final uid = authUserId;
    if (uid == null) return null;

    return await supa
        .from('questionnaireresponses')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  static Future<List<Map<String, dynamic>>> loadQuestionnaire() async {
    final data = await supa.storage
        .from('ncae-preassessment-data')
        .download('questionnaire.json');

    final decoded = json.decode(utf8.decode(data));
    final list = (decoded as List).cast<Map<String, dynamic>>();

    list.shuffle(Random()); // ✅ Shuffle questions each time
    return list;
  }

  static List<Map<String, dynamic>> processResults(
    Map<String, dynamic> answersJson,
    List<Map<String, dynamic>> questionnaire,
  ) {
    final Map<String, int> totalScores = {};
    final Map<String, int> maxScores = {};

    for (int i = 0; i < questionnaire.length; i++) {
      final q = questionnaire[i];
      final category = q['category'] as String;
      final correctIndex = q['correct_index'] as int;

      maxScores[category] = (maxScores[category] ?? 0) + 1;

      if (answersJson.containsKey('$i')) {
        final selected = answersJson['$i'];
        if (selected == correctIndex) {
          totalScores[category] = (totalScores[category] ?? 0) + 1;
        }
      }
    }

    final results = <Map<String, dynamic>>[];
    maxScores.forEach((category, max) {
      final score = totalScores[category] ?? 0;
      final pct = (score / max) * 100;
      final level = _getLevel(pct);

      results.add({
        'category': category,
        'score': score,
        'percentage': pct.toStringAsFixed(1),
        'level': level,
        'rank': 0,
      });
    });

    results.sort(
      (a, b) => double.parse(
        b['percentage'],
      ).compareTo(double.parse(a['percentage'])),
    );
    for (var i = 0; i < results.length; i++) {
      results[i]['rank'] = i + 1;
    }
    return results;
  }

  static String _getLevel(double pct) {
    if (pct >= 70) return 'HP';
    if (pct >= 51) return 'MP';
    return 'LP';
  }

  // ---------- QUESTIONNAIRE RESULTS ----------
  static Future<void> saveProcessedResults(
    List<Map<String, dynamic>> results,
  ) async {
    final uid = authUserId;
    if (uid == null) throw 'Not logged in';

    await supa.from('questionnaire_results').insert({
      'result_id': "${uid}_${DateTime.now().millisecondsSinceEpoch}",
      'user_id': uid,
      'timestamp': DateTime.now().toIso8601String(),
      'results': results,
    });
  }

  static Future<Map<String, dynamic>?> getLatestProcessedResults() async {
    final uid = authUserId;
    if (uid == null) return null;

    return await supa
        .from('questionnaire_results')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  // ---------- SKILL PROGRESS ----------
  static Future<void> updateSkillProgress(
    String moduleId,
    int lessonsCompleted,
    int lessonsTotal,
  ) async {
    final uid = authUserId;
    if (uid == null) throw 'Not logged in';

    await supa.from('skill_progress').upsert({
      'user_id': uid,
      'module_id': moduleId,
      'lessons_completed': lessonsCompleted,
      'lessons_total': lessonsTotal,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,module_id'); // ✅ no duplicates
  }

  static Future<List<Map<String, dynamic>>> getSkillProgress() async {
    final uid = authUserId;
    if (uid == null) return [];
    return await supa.from('skill_progress').select().eq('user_id', uid);
  }

  // ---------- QUIZ PROGRESS ----------
  static Future<void> updateQuizProgress(
    String quizId, {
    String status = 'in_progress',
    int? score,
    Map<int, int>? answers,
  }) async {
    final uid = authUserId;
    if (uid == null) throw 'Not logged in';

    await supa.from('quiz_progress').upsert({
      'user_id': uid,
      'quiz_id': quizId,
      'status': status,
      'score': score,
      'answers':
          answers != null
              ? answers.map((k, v) => MapEntry(k.toString(), v))
              : null,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,quiz_id'); // ✅ no duplicates
  }

  static Future<List<Map<String, dynamic>>> getQuizProgress() async {
    final uid = authUserId;
    if (uid == null) return [];
    return await supa.from('quiz_progress').select().eq('user_id', uid);
  }

  // ---------- LOAD LESSONS ----------
  static Future<List<Map<String, dynamic>>> loadSkillModule(
    String moduleId,
  ) async {
    try {
      final data = await supa.storage
          .from("skill-modules")
          .download("$moduleId.json");

      final decoded = json.decode(utf8.decode(data));

      if (decoded is Map<String, dynamic> && decoded.containsKey("lessons")) {
        return (decoded["lessons"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      return [];
    } catch (e) {
      print("Error loading module: $e");
      return [];
    }
  }

  // ---------- LOAD QUIZZES ----------
  static Future<List<Map<String, dynamic>>> loadQuiz(String quizId) async {
    try {
      final data = await supa.storage
          .from("adaptive-quizzes")
          .download("$quizId.json");

      final decoded = json.decode(utf8.decode(data));

      if (decoded is Map<String, dynamic> && decoded.containsKey("questions")) {
        return (decoded["questions"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      return [];
    } catch (e) {
      print("Error loading quiz: $e");
      return [];
    }
  }

  // ---------- STORAGE ----------
  static Future<String> uploadAvatar({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final uid = authUserId ?? (throw 'Not logged in');
    final path = '$uid/$fileName';

    await supa.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            cacheControl: '3600',
            contentType: _guessContentType(fileName),
          ),
        );

    return supa.storage.from('avatars').getPublicUrl(path);
  }

  // ✅ NEW: Dynamic list of PDFs
  static Future<List<FileObject>> listPdfFiles() async {
    return await supa.storage.from('my-study-guides').list();
  }

  static Future<String?> getPdfUrl(String key) async {
    return supa.storage.from('my-study-guides').getPublicUrl(key);
  }

  // ✅ NEW: Dynamic list of videos
  static Future<List<FileObject>> listVideoFiles() async {
    return await supa.storage.from('study-guide-videos').list();
  }

  static Future<String?> getVideoUrl(String key) async {
    return supa.storage.from('study-guide-videos').getPublicUrl(key);
  }

  static Future<String?> getFileUrl({
    required String bucket,
    required String path,
    int expiresIn = 86400,
  }) async {
    try {
      return supa.storage.from(bucket).getPublicUrl(path);
    } catch (_) {
      return await supa.storage.from(bucket).createSignedUrl(path, expiresIn);
    }
  }

  // ---------- HELPERS ----------
  static String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
