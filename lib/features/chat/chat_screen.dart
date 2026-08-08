import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Messaging pages. The overview is a contact list under a brand hero header;
/// tapping a contact opens the conversation.
///
/// The conversation used to paint a saturated primary/secondary/tertiary
/// gradient behind white text. That only worked in the old light-only theme —
/// under the dark scheme those three roles are all *light*, so the bubbles
/// went white-on-white. Bubbles now use the role pairs Material defines for
/// exactly this (primary/onPrimary outbound, a container inbound), so they are
/// legible in every variant.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  static const _contacts = <_Contact>[
    _Contact('Adison Lubin', 'Do you want to grab coffee this weekend?',
        'Just now',
        online: true),
    _Contact('James Vetrovs', '👍 Let me know if you need anything', '3:24 pm'),
    _Contact('Ashlynn Mango', "I'll be a little late, hope that's okay",
        'Yesterday'),
    _Contact('Tatiana Vaccaro', 'Just saw this and thought of you! 😂',
        'Yesterday',
        online: true),
    _Contact('Nolan Siphron', 'Hey, are you free later?', 'Sep 12'),
  ];

  static const _stories = ['Adison', 'Charlie', 'James', 'Kari'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const _HeroHeader(stories: _stories),
          Expanded(
            child: ListView.separated(
              // Bottom padding clears the shell's floating nav bar.
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.screenPadding,
                DesignTokens.space5,
                DesignTokens.screenPadding,
                DesignTokens.navBarClearance,
              ),
              itemCount: _contacts.length,
              separatorBuilder: (_, _) => const Divider(height: 28),
              itemBuilder: (context, i) {
                final c = _contacts[i];
                return _ContactRow(
                  contact: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ConversationScreen(name: c.name),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Overview header -------------------------------------------------------

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.stories});

  final List<String> stories;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(DesignTokens.screenPadding, 60,
          DesignTokens.screenPadding, DesignTokens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: palette.onHero.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: palette.onHero.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          color: palette.onHeroVariant, size: 20),
                      const SizedBox(width: DesignTokens.space2),
                      Expanded(
                        child: TextField(
                          style: context.text.bodyMedium
                              ?.copyWith(color: palette.onHero),
                          cursorColor: palette.onHero,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'ค้นหาแชท',
                            hintStyle: context.text.bodyMedium
                                ?.copyWith(color: palette.onHeroVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space6),
          Text(
            "Let's Stay\nConnected",
            style: context.text.displayMedium
                ?.copyWith(color: palette.onHero, height: 1.1),
          ),
          const SizedBox(height: DesignTokens.space6),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const _AddStory(),
                for (final name in stories) ...[
                  const SizedBox(width: DesignTokens.space4),
                  _Story(name: name),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStory extends StatelessWidget {
  const _AddStory();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: palette.onHero.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(Icons.add, color: palette.onHero, size: 28),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text('Add',
            style: context.text.labelMedium?.copyWith(color: palette.onHero)),
      ],
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = context.colors;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.onHero.withValues(alpha: 0.6),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHighest,
            ),
            child: Icon(Icons.person_rounded,
                color: scheme.onSurfaceVariant, size: 30),
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(name,
            style: context.text.labelMedium?.copyWith(color: palette.onHero)),
      ],
    );
  }
}

// --- Contact rows ----------------------------------------------------------

class _Contact {
  const _Contact(this.name, this.preview, this.time, {this.online = false});

  final String name;
  final String preview;
  final String time;
  final bool online;
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact, required this.onTap});

  final _Contact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.space1),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerHighest,
                  ),
                  child: Icon(Icons.person_rounded,
                      color: scheme.onSurfaceVariant, size: 26),
                ),
                if (contact.online)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: palette.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: DesignTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Expanded, not spaceBetween: a long contact name has
                      // to ellipsize rather than push the timestamp off the
                      // right edge.
                      Expanded(
                        child: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space2),
                      Text(
                        contact.time,
                        style: context.text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    contact.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Conversation ----------------------------------------------------------

class _Message {
  const _Message(this.text, this.time, {required this.inbound});

  final String text;
  final String time;
  final bool inbound;
}

class _ConversationScreen extends StatefulWidget {
  const _ConversationScreen({required this.name});

  final String name;

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  final _messages = <_Message>[
    const _Message("It's called Winds of Tomorrow", '10:08 PM', inbound: true),
    const _Message(
      "It's so good! 🤩 The story is super engaging, and the characters are so "
      "well-written. I ended up binge-watching half the season last night.",
      '10:09 PM',
      inbound: true,
    ),
    const _Message('That sounds amazing!', '10:10 PM', inbound: false),
    const _Message('Where can I watch it?', '10:10 PM', inbound: false),
    const _Message("It's on Netflix", '10:13 PM', inbound: true),
    const _Message('I can share my login so you can check it out 🤫', '10:14 PM',
        inbound: true),
    const _Message("That's so nice of you! ❤️", '10:23 PM', inbound: false),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text, 'Now', inbound: false));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ConversationAppBar(name: widget.name),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space4, DesignTokens.space2, DesignTokens.space4, DesignTokens.space4),
              itemCount: _messages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _Bubble(message: _messages[i]),
            ),
          ),
          _Composer(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _ConversationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ConversationAppBar({required this.name});

  final String name;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHighest,
            ),
            child: Icon(Icons.person_rounded,
                color: scheme.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          tooltip: 'โทร',
          icon: const Icon(Icons.call_outlined),
        ),
        IconButton(
          onPressed: () {},
          tooltip: 'โปรไฟล์',
          icon: const Icon(Icons.person_outline),
        ),
        const SizedBox(width: DesignTokens.space2),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final inbound = message.inbound;

    final fill = inbound ? scheme.surfaceContainerHigh : scheme.primary;
    final ink = inbound ? scheme.onSurface : scheme.onPrimary;

    return Align(
      alignment: inbound ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(inbound ? 4 : 18),
            bottomRight: Radius.circular(inbound ? 18 : 4),
          ),
          border: inbound ? Border.all(color: scheme.outlineVariant) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: context.text.bodyMedium
                  ?.copyWith(color: ink, height: 1.4),
            ),
            const SizedBox(height: 2),
            Text(
              message.time,
              style: context.text.labelSmall
                  ?.copyWith(color: ink.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.screenPadding, 12, DesignTokens.screenPadding, 28),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(hintText: 'พิมพ์ข้อความ...'),
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          IconButton.filled(
            onPressed: onSend,
            tooltip: 'ส่ง',
            iconSize: 20,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(DesignTokens.minTouchTarget),
            ),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
