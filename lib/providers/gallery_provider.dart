import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_work.dart';

const _kGalleryKey = 'user_works_gallery';

class GalleryState {
  final List<UserWork> works;
  final bool isLoading;
  final String? error;

  const GalleryState({
    this.works = const [],
    this.isLoading = false,
    this.error,
  });
}

class GalleryNotifier extends StateNotifier<GalleryState> {
  GalleryNotifier() : super(const GalleryState()) {
    _loadWorks();
  }

  Future<void> _loadWorks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kGalleryKey);

      if (jsonStr == null) {
        state = const GalleryState(works: [], isLoading: false);
        return;
      }

      final jsonList = jsonDecode(jsonStr) as List;
      final works = jsonList
          .map((item) => UserWork.fromMap(item as Map<String, dynamic>))
          .toList();

      state = GalleryState(works: works, isLoading: false);
    } catch (e) {
      state = GalleryState(
        works: [],
        isLoading: false,
        error: 'エラー: $e',
      );
    }
  }

  Future<void> addWork({
    required String challengeId,
    required String challengeTitle,
    required String blockCode,
    required String resultImage,
    required String difficulty,
  }) async {
    try {
      final newWork = UserWork(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        challengeId: challengeId,
        challengeTitle: challengeTitle,
        blockCode: blockCode,
        resultImage: resultImage,
        createdAt: DateTime.now(),
        difficulty: difficulty,
      );

      final updatedWorks = [newWork, ...state.works];
      await _saveWorks(updatedWorks);
      state = GalleryState(works: updatedWorks);
    } catch (e) {
      state = GalleryState(
        works: state.works,
        error: 'エラー: $e',
      );
    }
  }

  Future<void> toggleStar(String workId) async {
    try {
      final updatedWorks = state.works.map((work) {
        if (work.id == workId) {
          return UserWork(
            id: work.id,
            challengeId: work.challengeId,
            challengeTitle: work.challengeTitle,
            blockCode: work.blockCode,
            resultImage: work.resultImage,
            createdAt: work.createdAt,
            difficulty: work.difficulty,
            isStarred: !work.isStarred,
          );
        }
        return work;
      }).toList();

      await _saveWorks(updatedWorks);
      state = GalleryState(works: updatedWorks);
    } catch (e) {
      state = GalleryState(
        works: state.works,
        error: 'エラー: $e',
      );
    }
  }

  Future<void> deleteWork(String workId) async {
    try {
      final updatedWorks = state.works
          .where((work) => work.id != workId)
          .toList();

      await _saveWorks(updatedWorks);
      state = GalleryState(works: updatedWorks);
    } catch (e) {
      state = GalleryState(
        works: state.works,
        error: 'エラー: $e',
      );
    }
  }

  Future<void> _saveWorks(List<UserWork> works) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = works.map((w) => w.toMap()).toList();
    await prefs.setString(_kGalleryKey, jsonEncode(jsonList));
  }
}

final galleryProvider =
    StateNotifierProvider<GalleryNotifier, GalleryState>((ref) {
  return GalleryNotifier();
});
