import 'dart:convert';
import 'package:apidash_core/apidash_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LLMManager {
  static Map avaiableModels = {
    "gemini": [
      ["gemini-2.0-flash", "Gemini 2.0 Flash"],
    ],
  };

  static get models => avaiableModels;

  static const String modelRemoteURL =
      'https://raw.githubusercontent.com/synapsecode/apidash/llm_model_rearch/packages/genai/models.json';
  static const String baseOllamaURL = 'http://localhost:11434';

  static fetchAvailableLLMs([String? remoteURL, String? ollamaURL]) async {
    //get LLMs from remove
    final (resp, _, __) = await sendHttpRequest(
      'FETCH_MODELS',
      APIType.rest,
      HttpRequestModel(url: remoteURL ?? modelRemoteURL, method: HTTPVerb.get),
    );
    if (resp == null) {
      throw Exception('UNABLE TO FETCH MODELS');
    }
    Map remoteModels = jsonDecode(resp.body);
    final oM = await fetchInstalledOllamaModels(ollamaURL);
    remoteModels['ollama'] = oM;
    saveAvailableLLMs(remoteModels);
    loadAvailableLLMs();
  }

  static saveAvailableLLMs(Map updatedLLMs) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('genai_available_llms', jsonEncode(updatedLLMs));
  }

  static loadAvailableLLMs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final avl = prefs.getString('genai_available_llms');
    if (avl != null) {
      avaiableModels = (jsonDecode(avl));
    }
  }

  static clearAvailableLLMs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('genai_available_llms');
  }

  static Future<List?> fetchInstalledOllamaModels([String? ollamaURL]) async {
    final url = "${ollamaURL ?? baseOllamaURL}/api/tags";
    final (resp, _, __) = await sendHttpRequest(
      'OLLAMA_FETCH',
      APIType.rest,
      HttpRequestModel(url: url, method: HTTPVerb.get),
      noSSL: true,
    );
    if (resp == null) return [];
    final output = jsonDecode(resp.body);
    final models = output['models'];
    if (models == null) return [];
    List ollamaModels = [];
    for (final m in models) {
      ollamaModels.add([m['model'], m['name']]);
    }
    return ollamaModels;
  }
}
