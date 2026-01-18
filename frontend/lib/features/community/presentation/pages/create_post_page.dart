import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/community_bloc.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/injection.dart';

/// Create post page
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentController = TextEditingController();
  String _postType = 'update';
  String _visibility = 'public';
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _submit() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    context.read<CommunityBloc>().add(
          CommunityCreatePost(
            content: _contentController.text.trim(),
            postType: _postType,
            visibility: _visibility,
            tags: _tags.isNotEmpty ? _tags : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CommunityBloc>(),
      child: BlocConsumer<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state is CommunityPostCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post created successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          } else if (state is CommunityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Create Post'),
              actions: [
                TextButton(
                  onPressed: state is CommunitySubmitting ? null : _submit,
                  child: state is CommunitySubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Post type
                  Text(
                    'Post Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'update', label: Text('Update')),
                      ButtonSegment(value: 'discussion', label: Text('Discussion')),
                      ButtonSegment(value: 'poll', label: Text('Poll')),
                    ],
                    selected: {_postType},
                    onSelectionChanged: (value) {
                      setState(() => _postType = value.first);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Visibility
                  Text(
                    'Visibility',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'public',
                        label: Text('Public'),
                        icon: Icon(Icons.public),
                      ),
                      ButtonSegment(
                        value: 'followers',
                        label: Text('Followers'),
                        icon: Icon(Icons.people),
                      ),
                    ],
                    selected: {_visibility},
                    onSelectionChanged: (value) {
                      setState(() => _visibility = value.first);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Tags
                  Text(
                    'Tags',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Add a tag',
                            prefixText: '#',
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTag,
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map((tag) => Chip(
                                label: Text('#$tag'),
                                onDeleted: () => _removeTag(tag),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Guidelines
                  Card(
                    color: AppColors.primary.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Be respectful and constructive. Focus on civic issues and community matters.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
