import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/question_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/providers.dart';
import 'question_editor_sheet.dart';
 
const _kEmojis = [
  '🎯', '🚀', '🧠', '🎮', '⚡', '🌟', '🔥', '🎨',
  '🦄', '🏆', '🎲', '🌈', '🐉', '🎸', '🦊', '🌍',
];
 
class QuizCreatorScreen extends ConsumerStatefulWidget {
  const QuizCreatorScreen({super.key});
 
  @override
  ConsumerState<QuizCreatorScreen> createState() => _QuizCreatorScreenState();
}
 
class _QuizCreatorScreenState extends ConsumerState<QuizCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _coverEmoji = '🎯';
  final List<QuestionModel> _questions = [];
  bool _saving = false;
  
  @override
  void initState() {
    super.initState();
    // Check if user is a guest and redirect them
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGuestAccess();
    });
  }
  
  void _checkGuestAccess() {
    final profileAsync = ref.read(currentProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null && profile.isGuest) {
        // Guest users cannot create quizzes
        context.go('/join');
      }
    });
  }
 
  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
 
  // ── Build ─────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Cover emoji picker
            _SectionLabel(label: 'Cover'),
            const SizedBox(height: 10),
            _EmojiPicker(
              selected: _coverEmoji,
              onSelect: (e) => setState(() => _coverEmoji = e),
            ),
            const SizedBox(height: 24),
 
            // Title field
            _SectionLabel(label: 'Quiz Title'),
            const SizedBox(height: 10),
            _buildTitleField(),
            const SizedBox(height: 16),
 
            // Description field
            _SectionLabel(label: 'Description (optional)'),
            const SizedBox(height: 10),
            _buildDescField(),
            const SizedBox(height: 32),
 
            // Questions header
            Row(
              children: [
                _SectionLabel(
                    label: 'Questions (${_questions.length})'),
                const Spacer(),
                _AddQuestionButton(onTap: () => _openQuestionEditor(null)),
              ],
            ),
            const SizedBox(height: 12),
 
            // Questions list (reorderable)
            if (_questions.isEmpty) _EmptyQuestionsHint(),
 
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _questions.removeAt(oldIndex);
                  _questions.insert(newIndex, item);
                });
              },
              itemBuilder: (_, i) => _QuestionTile(
                key: ValueKey(_questions[i].id ?? i.toString()),
                question: _questions[i],
                index: i,
                onEdit: () => _openQuestionEditor(i),
                onDelete: () => setState(() => _questions.removeAt(i)),
              ),
            ),
 
            const SizedBox(height: 80), // space for FAB
          ],
        ),
      ),
 
      // Floating "Add Question" button
      floatingActionButton: _questions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openQuestionEditor(null),
              backgroundColor: const Color(0xFF6C63FF),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add Question',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
 
  // ── AppBar ────────────────────────────────────────────────────────────────
 
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => _confirmDiscard(),
      ),
      title: Text(
        'Create Quiz',
        style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _saveQuiz,
                  child: Text(
                    'Publish',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6C63FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
 
  // ── Form fields ───────────────────────────────────────────────────────────
 
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleCtrl,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
      maxLength: 80,
      decoration: _inputDeco(
        hint: 'e.g. World Geography Quiz',
        icon: Icons.title_rounded,
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Please add a title' : null,
    );
  }
 
  Widget _buildDescField() {
    return TextFormField(
      controller: _descCtrl,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      maxLines: 2,
      maxLength: 200,
      decoration: _inputDeco(
        hint: 'What\'s this quiz about?',
        icon: Icons.notes_rounded,
      ),
    );
  }
 
  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      counterStyle: const TextStyle(color: Colors.white24),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
 
  // ── Question editor ───────────────────────────────────────────────────────
 
  Future<void> _openQuestionEditor(int? editIndex) async {
    final existing = editIndex != null ? _questions[editIndex] : null;
 
    final result = await showModalBottomSheet<QuestionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestionEditorSheet(existing: existing),
    );
 
    if (result != null) {
      setState(() {
        if (editIndex != null) {
          _questions[editIndex] = result;
        } else {
          _questions.add(result);
        }
      });
    }
  }
 
  // ── Save ──────────────────────────────────────────────────────────────────
 
  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      _snack('Add at least one question to publish! 📝');
      return;
    }
 
    setState(() => _saving = true);
 
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Not logged in');
 
      final quiz = QuizModel(
        ownerId: user.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        coverEmoji: _coverEmoji,
        questions: _questions.asMap().entries.map((e) {
          return e.value.copyWith(
            quizId: '', // will be set inside createQuiz()
            orderIndex: e.key,
          );
        }).toList(),
      );
 
      await ref.read(quizRepositoryProvider).createQuiz(quiz);
 
      if (mounted) {
        _snack('Quiz published! 🎉');
        context.go('/home');
      }
    } catch (e) {
      _snack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
 
  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
 
  void _confirmDiscard() {
    if (_titleCtrl.text.isEmpty && _questions.isEmpty) {
      context.pop();
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3E),
        title: Text('Discard quiz?',
            style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('Your unsaved changes will be lost.',
            style: GoogleFonts.poppins(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep editing',
                style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text('Discard',
                style: GoogleFonts.poppins(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
 
// ─── Sub-widgets for QuizCreatorScreen ───────────────────────────────────────
 
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
 
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
 
class _EmojiPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
 
  const _EmojiPicker({required this.selected, required this.onSelect});
 
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _kEmojis.length,
        itemBuilder: (_, i) {
          final emoji = _kEmojis[i];
          final isSelected = emoji == selected;
          return GestureDetector(
            onTap: () => onSelect(emoji),
            child: AnimatedContainer(
              duration: 200.ms,
              width: 54,
              height: 54,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
          );
        },
      ),
    );
  }
}
 
class _AddQuestionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddQuestionButton({required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      icon: const Icon(Icons.add_circle_outline,
          color: Color(0xFF6C63FF), size: 18),
      label: Text('Add',
          style: GoogleFonts.poppins(
              color: const Color(0xFF6C63FF),
              fontWeight: FontWeight.w600,
              fontSize: 13)),
    );
  }
}
 
class _EmptyQuestionsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.08),
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Text('📋', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'No questions yet',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add" above to create your first question',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
 
class _QuestionTile extends StatelessWidget {
  final QuestionModel question;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
 
  const _QuestionTile({
    super.key,
    required this.question,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });
 
  // Answer option colors: red, blue, green, orange
  static const _colors = [
    Color(0xFFE53935),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFF57F17),
  ];
 
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6C63FF),
              radius: 16,
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              question.text,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${question.timeLimitSeconds}s  •  ${question.points} pts',
              style:
                  GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white54, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
                // Drag handle
                const Icon(Icons.drag_handle, color: Colors.white24),
              ],
            ),
          ),
 
          // Answer options preview
          Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 6,
              childAspectRatio: 4,
              children: question.options.asMap().entries.map((e) {
                final isCorrect = e.key == question.correctIndex;
                return Container(
                  decoration: BoxDecoration(
                    color: _colors[e.key].withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: isCorrect
                        ? Border.all(color: Colors.greenAccent, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      if (isCorrect)
                        const Icon(Icons.check_circle,
                            color: Colors.greenAccent, size: 12)
                      else
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _colors[e.key],
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.value,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn()
        .slideX(begin: 0.05, end: 0);
  }
}