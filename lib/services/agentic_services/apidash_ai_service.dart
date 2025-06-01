import 'dart:io';

import 'package:apidash/consts.dart';
import 'package:apidash/models/llm_models/all_models.dart';
import 'package:apidash/models/llm_models/google/gemini_20_flash.dart';
import 'package:apidash/models/llm_models/llm_model.dart';
import 'package:apidash/models/llm_models/openai/azure_openai.dart';
import 'package:apidash/services/agentic_services/agent_blueprint.dart';

typedef LLMAccessDetail = (String provider, String credential);

class APIDashAIService {
  static Future<String?> _call_ollama({
    required String systemPrompt,
    required String input,
  }) async {
    final result =
        await Process.run('curl', ['http://localhost:11434/api/tags']);
    if (result.exitCode != 0) {
      print('OLLAMA_NOT_ACTIVE');
      return null;
    }
    return await LLama3LocalModel().call(
      systemPrompt: systemPrompt,
      userPrompt: input == '' ? '' : '\nProvided Inputs:$input',
      credential: 'NONE',
    );
  }

  static Future<String?> _call_provider({
    required String provider,
    required String apiKey,
    required String systemPrompt,
    required String input,
  }) async {
    switch (provider) {
      // Handling Special Case for AzureOpenAI
      case 'azure_openai':
        final credParts = apiKey.split('|');
        final endpoint = credParts[0];
        final modelname = credParts[1];
        final apiversion = credParts[2];
        final apiK = credParts[3];
        final m = AzureOpenAIModel();
        m.loadConfigurations({
          'azure_endpoint': endpoint,
          'azure_deployment_name': modelname,
          'azure_api_version': apiversion
        });
        return await m.call(
          systemPrompt: systemPrompt,
          userPrompt: input == '' ? '' : '\nProvided Inputs:$input',
          credential: apiK,
        );
      default:
        final m = getLLMModelFromID(provider);
        if (m == null) {
          print('PROVIDER_UNIMPLEMENTED');
          return null;
        }
        return await m.call(
          systemPrompt: systemPrompt,
          userPrompt: input == '' ? '' : '\nProvided Inputs:$input',
          credential: apiKey,
        );
    }
  }

  static Future<String?> _orchestrator(
    APIDashAIAgent agent,
    LLMAccessDetail accessDetail, {
    String? query,
    Map? variables,
  }) async {
    String sP = agent.getSystemPrompt();

    //Perform Templating
    if (variables != null) {
      for (final v in variables.keys) {
        sP = sP.substitutePromptVariable(v, variables[v]);
      }
    }

    //Implement any Rate limiting logic as needed
    if (accessDetail.$1 == 'llama3_local') {
      //Use local ollama implementation
      return await _call_ollama(systemPrompt: sP, input: query ?? '');
    } else {
      //Use LLMProvider implementation
      return await _call_provider(
        provider: accessDetail.$1,
        apiKey: accessDetail.$2,
        systemPrompt: sP,
        input: query ?? '',
      );
    }
  }

  static Future<dynamic> _governor(
    APIDashAIAgent agent,
    LLMAccessDetail accessDetail, {
    String? query,
    Map? variables,
  }) async {
    int RETRY_COUNT = 0;
    List<int> backoffDelays = [200, 400, 800, 1600, 3200];
    do {
      try {
        final res = await _orchestrator(
          agent,
          accessDetail,
          query: query,
          variables: variables,
        );
        if (res != null) {
          if (await agent.validator(res)) {
            return agent.outputFormatter(res);
          }
        }
      } catch (e) {
        "APIDashAIService::Governor: Exception Occured: $e";
      }
      // Exponential Backoff
      if (RETRY_COUNT < backoffDelays.length) {
        await Future.delayed(Duration(
          milliseconds: backoffDelays[RETRY_COUNT],
        ));
      }
      RETRY_COUNT += 1;
      print(
        "Retrying AgentCall for (${agent.agentName}): ATTEMPT: $RETRY_COUNT",
      );
    } while (RETRY_COUNT < 5);
    return null;
  }

  static Future<dynamic> callAgent(
    APIDashAIAgent agent,
    LLMAccessDetail accessDetail, {
    String? query,
    Map? variables,
  }) async {
    return await _governor(
      agent,
      accessDetail,
      query: query,
      variables: variables,
    );
  }
}
