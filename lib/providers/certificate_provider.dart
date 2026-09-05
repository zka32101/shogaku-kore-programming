import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/certificate.dart';

const String _certificatesKey = 'certificates_list';

/// 認定証リストプロバイダー
final certificatesProvider =
    StateNotifierProvider<CertificateNotifier, List<Certificate>>((ref) {
  return CertificateNotifier();
});

/// 認定証管理ノーティファイアー
class CertificateNotifier extends StateNotifier<List<Certificate>> {
  CertificateNotifier() : super([]) {
    _loadCertificates();
  }

  /// SharedPreferences から認定証を読み込み
  Future<void> _loadCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_certificatesKey) ?? [];

    final certificates = jsonList.map((json) {
      return Certificate.fromJson(jsonDecode(json));
    }).toList();

    state = certificates;
  }

  /// state（メモリ上の最新リスト）を単一の真実源として prefs へ保存する。
  /// prefs を都度読み直さないことで、複数メソッドがほぼ同時に呼ばれた際の
  /// read-modify-write 競合による更新消失を防ぐ。
  Future<void> _persist(List<Certificate> next) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = next.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_certificatesKey, jsonList);
    state = next;
  }

  /// 新しい認定証を追加
  Future<void> addCertificate(Certificate certificate) async {
    await _persist([...state, certificate]);
  }

  /// 認定証を削除
  Future<void> removeCertificate(String certificateId) async {
    await _persist(state.where((c) => c.id != certificateId).toList());
  }

  /// ファイルパスを更新（生成後）
  Future<void> updateCertificateFilePath(
      String certificateId, String filePath) async {
    await _persist(state.map((c) {
      if (c.id == certificateId) {
        return c.copyWith(filePath: filePath);
      }
      return c;
    }).toList());
  }
}

/// 認定証総数プロバイダー
final certificateCountProvider = Provider<int>((ref) {
  final certs = ref.watch(certificatesProvider);
  return certs.length;
});

/// レベル別認定証カウントプロバイダー
final certificateCountByLevelProvider =
    Provider.family<int, String>((ref, level) {
  final certs = ref.watch(certificatesProvider);
  return certs.where((c) => c.level == level).length;
});

/// 最新の認定証プロバイダー
final latestCertificateProvider = Provider<Certificate?>((ref) {
  final certs = ref.watch(certificatesProvider);
  if (certs.isEmpty) return null;
  final sorted = List<Certificate>.from(certs);
  sorted.sort((a, b) => b.completedAt.compareTo(a.completedAt));
  return sorted.first;
});
