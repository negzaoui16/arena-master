import 'package:flutter/material.dart';
import 'package:arena/core/models/competition_model.dart';
import 'package:arena/core/models/auth_models.dart';
import 'package:arena/core/services/api_service.dart';
import 'package:arena/core/theme/app_theme.dart';
import 'admin_participants_screen.dart';

class HackathonDetailScreen extends StatefulWidget {
  final String competitionId;

  const HackathonDetailScreen({super.key, required this.competitionId});

  @override
  State<HackathonDetailScreen> createState() => _HackathonDetailScreenState();
}

class _HackathonDetailScreenState extends State<HackathonDetailScreen> {
  final _api = ApiService();
  Competition? _competition;
  bool _loading = true;
  String? _error;
  bool _joining = false;
  bool _joined = false;
  AuthUser? _user;

  // --- Anti-cheat vars ---
  final _githubController = TextEditingController();
  bool _isSubmittingGithub = false;
  String? _antiCheatScore;
  String? _antiCheatMessage;
  String _participantStatus = 'JOINED'; // JOINED, SUBMITTED, DISQUALIFIED
  String? _antiCheatError;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _load();
  }

  Future<void> _loadUser() async {
    try {
      final u = await _api.getMe();
      if (mounted) setState(() => _user = u);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await _api.getCompetitionById(widget.competitionId);

      // Also check if the user is already a participant
      bool alreadyJoined = false;
      try {
        alreadyJoined = await _api.checkMyParticipation(widget.competitionId);
        // If participation returned, extract status info
        if (alreadyJoined) {
          // Fetch participation details to get status
          try {
            final token = await _api.getParticipationDetails(widget.competitionId);
            if (token != null) {
              _participantStatus = token['status'] ?? 'JOINED';
              if (token['githubUrl'] != null) {
                _githubController.text = token['githubUrl'];
              }
              if (token['antiCheatScore'] != null) {
                _antiCheatScore = '${token['antiCheatScore']}%';
              }
            }
          } catch (_) {}
        }
      } catch (_) {
        // Ignore error when checking participation
      }

      if (mounted) setState(() {
        _competition = c;
        _joined = alreadyJoined;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (e.statusCode == 401 && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
        return;
      }
      if (mounted) setState(() {
        _error = e.displayMessage;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Connection error';
        _loading = false;
      });
    }
  }

  Future<void> _join() async {
    if (_competition == null || !_competition!.canJoin) return;
    setState(() => _joining = true);
    try {
      await _api.joinCompetition(widget.competitionId);
      if (mounted) setState(() {
        _joined = true;
        _joining = false;
      });
    } on ApiError catch (e) {
      if (mounted) setState(() => _joining = false);
      if (e.statusCode == 409) {
        setState(() => _joined = true);
        return;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (mounted) setState(() => _joining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B1121), Color(0xFF0F141C), Color(0xFF0B0E14)],
                )
              : null,
          color: isDark ? null : AppColors.backgroundLight,
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 56, color: Colors.grey.shade500),
                            const SizedBox(height: 16),
                            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh, size: 20),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _competition == null
                      ? const SizedBox.shrink()
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      icon: Icon(Icons.arrow_back, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'Hackathon',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 48),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _chip(_competition!.difficultyDisplay, _diffColor()),
                                        if (_competition!.specialty != null) ...[
                                          const SizedBox(width: 8),
                                          _chip(_competition!.specialty!, AppColors.primary),
                                        ],
                                        const Spacer(),
                                        Text(
                                          _competition!.statusDisplay,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _competition!.title,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : AppColors.textLightPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _competition!.description,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _infoRow(Icons.calendar_today, '${_formatDate(_competition!.startDate)} – ${_formatDate(_competition!.endDate)}'),
                                    if (_competition!.rewardPool > 0)
                                      _infoRow(Icons.emoji_events, 'Prize pool: \$${_competition!.rewardPool.toStringAsFixed(0)}'),
                                    if (_competition!.maxParticipants != null)
                                      _infoRow(Icons.people_outline, 'Max ${_competition!.maxParticipants} participants'),
                                    if (_competition!.participantsCount > 0)
                                      _infoRow(Icons.people, '${_competition!.participantsCount} joined'),
                                    const SizedBox(height: 32),
                                    // Hide join/submit for the creator (admin who made this hackathon)
                                    if (_competition!.creator?.id != _user?.id) ...[
                                      _buildJoinOrStatusButton(),
                                      if (_joined) ...[
                                        const SizedBox(height: 32),
                                        _buildAntiCheatSection(isDark),
                                      ],
                                    ],
                                    // Admin: view participants button
                                    if (_user?.role == 'ADMIN') ...[
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => AdminParticipantsScreen(
                                                  competitionId: widget.competitionId,
                                                  competitionTitle: _competition!.title,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.people, color: AppColors.primary),
                                          label: const Text(
                                            'Voir les participants',
                                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.primary),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ),
        ),
    );
  }

  Widget _buildJoinOrStatusButton() {
    // If the user has already joined, show the "Joined" button regardless of the current status
    if (_joined || _competition!.canJoin) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _joined ? null : (_joining ? null : _join),
          icon: _joining
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Icon(_joined ? Icons.check_circle : Icons.add_circle_outline, size: 22),
          label: Text(_joined ? 'Joined' : (_joining ? 'Joining…' : 'Join competition')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          _competition!.statusDisplay,
          style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAntiCheatSection(bool isDark) {
    final isSubmitted = _participantStatus == 'SUBMITTED';
    final isDisqualified = _participantStatus == 'DISQUALIFIED';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisqualified
              ? Colors.red.withAlpha(80)
              : isSubmitted
                  ? Colors.green.withAlpha(80)
                  : AppColors.primary.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDisqualified ? Icons.gpp_bad : Icons.security,
                color: isDisqualified ? Colors.red : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _competition!.antiCheatEnabled
                      ? 'Soumission & Anti-Triche'
                      : 'Soumettre votre travail',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textLightPrimary,
                  ),
                ),
              ),
            ],
          ),

          // ── DISQUALIFIED STATE ──
          if (isDisqualified) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withAlpha(50)),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Disqualifié',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (_antiCheatScore != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Score IA : $_antiCheatScore (seuil : ${_competition!.antiCheatThreshold ?? 70}%)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade300),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Votre code a été détecté comme généré par IA au-delà du seuil autorisé. Vous ne pouvez plus soumettre.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade300, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],

          // ── SUBMITTED STATE ──
          if (isSubmitted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withAlpha(50)),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Travail soumis ✅',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (_antiCheatScore != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Score Anti-Triche : $_antiCheatScore',
                      style: TextStyle(color: Colors.green.shade300),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Votre travail a été soumis avec succès. Bonne chance !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green.shade300, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],

          // ── JOINED STATE (can submit) ──
          if (!isSubmitted && !isDisqualified) ...[
            const SizedBox(height: 8),
            Text(
              _competition!.antiCheatEnabled
                  ? 'Ce hackathon utilise la vérification Anti-Triche IA. Fournissez votre lien GitHub pour soumettre votre travail.'
                  : 'Fournissez le lien GitHub de votre repository pour soumettre votre travail.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _githubController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'https://github.com/votre-compte/votre-repo',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.link, color: Colors.grey),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmittingGithub ? null : _submitGithubLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmittingGithub
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Soumettre le repository', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            if (_antiCheatError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_antiCheatError!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _submitGithubLink() async {
    final url = _githubController.text.trim();
    if (url.isEmpty) {
      setState(() => _antiCheatError = 'Veuillez entrer une URL GitHub valide.');
      return;
    }

    setState(() {
      _isSubmittingGithub = true;
      _antiCheatError = null;
    });

    try {
      final result = await _api.submitGithubLink(widget.competitionId, url);
      final status = result['status'] as String? ?? 'SUBMITTED';
      final message = result['message'] as String? ?? '';
      final score = result['antiCheatScore'];

      if (mounted) {
        setState(() {
          _participantStatus = status;
          _antiCheatMessage = message;
          if (score != null) _antiCheatScore = '${score}%';
          _isSubmittingGithub = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _antiCheatError = e.displayMessage;
          _isSubmittingGithub = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _antiCheatError = 'Erreur lors de la soumission.';
          _isSubmittingGithub = false;
        });
      }
    }
  }

  Color _diffColor() {
    if (_competition == null) return AppColors.primary;
    return _competition!.difficulty.toUpperCase() == 'HARD'
        ? AppColors.accentOrange
        : _competition!.difficulty.toUpperCase() == 'EASY'
            ? Colors.green
            : AppColors.primary;
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade300, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
