import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/certificate.dart';
import '../providers/certificate_provider.dart';
import '../services/share_service.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'package:intl/intl.dart';

class CertificatesGalleryScreen extends ConsumerStatefulWidget {
  const CertificatesGalleryScreen({super.key});

  @override
  ConsumerState<CertificatesGalleryScreen> createState() =>
      _CertificatesGalleryScreenState();
}

class _CertificatesGalleryScreenState
    extends ConsumerState<CertificatesGalleryScreen> {
  late String _selectedLevel;
  late String _sortBy; // 'date' or 'stage'

  @override
  void initState() {
    super.initState();
    _selectedLevel = '全て';
    _sortBy = 'date';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎓 マイ証明書'),
        elevation: 0,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Builder(builder: (context) {
        final certificates = ref.watch(certificatesProvider);
          // フィルタリング
          var filtered = certificates;
          if (_selectedLevel != '全て') {
            filtered =
                filtered.where((c) => c.level == _selectedLevel).toList();
          }

          // ソート
          if (_sortBy == 'date') {
            filtered.sort((a, b) => b.completedAt.compareTo(a.completedAt));
          } else {
            filtered.sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
          }

          return Column(
            children: [
              // フィルタ＆ソートバー
              _buildFilterBar(filtered.length),

              // ギャラリー
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'まだ認定証がありません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ステージをクリアすると認定証が獲得できます！',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildCertificateCard(
                        filtered[index],
                        ref,
                      );
                    },
                  ),
                ),
            ],
          );
      }),
    );
  }

  Widget _buildFilterBar(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // レベルフィルター
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['全て', '初級', '中級', '上級'].map((level) {
                final isSelected = _selectedLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (value) {
                      setState(() => _selectedLevel = level);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: kPrimaryColor.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: isSelected ? kPrimaryColor : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // ソート＆カウント
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '合計: $count 件',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('最新順')),
                  DropdownMenuItem(value: 'stage', child: Text('ステージ順')),
                ]
                    .map((item) => DropdownMenuItem(
                          value: item.value,
                          child: item.child,
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(Certificate certificate, WidgetRef ref) {
    final color = _getLevelColor(certificate.level);
    final stars = '⭐' * certificate.stars;
    final dateStr = DateFormat('yyyy/MM/dd').format(certificate.completedAt);

    return GestureDetector(
      onTap: () {
        _showCertificateDetail(certificate, ref);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // レベルバッジ
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                certificate.level,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // ステージ番号＆名前
            Column(
              children: [
                Text(
                  'Stage ${certificate.stageNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  certificate.stageName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // 星
            Text(
              stars,
              style: const TextStyle(fontSize: 16),
            ),

            // 修了者名
            Text(
              certificate.childName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),

            // 修了日
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCertificateDetail(Certificate certificate, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CertificateDetailSheet(certificate: certificate, ref: ref);
      },
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case '初級':
        return const Color(0xFF2196F3);
      case '中級':
        return const Color(0xFF9C27B0);
      case '上級':
        return const Color(0xFFFFA500);
      default:
        return Colors.grey;
    }
  }
}

class _CertificateDetailSheet extends ConsumerWidget {
  final Certificate certificate;
  final WidgetRef ref;

  const _CertificateDetailSheet({
    required this.certificate,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getLevelColor(certificate.level);
    final stars = '⭐' * certificate.stars;
    final dateStr = DateFormat('yyyy年MM月dd日').format(certificate.completedAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ハンドル
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // 認定証プレビュー（簡略版）
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.05),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '修了証',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ステージ${certificate.stageNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      certificate.stageName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      stars,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      certificate.childName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr + ' 修了',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 共有ボタン
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ShareService.shareToTwitter(certificate);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Twitter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DA1F2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ShareService.shareGeneric(certificate);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('シェア'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 削除ボタン
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    _showDeleteConfirm(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('削除'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('認定証を削除'),
        content: const Text('この認定証を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(certificatesProvider.notifier).removeCertificate(
                    certificate.id,
                  );
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case '初級':
        return const Color(0xFF2196F3);
      case '中級':
        return const Color(0xFF9C27B0);
      case '上級':
        return const Color(0xFFFFA500);
      default:
        return Colors.grey;
    }
  }
}
