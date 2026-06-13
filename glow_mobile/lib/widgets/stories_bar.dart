import 'package:flutter/material.dart';
import '../services/story_service.dart';
import '../screens/story_viewer_screen.dart';
import '../screens/create_story_screen.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  @override
  void initState() {
    super.initState();
    StoryService.instance.refreshFeed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<int>(
      valueListenable: StoryService.revision,
      builder: (context, _, __) {
        final groups = StoryService.instance.friendGroupedFeed;
        final myStories = StoryService.instance.myStories;
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: groups.length + 1, // +1 for "Your Story"
            itemBuilder: (ctx, i) {
              if (i == 0) return _buildAddStory(ctx, scheme, myStories);
              final group = groups[i - 1];
              return _buildStoryCircle(ctx, group, scheme);
            },
          ),
        );
      },
    );
  }

  Widget _buildAddStory(BuildContext context, ColorScheme scheme, List<Map<String, dynamic>> myStories) {
    final hasStories = myStories.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  if (hasStories) {
                    // Show own stories
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StoryViewerScreen(
                          stories: myStories,
                          initialIndex: 0,
                          username: 'Your story',
                        ),
                      ),
                    );
                  } else {
                    // Open camera to create new story
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CreateStoryScreen()),
                    );
                  }
                },
                onLongPress: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CreateStoryScreen()),
                  );
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStories
                        ? const LinearGradient(
                            colors: [Color(0xFFFF8FC8), Color(0xFFE0569A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasStories ? null : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    border: hasStories
                        ? null
                        : Border.all(
                            color: scheme.outline.withValues(alpha: 0.2),
                            width: 2,
                          ),
                  ),
                  child: hasStories
                      ? Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.surface,
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: const Color(0xFFFF8FC8),
                              size: 30,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person_outline_rounded,
                          color: scheme.onSurfaceVariant,
                          size: 30,
                        ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: () {
                    // ALWAYS open create new story
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CreateStoryScreen()),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface,
                    ),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF8FC8), Color(0xFFE0569A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 6),
            Text(
              'Your story',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
  }

  Widget _buildStoryCircle(
    BuildContext context,
    Map<String, dynamic> group,
    ColorScheme scheme,
  ) {
    final username = group['username']?.toString() ?? '';
    final displayName =
        username.length > 8 ? username.substring(0, 8) : username;
    final initial =
        username.isNotEmpty ? username[0].toUpperCase() : '?';
    final stories = (group['stories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final bool viewed = stories.isEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StoryViewerScreen(
              stories: stories,
              initialIndex: 0,
              username: username,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: viewed
                    ? LinearGradient(
                        colors: [
                          Colors.grey.shade400,
                          Colors.grey.shade300,
                        ],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFFF8FC8), Color(0xFFE0569A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      const Color(0xFFFF8FC8).withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF8FC8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
