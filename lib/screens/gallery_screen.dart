import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gallery_provider.dart';
import '../models/user_work.dart';
import '../services/haptic_service.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  bool _showStarredOnly = false;

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryProvider);
    final filteredWorks = _showStarredOnly
        ? galleryState.works.where((w) => w.isStarred).toList()
        : galleryState.works;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 作品ギャラリー'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(_showStarredOnly ? Icons.star : Icons.star_border),
            onPressed: () => setState(() => _showStarredOnly = !_showStarredOnly),
            tooltip: 'お気に入りのみ表示',
          ),
        ],
      ),
      body: filteredWorks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🖼️ 作品がまだありません',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showStarredOnly
                        ? 'お気に入りの作品がまだありません'
                        : 'ブロック操作を完了すると作品が保存されます',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: filteredWorks.length,
              itemBuilder: (context, index) {
                final work = filteredWorks[index];
                return _buildWorkCard(context, work, ref);
              },
            ),
    );
  }

  Widget _buildWorkCard(
    BuildContext context,
    UserWork work,
    WidgetRef ref,
  ) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(work.challengeTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 作品サムネイル
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: work.resultImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              Uri.parse(work.resultImage).data!.contentAsBytes(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_not_supported),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '難易度: ${work.difficulty}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '作成日: ${work.createdAt.year}年${work.createdAt.month}月${work.createdAt.day}日',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: work.resultImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.memory(
                          Uri.parse(work.resultImage)
                              .data!
                              .contentAsBytes(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported, size: 40),
                      ),
              ),
            ),
            // 情報セクション
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    work.challengeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        work.difficulty,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticService.lightImpact();
                          ref
                              .read(galleryProvider.notifier)
                              .toggleStar(work.id);
                        },
                        child: Icon(
                          work.isStarred ? Icons.star : Icons.star_border,
                          size: 16,
                          color: work.isStarred ? Colors.orange : Colors.grey,
                        ),
                      ),
                    ],
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
