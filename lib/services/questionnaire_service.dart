import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionnaireService {
  static Future<List<Map<String, dynamic>>> loadQuestionnaire() async {
    final client = Supabase.instance.client;

    final data = await client.storage
        .from('ncae-preassessment-data')
        .download('questionnaire.json');

    final decoded = json.decode(utf8.decode(data));
    final list = (decoded as List).cast<Map<String, dynamic>>();

    // ✅ Shuffle the questions every time
    list.shuffle(Random());

    return list;
  }
}
