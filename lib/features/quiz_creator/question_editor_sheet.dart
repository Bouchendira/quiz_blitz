import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/question_model.dart';
 
class QuestionEditorSheet extends StatefulWidget {
  /// Pass an existing question to edit it; null = create new.
  final QuestionModel? existing;
 
  const QuestionEditorSheet({super.key, this.existing});
 
  @override
  State<QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}
 
class _QuestionEditorSheetState extends State<QuestionEditorSheet> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls =
      List.generate(4, (_) => TextEditingController());
  late int _correctIndex;
  late int _timeLimit;
  late int _points;
 
  // Answer color + icon pairs (matching the game screen)
  static const _answerColors = [
    Color(0xFFE53935), // Red
    Color(0xFF1565C0), // Blue
    Color(0xFF2E7D32), // Green
    Color(0xFFF57F17), // Orange
  ];
  static const _answerIcons = ['▲', '◆', '●', '■'];
  static const _answerLabels = ['A', 'B', 'C', 'D'];
  static const _pointOptions = [500, 1000, 2000];
 
  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _questionCtrl.text = q?.text ?? '';
    for (int i = 0; i < 4; i++) {
      _optionCtrls[i].text =
          (q != null && i < q.options.length) ? q.options[i] : '';
    }
    _correctIndex = q?.correctIndex ?? 0;
    _timeLimit = q?.timeLimitSeconds ?? 20;
    _points = q?.points ?? 1000;
  }
 
  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
 
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12122A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
 
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        widget.existing == null
                            ? 'New Question'
                            : 'Edit Question',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
 
                  // ── Question text ──────────────────────────────────────
                  _Label('Question'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _questionCtrl,
                    maxLines: 3,
                    maxLength: 200,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 15),
                    decoration: _textInputDeco(
                      'Type your question here...',
                      Icons.help_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 20),
 
                  // ── Answer options ─────────────────────────────────────
                  Row(
                    children: [
                      _Label('Answers'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Tap ✓ to mark correct',
                          style: GoogleFonts.poppins(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
 
                  ...List.generate(4, (i) => _AnswerOptionField(
                    index: i,
                    controller: _optionCtrls[i],
                    isCorrect: _correctIndex == i,
                    color: _answerColors[i],
                    icon: _answerIcons[i],
                    label: _answerLabels[i],
                    onMarkCorrect: () =>
                        setState(() => _correctIndex = i),
                  )),
                  const SizedBox(height: 24),
 
                  // ── Time limit ─────────────────────────────────────────
                  _Label('Time Limit'),
                  const SizedBox(height: 12),
                  _TimeLimitSlider(
                    value: _timeLimit,
                    onChanged: (v) => setState(() => _timeLimit = v),
                  ),
                  const SizedBox(height: 24),
 
                  // ── Points ─────────────────────────────────────────────
                  _Label('Points'),
                  const SizedBox(height: 12),
                  _PointsSelector(
                    selected: _points,
                    options: _pointOptions,
                    onSelect: (p) => setState(() => _points = p),
                  ),
                  const SizedBox(height: 28),
 
                  // ── Save button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor:
                            const Color(0xFF6C63FF).withOpacity(0.5),
                      ),
                      child: Text(
                        widget.existing == null
                            ? 'Add Question +'
                            : 'Save Changes',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
 
  // ── Helpers ───────────────────────────────────────────────────────────────
 
  InputDecoration _textInputDeco(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
        counterStyle: const TextStyle(color: Colors.white24, fontSize: 11),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      );
 
  void _save() {
    final questionText = _questionCtrl.text.trim();
    if (questionText.isEmpty) {
      _snack('Please type a question ✏️');
      return;
    }
 
    final options = _optionCtrls.map((c) => c.text.trim()).toList();
    final emptyIndex =
        options.indexWhere((o) => o.isEmpty);
    if (emptyIndex != -1) {
      _snack('Option ${_answerLabels[emptyIndex]} is empty!');
      return;
    }
 
    // Check for duplicate options
    if (options.toSet().length < options.length) {
      _snack('All answer options must be different!');
      return;
    }
 
    Navigator.pop(
      context,
      QuestionModel(
        id: widget.existing?.id ?? const Uuid().v4(),
        quizId: widget.existing?.quizId ?? '',
        orderIndex: widget.existing?.orderIndex ?? 0,
        text: questionText,
        options: options,
        correctIndex: _correctIndex,
        timeLimitSeconds: _timeLimit,
        points: _points,
      ),
    );
  }
 
  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
 
// ─── Answer option input row ──────────────────────────────────────────────────
 
class _AnswerOptionField extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final bool isCorrect;
  final Color color;
  final String icon;
  final String label;
  final VoidCallback onMarkCorrect;
 
  const _AnswerOptionField({
    required this.index,
    required this.controller,
    required this.isCorrect,
    required this.color,
    required this.icon,
    required this.label,
    required this.onMarkCorrect,
  });
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Correct-answer toggle button
          GestureDetector(
            onTap: onMarkCorrect,
            child: AnimatedContainer(
              duration: 200.ms,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect ? Colors.greenAccent : Colors.white12,
                border: Border.all(
                  color:
                      isCorrect ? Colors.greenAccent : Colors.white24,
                  width: 2,
                ),
                boxShadow: isCorrect
                    ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.4),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  isCorrect ? Icons.check : Icons.check,
                  size: 18,
                  color: isCorrect ? Colors.black : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
 
          // Color indicator + answer shape icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
 
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Option $label',
                hintStyle: GoogleFonts.poppins(
                    color: Colors.white24, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                filled: true,
                fillColor: isCorrect
                    ? Colors.greenAccent.withOpacity(0.08)
                    : Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isCorrect ? Colors.greenAccent : color,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// ─── Time limit slider ────────────────────────────────────────────────────────
 
class _TimeLimitSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
 
  const _TimeLimitSlider({required this.value, required this.onChanged});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text('⏱️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Time limit',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 13)),
              ]),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$value seconds',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF6C63FF),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 10,
              max: 60,
              divisions: 10,
              onChanged: (v) => onChanged(v.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10s',
                  style: GoogleFonts.poppins(
                      color: Colors.white24, fontSize: 11)),
              Text('60s',
                  style: GoogleFonts.poppins(
                      color: Colors.white24, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ─── Points selector ──────────────────────────────────────────────────────────
 
class _PointsSelector extends StatelessWidget {
  final int selected;
  final List<int> options;
  final ValueChanged<int> onSelect;
 
  const _PointsSelector({
    required this.selected,
    required this.options,
    required this.onSelect,
  });
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((pts) {
        final isSelected = pts == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(pts),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : Colors.white12,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 10,
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    '⭐',
                    style: TextStyle(
                        fontSize: pts == 2000 ? 22 : pts == 1000 ? 18 : 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pts',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'pts',
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
 
// ─── Shared label widget ──────────────────────────────────────────────────────
 
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
 
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}