import 'package:flutter/material.dart';
import 'package:greendrive/screens/new_post_screen.dart';
import 'package:greendrive/screens/post_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../model/post.dart';
import '../../services/social_service.dart';
import '../../providers/user_provider.dart';
import 'package:intl/intl.dart';


class FeedSection extends StatefulWidget {
  const FeedSection({super.key});

  @override
  State<FeedSection> createState() => _FeedSectionState();
}

class _FeedSectionState extends State<FeedSection> {
  final _socialService = SocialService();
  bool _isLoading = true;
  List<Post> _posts = [];
  String _error = '';
  String? _selectedCategory;

  // Lista de categorías para filtrar
  final List<String> _categories = [
    'All', 
    'General', 
    'Consejos', 
    'Experiencias', 
    'Noticias', 
    'Modelos de VE', 
    'Carga', 
    'Autonomía', 
    'Incentivos',
    'Tecnología'
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      List<Post> posts;
      if (_selectedCategory == null || _selectedCategory == 'All') {
        posts = await _socialService.getPosts();
      } else {
        posts = await _socialService.getPostsByCategory(_selectedCategory!);
      }
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load forum posts: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Community'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showCategoryFilterDialog();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: Column(
          children: [
            // Mostrar la categoría seleccionada como un chip
            if (_selectedCategory != null && _selectedCategory != 'All')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Chip(
                      label: Text(_selectedCategory!),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                        _loadPosts();
                      },
                    ),
                  ],
                ),
              ),
            
            // Lista de posts
            Expanded(
              child: _posts.isEmpty
                ? const Center(child: Text('No forum posts available.'))
                : ListView.builder(
                    itemCount: _posts.length,
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(post: post),
                              ),
                            ).then((_) => _loadPosts());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Perfil del usuario
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          child: Icon(Icons.person),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              post.username,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              DateFormat('MMM d, yyyy · HH:mm').format(post.date),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                    // Chip de categoría
                                    Chip(
                                      label: Text(
                                        post.category,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: _getCategoryColor(post.category),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  post.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.comment_outlined,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${post.commentCount} comments',
                                          style: const TextStyle(color: Colors.blue),
                                        ),
                                      ],
                                    ),
                                    if (userProvider.userId == post.userId)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Post'),
                                              content: const Text('Are you sure you want to delete this post?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (confirm == true) {
                                            try {
                                              await _socialService.deletePost(post.id);
                                              _loadPosts();
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed to delete post: $e')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: userProvider.isLoggedIn
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewPostScreen(userId: userProvider.userId ?? 0),
                  ),
                ).then((_) => _loadPosts());
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  // Función para mostrar el diálogo de filtro de categorías
  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Category'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _categories.map((String category) {
                  return ListTile(
                    title: Text(category),
                    selected: _selectedCategory == category,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category == 'All' ? null : category;
                      });
                      Navigator.pop(context);
                      _loadPosts();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Asigna colores a las categorías
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Consejos':
        return Colors.blue.shade100;
      case 'Experiencias':
        return Colors.green.shade100;
      case 'Noticias':
        return Colors.orange.shade100;
      case 'Modelos de VE':
        return Colors.purple.shade100;
      case 'Carga':
        return Colors.red.shade100;
      case 'Autonomía':
        return Colors.teal.shade100;
      case 'Incentivos':
        return Colors.amber.shade100;
      case 'Tecnología':
        return Colors.indigo.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}