import 'dart:ui';
import 'package:flutter/material.dart';

/// Messaging pages — the `overview_chat_and_ai_chat` reference. The
/// "overview" is a contact list with a mesh-gradient header and stories
/// row; tapping a contact opens the conversation view (glassy inbound
/// bubbles, dark outbound bubbles) over a matching gradient.
///
/// Kept presentational with a local message list; wiring the composer to
/// the AI orchestrator would be the "ai chat" half's natural next step.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  static const _contacts = <_Contact>[
    _Contact('Adison Lubin', 'Do you want to grab coffee this weekend?', 'Just now', online: true),
    _Contact('James Vetrovs', '👍 Let me know if you need anything', '3:24 pm'),
    _Contact('Ashlynn Mango', "I'll be a little late, hope that's okay", 'Yesterday'),
    _Contact('Tatiana Vaccaro', 'Just saw this and thought of you! 😂', 'Yesterday', online: true),
    _Contact('Nolan Siphron', 'Hey, are you free later?', 'Sep 12'),
  ];

  static const _stories = ['Adison', 'Charlie', 'James', 'Kari'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const _MeshHeader(stories: _stories),
          Expanded(
            child: ListView.separated(
              // Bottom padding clears the shell's floating nav bar.
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
              itemCount: _contacts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemBuilder: (context, i) {
                final c = _contacts[i];
                return _ContactRow(
                  contact: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => _ConversationScreen(name: c.name)),
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

const _meshGradient = RadialGradient(
  center: Alignment.topLeft,
  radius: 1.4,
  colors: [Color(0xFFA0D8E6), Color(0xFFC5A9E3), Color(0xFF6B7280)],
  stops: [0.0, 0.55, 1.0],
);

class _MeshHeader extends StatelessWidget {
  const _MeshHeader({required this.stories});
  final List<String> stories;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: _meshGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Let's Stay\nConnected",
            style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const _AddStory(),
                for (final name in stories) ...[
                  const SizedBox(width: 16),
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
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2, style: BorderStyle.solid),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFFACC15), Color(0xFFC026D3)],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2A2A2A)),
                child: const Icon(Icons.person_rounded, color: Colors.white54, size: 26),
              ),
              if (contact.online)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(contact.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(contact.time, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  contact.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
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
    const _Message('I can share my login so you can check it out 🤫', '10:14 PM', inbound: true),
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
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.4,
                  colors: [Color(0xFFA0D8E6), Color(0xFFC5A9E3), Color(0xFF6B7280)],
                  stops: [0.0, 0.55, 1.0],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _ConversationHeader(name: widget.name),
                  Expanded(
                    child: ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _Bubble(message: _messages[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Composer(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white.withValues(alpha: 0.85), size: 20),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.1),
            ),
          ),
          _CircleButton(icon: Icons.call, onTap: () {}),
          const SizedBox(width: 8),
          _CircleButton(icon: Icons.person_outline, onTap: () {}),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Colors.white, size: 20)),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final inbound = message.inbound;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: inbound ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(inbound ? 4 : 18),
          bottomRight: Radius.circular(inbound ? 18 : 4),
        ),
        border: inbound ? Border.all(color: Colors.white.withValues(alpha: 0.15)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
          const SizedBox(height: 2),
          Text(message.time, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
        ],
      ),
    );

    // Inbound bubbles get a real backdrop blur for the glass effect.
    final child = inbound
        ? ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: bubble),
          )
        : bubble;

    return Align(alignment: inbound ? Alignment.centerLeft : Alignment.centerRight, child: child);
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Your Message...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            child: InkWell(
              onTap: onSend,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
