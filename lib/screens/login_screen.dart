import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../main.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _nameError;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // バリデーション
  // ─────────────────────────────────────────────────────────────

  bool _validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  bool _validateLoginForm() {
    setState(() {
      _emailError = _emailController.text.isEmpty
          ? 'メールアドレスを入力してください'
          : !_validateEmail(_emailController.text)
              ? '有効なメールアドレスを入力してください'
              : null;
      _passwordError = _passwordController.text.isEmpty
          ? 'パスワードを入力してください'
          : !_validatePassword(_passwordController.text)
              ? 'パスワードは6文字以上である必要があります'
              : null;
    });
    return _emailError == null && _passwordError == null;
  }

  bool _validateSignUpForm() {
    setState(() {
      _emailError = _emailController.text.isEmpty
          ? 'メールアドレスを入力してください'
          : !_validateEmail(_emailController.text)
              ? '有効なメールアドレスを入力してください'
              : null;
      _passwordError = _passwordController.text.isEmpty
          ? 'パスワードを入力してください'
          : !_validatePassword(_passwordController.text)
              ? 'パスワードは6文字以上である必要があります'
              : null;
      _nameError = _nameController.text.isEmpty ? 'お名前を入力してください' : null;
    });
    return _emailError == null && _passwordError == null && _nameError == null;
  }

  // ─────────────────────────────────────────────────────────────
  // ログイン/サインアップ処理
  // ─────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_validateLoginForm()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(signInProvider(
        SignInParams(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      ).future);

      if (mounted) {
        // ログイン成功後、MainNavigatorに遷移
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainNavigator(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('ログインに失敗しました', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (!_validateSignUpForm()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(signUpProvider(
        SignUpParams(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        ),
      ).future);

      if (mounted) {
        // サインアップ成功後、MainNavigatorに遷移
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainNavigator(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('アカウント作成に失敗しました', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI ビルド
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('プログラミング学習アプリ'),
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'ログイン'),
              Tab(text: 'アカウント作成'),
            ],
            labelColor: kPrimaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kPrimaryColor,
          ),
        ),
        body: TabBarView(
          children: [
            // ─────────────────────────────────────────────
            // ログインタブ
            // ─────────────────────────────────────────────
            _buildLoginTab(),

            // ─────────────────────────────────────────────
            // サインアップタブ
            // ─────────────────────────────────────────────
            _buildSignUpTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),

          // ━━━━━ ロゴ ━━━━━
          Center(
            child: Text(
              '💻',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'ようこそ！',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ━━━━━ メールアドレス入力 ━━━━━
          TextField(
            controller: _emailController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: 'メールアドレス',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: _emailError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
          ),
          const SizedBox(height: 16),

          // ━━━━━ パスワード入力 ━━━━━
          TextField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'パスワード',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              errorText: _passwordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
          const SizedBox(height: 24),

          // ━━━━━ ログインボタン ━━━━━
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: kPrimaryColor,
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'ログイン',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // ━━━━━ 説明テキスト ━━━━━
          Center(
            child: Text(
              'アカウントをお持ちでないですか？上のタブから作成できます',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),

          // ━━━━━ ロゴ ━━━━━
          Center(
            child: Text(
              '🚀',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'さあ始めよう！',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ━━━━━ お名前入力 ━━━━━
          TextField(
            controller: _nameController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: 'お名前',
              prefixIcon: const Icon(Icons.person_outlined),
              errorText: _nameError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) {
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
          ),
          const SizedBox(height: 16),

          // ━━━━━ メールアドレス入力 ━━━━━
          TextField(
            controller: _emailController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: 'メールアドレス',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: _emailError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
          ),
          const SizedBox(height: 16),

          // ━━━━━ パスワード入力 ━━━━━
          TextField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'パスワード（6文字以上）',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              errorText: _passwordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
          const SizedBox(height: 24),

          // ━━━━━ アカウント作成ボタン ━━━━━
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSignUp,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: kPrimaryColor,
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'アカウント作成',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // ━━━━━ 説明テキスト ━━━━━
          Center(
            child: Text(
              'すでにアカウントをお持ちですか？上のタブからログインしてください',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
