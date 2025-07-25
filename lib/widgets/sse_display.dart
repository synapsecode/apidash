import 'dart:convert';
import 'package:apidash/providers/collection_providers.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SSEDisplay extends ConsumerStatefulWidget {
  final String sseOutput;
  const SSEDisplay({
    super.key,
    required this.sseOutput,
  });

  @override
  ConsumerState<SSEDisplay> createState() => _SSEDisplayState();
}

class _SSEDisplayState extends ConsumerState<SSEDisplay> {
  @override
  Widget build(BuildContext context) {
    final requestModel = ref.read(selectedRequestModelProvider);
    final aiRequestModel = requestModel?.aiRequestModel;
    final isAIOutput = (aiRequestModel != null);

    final theme = Theme.of(context);

    List<dynamic> sse;

    try {
      sse = jsonDecode(widget.sseOutput);
    } catch (e) {
      return Text(
        'Invalid SSE output',
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
      );
    }

    if (isAIOutput) {
      String out = "";
      for (String x in sse) {
        x = x.substring(6);
        out += aiRequestModel.model.provider.modelController
                .streamOutputFormatter(jsonDecode(x)) ??
            "<?>";
      }
      return SingleChildScrollView(
        child: Text(out),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: (sse).reversed.where((e) => e != '').map<Widget>((chunk) {
          Map<String, dynamic>? parsedJson;
          try {
            parsedJson = jsonDecode(chunk);
          } catch (_) {}

          return Card(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : const Color.fromARGB(255, 14, 20, 27),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: parsedJson != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: parsedJson.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}: ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kColorGQL,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  style: kCodeStyle,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : Text(
                      chunk.toString().trim(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
