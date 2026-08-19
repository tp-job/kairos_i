import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/env/env.dart';
import '../models/orchestrator_models.dart';

/// Everything AI-related goes through this one service: intent parsing
/// (Feature 1.2) and news summarization (Feature 5.2) both call
/// OpenRouter's OpenAI-compatible chat/completions endpoint, just with
/// different prompts.
class OpenRouterService {
  OpenRouterService(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // Free-tier model on OpenRouter. Swap this for any other ":free"
  // model id from https://openrouter.ai/models?max_price=0 if this
  // one gets deprecated or rate-limited.
  static const _model = 'meta-llama/llama-3.1-8b-instruct:free';

  Future<String> _complete(String systemPrompt, String userPrompt) =>
      _completeWithHistory(systemPrompt, [
        {'role': 'user', 'content': userPrompt},
      ]);

  /// The general form: a system prompt plus however many prior turns.
  ///
  /// The single-message version above is the special case. Sending history is
  /// the whole difference between a command box and a conversation — without
  /// it "แล้วเลื่อนเป็นบ่ายสอง" is unanswerable because the model has never
  /// seen what is being moved.
  Future<String> _completeWithHistory(
    String systemPrompt,
    List<Map<String, String>> turns,
  ) async {
    final response = await _dio.post(
      _baseUrl,
      options: Options(headers: {
        'Authorization': 'Bearer ${Env.openRouterApiKey}',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...turns,
        ],
        'temperature': 0.3,
      },
    );

    return response.data['choices'][0]['message']['content'] as String;
  }

  /// Strips markdown code fences (```json ... ```) that chat models
  /// love to wrap JSON in, even when told not to.
  Map<String, dynamic> _extractJson(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'^```(json)?', multiLine: true), '')
        .replaceAll('```', '')
        .trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  /// Feature 1.2 NLP: turn a free-text command into a ParsedIntent.
  /// [nowIso] is injected instead of using DateTime.now() inside the
  /// prompt string, so relative dates ("พรุ่งนี้") resolve against a
  /// known reference time the model is told about explicitly.
  Future<ParsedIntent> parseIntent(String userMessage) async {
    final now = DateTime.now();
    final systemPrompt = '''
คุณคือ Orchestrator ของแอป Kairos มีหน้าที่แปลงข้อความภาษาธรรมชาติของผู้ใช้
ให้เป็น JSON เท่านั้น ห้ามมีข้อความอื่นนอกเหนือจาก JSON object

วันเวลาปัจจุบันคือ ${now.toIso8601String()}

รูปแบบ JSON ที่ต้องตอบกลับ:
{
  "role": "weather" | "tasks" | "techNews" | "market" | "general",
  "action": "create_task" | "answer_question" | "none",
  "task_name": string หรือ null,
  "due_date": ISO8601 string หรือ null,
  "reply_text": string หรือ null (คำตอบสั้นๆ ถ้า action เป็น answer_question)
}

ตัวอย่าง: "พรุ่งนี้บ่ายโมงมีนัดส่งงาน" ->
role=tasks, action=create_task, task_name="ส่งงาน", due_date=พรุ่งนี้เวลา 13:00
''';

    final raw = await _complete(systemPrompt, userMessage);
    return ParsedIntent.fromJson(_extractJson(raw));
  }

  /// The chat turn: the same JSON contract as [parseIntent], but with the
  /// conversation so far in front of it.
  ///
  /// [turns] is oldest-first and already trimmed by the caller — a free-tier
  /// context window is small, and an unbounded transcript starts failing
  /// silently once it overflows.
  Future<ParsedIntent> parseConversation(
    List<Map<String, String>> turns,
  ) async {
    final now = DateTime.now();
    final systemPrompt = '''
คุณคือผู้ช่วยของแอป Kairos คุยกับผู้ใช้เป็นภาษาไทยแบบเป็นกันเอง
ตอบกลับเป็น JSON object เท่านั้น ห้ามมีข้อความอื่นนอกเหนือจาก JSON

วันเวลาปัจจุบันคือ ${now.toIso8601String()}

รูปแบบ JSON:
{
  "role": "weather" | "tasks" | "techNews" | "market" | "general",
  "action": "create_task" | "answer_question" | "none",
  "task_name": string หรือ null,
  "due_date": ISO8601 string หรือ null,
  "reply_text": string (สิ่งที่จะพูดกับผู้ใช้ ต้องมีเสมอ)
}

กติกา:
- "reply_text" ต้องมีค่าเสมอ เพราะเป็นสิ่งที่ผู้ใช้จะเห็น
- ถ้าผู้ใช้สั่งสร้างงาน ให้ action=create_task และสรุปสั้นๆ ใน reply_text
- ถ้าผู้ใช้ถามต่อจากข้อความก่อนหน้า ให้ใช้บริบทจากบทสนทนาด้านบน
- ถ้าไม่แน่ใจเรื่องวันเวลา ให้ถามกลับ โดยใช้ action=none
''';

    final raw = await _completeWithHistory(systemPrompt, turns);
    return ParsedIntent.fromJson(_extractJson(raw));
  }

  /// Feature 5.2: compress one article into a 3-line bullet summary.
  Future<String> summarizeToThreeLines({
    required String title,
    required String description,
  }) async {
    const systemPrompt =
        'สรุปข่าวเทคโนโลยีต่อไปนี้เป็นภาษาไทย 3 บรรทัดสั้นๆ แบบ bullet '
        'ห้ามมีคำนำหรือข้อความอื่นนอกจากสรุป';

    return _complete(systemPrompt, 'หัวข้อ: $title\nเนื้อหา: $description');
  }

  /// Feature 1.3 Cross-API Synthesis: combine two already-fetched
  /// signals (e.g. weather + upcoming tasks) into one advisory sentence.
  Future<String> synthesizeAdvice({
    required String weatherSummary,
    required String scheduleSummary,
  }) async {
    const systemPrompt =
        'คุณเป็นผู้ช่วยส่วนตัวที่ผสมข้อมูลสภาพอากาศกับตารางนัดหมาย '
        'แล้วให้คำแนะนำสั้นๆ 1 ประโยคภาษาไทย ถ้าไม่มีความเสี่ยงให้ตอบให้กำลังใจสั้นๆ แทน';

    return _complete(
      systemPrompt,
      'สภาพอากาศ: $weatherSummary\nตารางนัดหมาย: $scheduleSummary',
    );
  }
}
