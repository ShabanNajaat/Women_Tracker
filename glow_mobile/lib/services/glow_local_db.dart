import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite (mobile + desktop). Not used on web.
class GlowLocalDb {
  GlowLocalDb._();
  static final GlowLocalDb instance = GlowLocalDb._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'glow_local.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute(
            'ALTER TABLE community_posts_cache ADD COLUMN phase_room TEXT',
          );
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
        await db.execute('''
CREATE TABLE chat_messages (
  local_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_scope TEXT NOT NULL,
  role TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at_ms INTEGER NOT NULL,
  server_id TEXT
)''');
        await db.execute('CREATE INDEX idx_chat_scope_time ON chat_messages(user_scope, created_at_ms)');
        await db.execute(
          'CREATE UNIQUE INDEX idx_chat_server ON chat_messages(user_scope, server_id) WHERE server_id IS NOT NULL',
        );

        await db.execute('''
CREATE TABLE community_posts_cache (
  post_id TEXT PRIMARY KEY,
  author_name TEXT,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  comment_count INTEGER NOT NULL DEFAULT 0,
  created_at_ms INTEGER,
  fetched_at_ms INTEGER NOT NULL,
  phase_room TEXT
)''');

        await db.execute('''
CREATE TABLE community_comments_cache (
  local_id INTEGER PRIMARY KEY AUTOINCREMENT,
  post_id TEXT NOT NULL,
  server_comment_id TEXT,
  author_name TEXT,
  body TEXT NOT NULL,
  created_at_ms INTEGER,
  fetched_at_ms INTEGER NOT NULL
)''');
        await db.execute(
          'CREATE UNIQUE INDEX idx_comm_comment_server ON community_comments_cache(post_id, server_comment_id) WHERE server_comment_id IS NOT NULL',
        );
  }
}
