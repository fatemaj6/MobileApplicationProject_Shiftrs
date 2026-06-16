import 'package:firebase_ai/firebase_ai.dart';

class AiService {
  AiService();

  static const String _modelName =
      'gemini-2.5-flash'; //model can be changed later

  GenerativeModel _buildModel(String? systemInstruction) {
    return FirebaseAI.googleAI().generativeModel(
      model: _modelName,
      systemInstruction: systemInstruction == null
          ? null
          : Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.4,
        maxOutputTokens: 1024,
      ),
    );
  }

  //session keeps chat history
  ChatSession startChat({required String systemInstruction}) {
    return _buildModel(systemInstruction).startChat();
  }

  //no chat history session
  Future<String> generateOnce(
    String prompt, {
    String? systemInstruction,
  }) async {
    final response = await _buildModel(
      systemInstruction,
    ).generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? '';
  }
}
