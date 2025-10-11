import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';
import 'qr_screen.dart';
import 'settings_screen.dart';

/// リスト表示画面（MVP超軽量版）
///
/// お買い物アイテムのリスト表示・チェック機能
class ListScreen extends ConsumerStatefulWidget {
  final String familyId;
  final String listId;

  const ListScreen({
    super.key,
    required this.familyId,
    required this.listId,
  });

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final dataService = ref.read(dataServiceProvider);
      final lists = await dataService.getLists(widget.familyId);

      final currentList = lists.firstWhere(
        (list) => list['id'] == widget.listId,
        orElse: () => {'shopping_items': []},
      );

      setState(() {
        _items = List<Map<String, dynamic>>.from(
          currentList['shopping_items'] ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('読み込みエラー: $e')),
        );
      }
    }
  }

  Future<void> _toggleItem(String itemId, bool completed) async {
    try {
      final dataService = ref.read(dataServiceProvider);
      await dataService.toggleItem(itemId, !completed);
      await _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新エラー: $e')),
        );
      }
    }
  }

  Future<void> _addItem() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('商品追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '商品名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      try {
        final dataService = ref.read(dataServiceProvider);
        await dataService.createItem(widget.listId, controller.text);
        await _loadItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('追加エラー: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お買い物リスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRScreen(familyId: widget.familyId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    '商品がありません\n+ボタンで追加してください',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final completed = item['completed'] as bool? ?? false;

                    return ListTile(
                      title: Text(
                        item['name'] as String,
                        style: TextStyle(
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: Checkbox(
                        value: completed,
                        onChanged: (_) => _toggleItem(
                          item['id'] as String,
                          completed,
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
