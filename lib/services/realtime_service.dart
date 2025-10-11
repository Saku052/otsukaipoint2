import 'package:supabase_flutter/supabase_flutter.dart';

/// リアルタイムサービス（MVP超軽量版）
///
/// お買い物リストのリアルタイム同期機能を提供
class RealtimeService {
  final _client = Supabase.instance.client;
  final Map<String, RealtimeChannel> _channels = {};

  /// リストのアイテム変更を監視
  void subscribeToList(String listId, Function(Map<String, dynamic>) onUpdate) {
    try {
      // 既存チャンネルがあれば停止
      if (_channels.containsKey('list_$listId')) {
        unsubscribe(listId);
      }

      // 新しいチャンネル作成
      final channel = _client
          .channel('list_$listId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shopping_items',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'shopping_list_id',
              value: listId,
            ),
            callback: (payload) {
              print('アイテム変更: ${payload.eventType}');
              onUpdate({
                'eventType': payload.eventType.toString(),
                'new': payload.newRecord,
                'old': payload.oldRecord,
              });
            },
          )
          .subscribe();

      _channels['list_$listId'] = channel;
      print('リアルタイム開始: $listId');
    } catch (e) {
      print('リアルタイムエラー: $e');
      rethrow;
    }
  }

  /// 購読停止
  void unsubscribe(String listId) {
    try {
      final channel = _channels['list_$listId'];
      if (channel != null) {
        _client.removeChannel(channel);
        _channels.remove('list_$listId');
        print('リアルタイム停止: $listId');
      }
    } catch (e) {
      print('停止エラー: $e');
    }
  }

  /// 全チャンネルクリーンアップ
  void dispose() {
    try {
      for (var channel in _channels.values) {
        _client.removeChannel(channel);
      }
      _channels.clear();
      print('リアルタイム全停止');
    } catch (e) {
      print('クリーンアップエラー: $e');
    }
  }

  /// アクティブなチャンネル数
  int get activeChannels => _channels.length;
}
