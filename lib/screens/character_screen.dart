import 'package:flutter/material.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: CharacterProfileMap API in shared_core has different structure
    // final charState = ref.watch(characterProvider);
    // const character = charState.character;

    // if (charState.isLoading || character == null) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

    // Placeholder while character system is being integrated
    return const Scaffold(
      body: Center(child: Text('キャラクターシステム: 準備中')),
    );

    // final charDef = kAvailableCharacters.firstWhere(
    //   (c) => c.id == character.characterId,
    //   orElse: () => kAvailableCharacters.first,
    // );
    //
    // return Scaffold(
    //   appBar: AppBar(title: const Text('キャラクター')),
    //   body: Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         Icon(Icons.pets, size: 64, color: Colors.grey[400]),
    //         const SizedBox(height: 16),
    //         Text(
    //           '近日公開予定です',
    //           style: TextStyle(fontSize: 16, color: Colors.grey[600]),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
