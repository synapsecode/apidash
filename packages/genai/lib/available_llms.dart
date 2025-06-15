import 'dart:convert';
import 'dart:math';
import 'package:apidash_core/apidash_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, List<List<String>>> DEFAULT_LLMS = {
  "openai": [
    ["gpt-4o", "GPT-4o"],
    ["gpt-4", "GPT-4"],
    ["gpt-3.5-turbo", "GPT-3.5 Turbo"],
  ],
  "anthropic": [
    ["claude-3-haiku-latest", "Claude 3 Haiku"],
  ],
  "gemini": [
    ["gemini-2.0-flash", "Gemini 2.0 Flash"],
  ],
  "ollama": [
    ["llama3", "Llama 3"],
    ["gemma3", "Gemma 3"],
  ],
};

Map<String, List<List<String>>> AVAILABLE_LLMS = {};

void fetchAvailableLLMs([String remoteURL = '']) async {
  //get LLMs from remove
  // saveAvailableLLMs(...)
}

saveAvailableLLMs(Map<String, List<List<String>>> updatedLLMs) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('genai_available_llms', jsonEncode(updatedLLMs));
}

loadAvailableLLMs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final avl = prefs.getString('genai_available_llms');
  if (avl == null) {
    AVAILABLE_LLMS = DEFAULT_LLMS;
  } else {
    AVAILABLE_LLMS = jsonDecode(avl);
  }
}

fetchAvailableOllamaModels() {}
