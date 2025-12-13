// ignore_for_file: unrelated_type_equality_checks
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:learningfirebase/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart'
    show MissingPlatformDirectoryException, getApplicationCacheDirectory;

/// ---------------------------------------------------------------------------
/// NOTES SERVICE
/// ---------------------------------------------------------------------------
///
/// This class acts as a **data access layer (DAL)** or **repository** for notes.
///
/// Responsibilities:
/// 1. Open and close the local SQLite database
/// 2. Perform CRUD operations on users and notes
/// 3. Maintain an in-memory cache of notes for performance
/// 4. Expose a stream so the UI can react to data changes
///
/// Why this abstraction exists:
/// - Keeps database logic OUT of UI widgets
/// - Makes the app scalable and testable
/// - Allows easy replacement of SQLite with another backend later
///

class NotesService {
  /// Holds the reference to the SQLite database.
  /// It is nullable because the database may not yet be opened.
  Database? _db;

  /// In-memory cache of notes.
  ///
  /// Why cache?
  /// - Avoids hitting the database repeatedly
  /// - Makes streams fast and reactive
  /// - Keeps UI updates smooth
  List<DatabaseNote> _notes = [];

  // Singleton pattern implementation
  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance();
  factory NotesService() => _shared;

  /// StreamController that broadcasts changes in notes.
  ///
  /// Why broadcast?
  /// - Multiple widgets (listeners) may need updates simultaneously
  /// - Example: notes list + note editor screen
  /// Streamcontroller listens to the notes service for changes
  final _notesStreamController =
      StreamController<List<DatabaseNote>>.broadcast();

  Stream<List<DatabaseNote>> get allNotes =>
      _notesStreamController.stream;

  /// -------------------------------------------------------------------------
  /// USER HELPERS
  /// -------------------------------------------------------------------------

  /// Gets an existing user or creates a new one if it does not exist.
  ///
  /// This is commonly used during authentication flows.
  ///
  /// Logic:
  /// 1. Try to fetch the user
  /// 2. If user does not exist → create a new one
  ///
  /// This avoids duplicate logic across the app.
  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFinadUserException {
      final createdUser = await createUser(email: email);
      return createdUser;
    }
  }

  /// -------------------------------------------------------------------------
  /// INTERNAL CACHE MANAGEMENT
  /// -------------------------------------------------------------------------

  /// Reads all notes from the database and updates:
  /// 1. Local in-memory cache
  /// 2. Notes stream (notifies UI)
  ///
  /// This method is PRIVATE because:
  /// - It is an internal synchronization mechanism
  /// - External callers should not control caching behavior
  Future<void> _cacheNotes() async {
    await _ensureDbIsOpen();
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  /// -------------------------------------------------------------------------
  /// NOTE CRUD OPERATIONS
  /// -------------------------------------------------------------------------

  /// Updates an existing note’s text.
  ///
  /// Why steps matter:
  /// 1. Ensure database is open
  /// 2. Ensure note exists (avoids silent failures)
  /// 3. Update database row
  /// 4. Update local cache
  /// 5. Notify listeners via stream
  ///
  /// This guarantees **data consistency** across DB, cache, and UI.
  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    final db = _getDatabaseOrThrow();
    // make sure note exists
    await getNote(id: note.id);
    // update the note
    final updatesCount = await db.update(
      noteTable,
      {textColumn: text, isSyncedWithCloudColumn: 0},
      where: 'id = ?',
      whereArgs: [note.id],
    );
    if (updatesCount == 0) {
      throw CouldNotUpdateNoteException();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  /// Returns ALL notes from the database.
  ///
  /// This method:
  /// - Does NOT modify cache directly
  /// - Is mainly used internally during initialization and refresh
  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);
    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow)).toList();
  }

  /// Fetches a single note by ID.
  ///
  /// Why limit = 1?
  /// - ID is unique
  /// - Prevents unnecessary data reads
  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNoteException();
    } else {
      final note = DatabaseNote.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  /// Deletes ALL notes from the database.
  ///
  /// Typically used:
  /// - During logout
  /// - Debugging or reset operations
  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  /// Deletes a single note by ID.
  ///
  /// Ensures:
  /// - Database deletion succeeded
  /// - Cache is updated
  /// - UI is notified
  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNoteException();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  /// Creates a new note for a given user.
  ///
  /// Key validations:
  /// - Owner must exist in database
  /// - Prevents orphan notes
  ///
  /// New notes start with:
  /// - Empty text
  /// - Unsynced cloud state
  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final dbUser = await getUser(email: owner.email);

    if (dbUser != owner) {
      throw CouldNotFinadUserException();
    }

    const text = '';
    // create the note
    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });

    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: false,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
  }

  /// -------------------------------------------------------------------------
  /// USER CRUD OPERATIONS
  /// -------------------------------------------------------------------------

  /// Fetches a user by email.
  ///
  /// Email is normalized to lowercase to prevent duplicates.
  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotDeleteUserException();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  /// Creates a new user.
  ///
  /// Enforces:
  /// - Unique email constraint
  /// - Database-level integrity
  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    // Check if user already exists
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    // If user exists, throw exception
    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }
    // If user does not exist, create new user
    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });
    return DatabaseUser(id: userId, email: email);
  }

  /// Deletes a user by email.
  ///
  /// Expected behavior:
  /// - Exactly ONE user must be deleted
  /// - Otherwise → data inconsistency
  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUserException();
    }
  }

  /// -------------------------------------------------------------------------
  /// DATABASE LIFECYCLE
  /// -------------------------------------------------------------------------

  /// Safely retrieves the database or throws if not opened.
  ///
  /// This prevents:
  /// - Null pointer exceptions
  /// - Silent failures
  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  

  /// Closes the database connection.
  ///
  /// Important for:
  /// - App shutdown
  /// - Preventing memory leaks
  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseAlreadyOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      // Database is already open, no action needed
    }
  }

  /// Opens the database and initializes tables.
  ///
  /// Steps:
  /// 1. Resolve app directory
  /// 2. Open database file
  /// 3. Create tables if they do not exist
  /// 4. Cache existing notes
  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationCacheDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      // Create the user table
      await db.execute(createUserTable);
      // Create the note table
      await db.execute(createNoteTable);
      // We will read all notes from the database and cache them in _notes
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({required this.id, required this.email});

  /// User will be represented in (string, object?) format
  DatabaseUser.fromRow(Map<String, Object?> map)
    : id = map[idColumn] as int,
      email = map[emailColumn] as String;

  @override
  String toString() => 'Perosn, id = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
    : id = map[idColumn] as int,
      userId = map[userIdColumn] as int,
      text = map[textColumn] as String,
      isSyncedWithCloud = (map[isSyncedWithCloudColumn] as int) == 1
          ? true
          : false;

  @override
  String toString() =>
      'Note, id = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUserTable = '''CREATE TABLE IF NOT EXISTS"user" (
          "id"	INTEGER NOT NULL,
          "email"	TEXT NOT NULL UNIQUE,
          PRIMARY KEY("id" AUTOINCREMENT)
        );''';
const createNoteTable = '''CREATE TABLE "note" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT,
        "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("user_id") REFERENCES "user"("id")
        ); ''';
