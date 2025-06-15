import 'dart:math';
import 'anthropic.dart';
import 'azureopenai.dart';
import 'common.dart';
import 'gemini.dart';
import 'ollama.dart';
import 'openai.dart';

Map<String, List<List<String>>> AVAILABLE_LLMS = {
  'openai': [
    ['gpt-4o', 'GPT-4o'],
    ['gpt-4', 'GPT-4'],
    ['gpt-4o-mini', 'GPT-4o Mini'],
    ['gpt-4-turbo', 'GPT-4 Turbo'],
    ['gpt-4.1', 'GPT-4.1'],
    ['gpt-4.1-mini', 'GPT-4.1 Mini'],
    ['gpt-4.1-nano', 'GPT-4.1 Nano'],
    ['o1', 'o1'],
    ['o3', 'o3'],
    ['o3-mini', 'o3 Mini'],
    ['gpt-3.5-turbo', 'GPT-3.5 Turbo'],
  ],
  'anthropic': [
    ['claude-3-opus-latest', 'Claude 3 Opus'],
    ['claude-3-sonnet-latest', 'Claude 3 Sonnet'],
    ['claude-3-haiku-latest', 'Claude 3 Haiku'],
    ['claude-3-5-haiku-latest', 'Claude 3.5 Haiku'],
    ['claude-3-5-sonnet-latest', 'Claude 3.5 Sonnet'],
  ],
  'gemini': [
    ['gemini-1.5-pro', 'Gemini 1.5 Pro'],
    ['gemini-1.5-flash-8b', 'Gemini 1.5 Flash 8B'],
    ['gemini-2.0-flash', 'Gemini 2.0 Flash'],
    ['gemini-2.0-flash-lite', 'Gemini 2.0 Flash Lite'],
    ['gemini-2.5-flash-preview_0520', 'Gemini 2.5 Flash Preview 0520'],
  ],
  'ollama': [
    ['llama3', 'Llama 3'],
    ['gemma3', 'Gemma 3'],
    ['mistral', 'Mistral'],
  ],
  'azureopenai': [
    ['custom', 'Custom'],
  ],
};

enum LLMProvider {
  gemini('Gemini'),
  openai('OpenAI'),
  anthropic('Anthropic'),
  ollama('Ollama'),
  azureopenai('Azure OpenAI');

  const LLMProvider(this.displayName);

  final String displayName;

  List<LLMModel> get models {
    final avl = AVAILABLE_LLMS[this.name.toLowerCase()];
    if (avl == null) return [];
    List<LLMModel> models = [];
    for (final x in avl) {
      models.add(LLMModel(x[0], x[1], this));
    }
    return models;
  }

  ModelController get modelController {
    switch (this) {
      case LLMProvider.ollama:
        return OllamaModelController.instance;
      case LLMProvider.gemini:
        return GeminiModelController.instance;
      case LLMProvider.azureopenai:
        return AzureOpenAIModelController.instance;
      case LLMProvider.openai:
        return OpenAIModelController.instance;
      case LLMProvider.anthropic:
        return AnthropicModelController.instance;
    }
  }

  static LLMProvider fromJSON(Map json) {
    return LLMProvider.fromName(json['llm_provider']);
  }

  static Map toJSON(LLMProvider p) {
    return {'llm_provider': p.name};
  }

  static LLMProvider? fromJSONNullable(Map? json) {
    if (json == null) return null;
    return LLMProvider.fromName(json['llm_provider']);
  }

  static Map? toJSONNullable(LLMProvider? p) {
    if (p == null) return null;
    return {'llm_provider': p.name};
  }

  LLMModel getLLMByIdentifier(String identifier) {
    final m = this.models.where((e) => e.identifier == identifier).firstOrNull;
    if (m == null) {
      throw Exception('MODEL DOES NOT EXIST');
    }
    return m;
  }

  static LLMProvider fromName(String name) {
    return LLMProvider.values.firstWhere(
      (model) => model.name == name,
      orElse: () => throw ArgumentError('INVALID LLM PROVIDER: $name'),
    );
  }
}
