import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../shared/widgets/frosted_card.dart';

/// 语音输入组件
///
/// 支持实时语音转文字，插入到日记编辑器。
class VoiceInputWidget extends ConsumerStatefulWidget {
  final ValueChanged<String> onTextReceived;
  final String? initialText;

  const VoiceInputWidget({
    super.key,
    required this.onTextReceived,
    this.initialText,
  });

  @override
  ConsumerState<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends ConsumerState<VoiceInputWidget> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _currentText = '';
  bool _isAvailable = false;
  String _selectedLocale = 'zh_CN';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _isAvailable = await _speech.initialize(
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
      onStatus: (status) {
        if (status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _startListening() async {
    if (!_isAvailable) {
      _showError('语音识别不可用，请检查设备设置');
      return;
    }

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _currentText = result.recognizedWords;
          });
        }
      },
      localeId: _selectedLocale,
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
      partialResults: true,
    );

    if (mounted) {
      setState(() {
        _isListening = true;
        _currentText = widget.initialText ?? '';
      });
    }
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      if (_currentText.isNotEmpty) {
        widget.onTextReceived(_currentText);
      }
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: _isListening ? Colors.red : Colors.white70,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isListening ? '正在聆听...' : '点击开始语音输入',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // 语言选择
              DropdownButton<String>(
                value: _selectedLocale,
                dropdownColor: const Color(0xFF1A1A3E),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'zh_CN', child: Text('中文', style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(value: 'en_US', child: Text('English', style: TextStyle(color: Colors.white70))),
                ],
                onChanged: _isListening
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedLocale = value);
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 识别结果预览
          if (_currentText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // 控制按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleListening,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? '停止' : '开始'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_currentText.isNotEmpty && !_isListening) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.onTextReceived(_currentText);
                      setState(() => _currentText = '');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('插入'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
