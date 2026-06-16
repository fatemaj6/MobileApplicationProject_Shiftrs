import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../controllers/ai_assistant_controller.dart';

class AiAssistantScreen extends StatefulWidget {
  // for bottom-nav routing + active colour (purple for family/AI).
  final bool isFamily;

  //used in the assistant card copy
  final String? patientName;

  const AiAssistantScreen({super.key, this.isFamily = false, this.patientName});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late final AiAssistantController _ai;

  static const List<String> _quickQuestions = [
    'Drug interactions?',
    'Summarize week',
    'Adherence tips',
    'Health trends',
  ];

  //illustrative feed shown in the empty state. These are seed cards
  final List<_AiInsight> _insights = const [
    _AiInsight(
      kind: _InsightKind.alert,
      title: 'Drug Interaction Alert',
      body:
          'Aspirin and Amlodipine may interact. Both can affect blood pressure. '
          'Monitor for signs of dizziness or lightheadedness. Consult Dr. Tan '
          'if symptoms occur.',
      timeAgo: '3 hours ago',
    ),
    _AiInsight(
      kind: _InsightKind.positive,
      title: 'Positive Adherence Trend',
      body:
          'Medication adherence has improved by 15% this week compared to last '
          'week. Current rate: 94%. Great progress!',
      timeAgo: '5 hours ago',
    ),
    _AiInsight(
      kind: _InsightKind.summary,
      title: 'Daily Care Summary',
      body:
          'Today: All morning medications given on time. Blood pressure recorded '
          '(135/82). Light exercise completed. Patient reported good mood and '
          'appetite.',
      timeAgo: '8 hours ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ai = AiAssistantController(patientName: widget.patientName);
    _ai.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _ai.removeListener(_onControllerChanged);
    _ai.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _inputFocus.unfocus();
    _ai.send(text);
  }

  void _onQuickQuestion(String label) {
    const prompts = <String, String>{
      'Drug interactions?':
          'Are there any drug interactions I should be aware of?',
      'Summarize week': "Summarise this week's care notes.",
      'Adherence tips': 'How can we improve medication adherence?',
      'Health trends': 'What health trends are worth noting?',
    };
    _ai.send(prompts[label] ?? label);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _ai.hasConversation
                  ? _buildConversation()
                  : _buildLanding(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // header ------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant', style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(
                  'Intelligent care insights',
                  style: AppTextStyles.secondary,
                ),
              ],
            ),
          ),
          if (_ai.hasConversation)
            IconButton(
              tooltip: 'New chat',
              onPressed: _ai.isLoading ? null : _ai.reset,
              icon: const Icon(
                Icons.add_comment_outlined,
                color: AppColors.purple,
              ),
            ),
        ],
      ),
    );
  }

  // empty state -------------------------------------

  Widget _buildLanding() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssistantCard(),
            const SizedBox(height: 24),
            _buildQuickQuestions(),
            const SizedBox(height: 24),
            _buildInsights(),
            const SizedBox(height: 16),
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantCard() {
    final name = widget.patientName?.trim();
    final whose = (name == null || name.isEmpty)
        ? "your loved one's"
        : "$name's";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.purpleLight, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.22),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Care Assistant',
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Powered by AI',
                      style: AppTextStyles.bodySm.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Get personalized insights about $whose care, medication '
            'interactions, and health trends.',
            style: AppTextStyles.bodyMd.copyWith(
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Questions', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _quickChip(_quickQuestions[0])),
            const SizedBox(width: 12),
            Expanded(child: _quickChip(_quickQuestions[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _quickChip(_quickQuestions[2])),
            const SizedBox(width: 12),
            Expanded(child: _quickChip(_quickQuestions[3])),
          ],
        ),
      ],
    );
  }

  Widget _quickChip(String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _onQuickQuestion(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Insights', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        for (final insight in _insights) ...[
          _InsightCard(insight: insight),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySm.copyWith(
            color: const Color(0xFF3730A3),
            height: 1.5,
          ),
          children: const [
            TextSpan(
              text: 'Note: ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text:
                  'AI insights are for informational purposes only and should '
                  'not replace professional medical advice. Always consult '
                  'healthcare providers for medical decisions.',
            ),
          ],
        ),
      ),
    );
  }

  // conversation ------------------------------------------------------

  Widget _buildConversation() {
    final items = _ai.messages;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      itemCount: items.length + (_ai.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) return _loadingBubble();
        return _messageBubble(items[index]);
      },
    );
  }

  Widget _messageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.purple : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.bodyMd.copyWith(
            color: isUser ? Colors.white : AppColors.foreground,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _loadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 10),
            Text('Thinking…', style: AppTextStyles.secondarySm),
          ],
        ),
      ),
    );
  }

  // input bar ---------------------------------------------------------

  Widget _buildInputBar() {
    final radius = BorderRadius.circular(28);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: 'Ask about medications, trends...',
                hintStyle: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: const BorderSide(
                    color: AppColors.purple,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _ai.isLoading ? AppColors.purpleLight : AppColors.purple,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _ai.isLoading ? null : _send,
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: _ai.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // bottom nav --------------------------------------------------------

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 4,
      selectedItemColor: AppColors.purple,
      unselectedItemColor: AppColors.textMuted,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        if (index == 4) return; // already on AI
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(
              context,
              widget.isFamily ? AppRoutes.familyHome : AppRoutes.caregiverHome,
              (route) => false,
            );
            break;
          case 1:
            Navigator.pushNamed(
              context,
              widget.isFamily
                  ? AppRoutes.familyMedications
                  : AppRoutes.medications,
            );
            break;
          case 2:
            Navigator.pushNamed(
              context,
              widget.isFamily
                  ? AppRoutes.familyAppointments
                  : AppRoutes.appointments,
            );
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.careNotes);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.link_outlined),
          activeIcon: Icon(Icons.link),
          label: 'Meds',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'Appts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note_alt_outlined),
          activeIcon: Icon(Icons.note_alt),
          label: 'Notes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_outlined),
          activeIcon: Icon(Icons.auto_awesome),
          label: 'AI',
        ),
      ],
    );
  }
}

enum _InsightKind { alert, positive, summary }

class _AiInsight {
  final _InsightKind kind;
  final String title;
  final String body;
  final String timeAgo;

  const _AiInsight({
    required this.kind,
    required this.title,
    required this.body,
    required this.timeAgo,
  });
}

class _InsightCard extends StatelessWidget {
  final _AiInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;

    switch (insight.kind) {
      case _InsightKind.alert:
        bg = AppColors.alertAmberBg;
        borderColor = AppColors.alertAmberBorder;
        iconColor = AppColors.alertAmber;
        icon = Icons.warning_amber_rounded;
        break;
      case _InsightKind.positive:
        bg = AppColors.givenBg;
        borderColor = AppColors.givenBorder;
        iconColor = AppColors.given;
        icon = Icons.trending_up;
        break;
      case _InsightKind.summary:
        bg = AppColors.checkupBg;
        borderColor = const Color(0xFFBFDBFE);
        iconColor = AppColors.checkupText;
        icon = Icons.description_outlined;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.body,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            insight.timeAgo,
            style: AppTextStyles.secondarySm.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
