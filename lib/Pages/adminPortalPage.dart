import 'package:cap/Pages/ProfilePage.dart';
import 'package:cap/Pages/RecipeDetailPage.dart';
import 'package:cap/firebase/services/admin_service.dart';
import 'package:cap/ui_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cap/models/user_model.dart';
import 'package:cap/models/recipe_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPortalPage extends StatelessWidget {
  const AdminPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminService(),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Admin Portal',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            bottom: TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: [
                Tab(
                    icon: Icon(Icons.restaurant_menu_outlined),
                    text: 'Recipes'),
                Tab(
                    icon: Icon(Icons.verified_user_outlined),
                    text: 'Promotions'),
                Tab(icon: Icon(Icons.group_outlined), text: 'Users'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _RecipeSubmissionsTab(),
              _ChefPromotionsTab(),
              _RegisteredUsersTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// Recipe Submissions Tab
class _RecipeSubmissionsTab extends StatelessWidget {
  const _RecipeSubmissionsTab();

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: adminService.getPendingRecipes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading recipes'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Failed to load recipes\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }
        

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final recipe = Recipe.fromFirestore(doc);

            return _RecipeSubmissionCard(
              recipe: recipe,
              onApprove: () => adminService.approveRecipe(doc.id),
              onReject: () => adminService.rejectRecipe(doc.id),
            );
          },
        );
      },
    );
  }
}

Widget _buildChip(String text, Color color) {
  return Chip(
    label:
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
    backgroundColor: color.withOpacity(0.9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

class _RecipeSubmissionCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RecipeSubmissionCard({
    required this.recipe,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.deepPurple[800],
                    fontWeight: FontWeight.w800)),

            Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Row(
    children: [
      buildMetaChip(
        icon: Icons.timer_outlined,
        label: "${recipe.preparationTime} MIN",
        color: Colors.blue.shade400,
      ),
      const SizedBox(width: 10),
      buildMetaChip(
        icon: DifficultyUtils.getDifficultyIcon(
            recipe.difficulty.toString().split('.').last),
        label: recipe.difficulty.toString().split('.').last.capitalize(),
        color: DifficultyUtils.getDifficultyColor(
            recipe.difficulty.toString().split('.').last),
      ),
      const SizedBox(width: 10),
      buildMetaChip(
        icon: Icons.category_outlined,
        label: recipe.category.title,
        color: Colors.green.shade400,
      ),
    ],
  ),
),

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                recipe.dishImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[100],
                  child: const Icon(Icons.photo_camera_back, size: 40),
                ),
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(recipe.description,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.4)),
            ),

            // YouTube URL
            if (recipe.videoUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  child: Text('Watch Video Tutorial',
                      style: TextStyle(
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  onTap: () => launchUrl(Uri.parse(recipe.videoUrl!)),
                ),
              ),

            // Ingredients Section
            _buildDetailSection(
              title: 'Ingredients',
              items: recipe.ingredients,
            ),

            // Steps Section
            _buildDetailSection(
              title: 'Cooking Steps',
              items: recipe.methodSteps,
              isNumbered: true,
            ),

            // Chef Information
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(recipe.chef.id)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const ListTile(
                    leading: Icon(Icons.error),
                    title: Text('Chef not found'),
                  );
                }
                final chef = AppUser.fromFirestore(snapshot.data!);
                return ListTile(
                  onTap: () {
                    // Add this
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: recipe.chef.id),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundImage: chef.profileImage != null
                        ? NetworkImage(chef.profileImage!)
                        : null,
                    child: chef.profileImage == null
                        ? Text(chef.name.isNotEmpty ? chef.name[0] : '?')
                        : null,
                  ),
                  title: Text(chef.name),
                  subtitle: Text(chef.email),
                );
              },
            ),

            // Approval Buttons
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12)),
                    onPressed: onApprove,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[700]!),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12)),
                    onPressed: onReject,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildMetaChip({
  required IconData icon,
  required String label,
  required Color color,
}) {
  return MetaChip(
    icon: icon,
    text: label,
    color: color,
    horizontalPadding: 8,
    verticalPadding: 8,
    fontSize: 12,
    iconSize: 14,
  );
}
 
}

Widget _buildDetailSection({
  required String title,
  required List<String> items,
  bool isNumbered = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      ...items.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isNumbered ? '${entry.key + 1}.' : '•'),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.value)),
            ],
          ),
        );
      }),
    ],
  );
}

// Chef Promotions Tab
class _ChefPromotionsTab extends StatelessWidget {
  const _ChefPromotionsTab();

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: adminService.getPromotionRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading promotions'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _PromotionRequestCard(
              requestId: doc.id,
              userId: data['userId'],
              userEmail: data['userEmail'] ?? 'No email provided',
              bio: data['bio'] ?? 'No bio submitted',
              experience: data['yearsExperience'] ?? 0,
              certifications: List<String>.from(data['certifications'] ?? []),
              youtubeChannel: data['youtubeChannel'],
              linkedIn: data['linkedIn'],
              profileImage: data['profileImage'],
              onApprove: () =>
                  adminService.approvePromotion(doc.id, data['userId']),
              onReject: () => adminService.rejectPromotion(doc.id),
            );
          },
        );
      },
    );
  }
}

class _PromotionRequestCard extends StatelessWidget {
  final String requestId;
  final String userId;
  final String? userEmail;
  final String bio;
  final int experience;
  final List<String> certifications;
  final String? youtubeChannel;
  final String? linkedIn;
  final String? profileImage;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PromotionRequestCard({
    required this.requestId,
    required this.userId,
    this.userEmail,
    required this.bio,
    required this.experience,
    required this.certifications,
    required this.youtubeChannel,
    required this.linkedIn,
    required this.profileImage,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profileImage != null)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.blueGrey[100]!, width: 3)),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: NetworkImage(profileImage!),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.email_outlined, userEmail ?? 'No email'),
            _buildDetailRow(
                Icons.work_outline, 'Experience: $experience years'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(bio,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                      height: 1.4)),
            ),
            if (youtubeChannel != null && youtubeChannel!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  child: Text('YouTube Channel',
                      style: TextStyle(
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  onTap: () => launchUrl(Uri.parse(youtubeChannel!)),
                ),
              ),
            if (linkedIn != null && linkedIn!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  child: Text('LinkedIn Profile',
                      style: TextStyle(
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  onTap: () => launchUrl(Uri.parse(linkedIn!)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Certifications:',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600)),
            ),
            Wrap(
              spacing: 8,
              children: certifications
                  .map((cert) => Chip(
                        label: Text(cert, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.blue[50],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ))
                  .toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12)),
                    onPressed: onApprove,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[700]!),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12)),
                    onPressed: onReject,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }
}

// Registered Users Tab
class _RegisteredUsersTab extends StatelessWidget {
  const _RegisteredUsersTab();

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: adminService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading users'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final user = AppUser.fromFirestore(doc);

            return _UserCard(user: user);
          },
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(userId: user.id),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue[50],
          backgroundImage: user.profileImage != null
              ? NetworkImage(user.profileImage!)
              : null,
          child: user.profileImage == null
              ? Icon(Icons.person_outline, size: 28, color: Colors.blue[700])
              : null,
        ),
        title: Text(user.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(user.role.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(user.createdAt),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.deepPurple;
      case 'chef':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }
  String _formatDate(DateTime? date) {
  return date != null
      ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
      : 'Unknown Date';
}
}