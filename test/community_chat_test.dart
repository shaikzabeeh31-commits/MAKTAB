import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/community_chat_screen.dart';
import 'package:maktab_management_system/role_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Community Chat Models Serialization Tests', () {
    test('ChatMessage serializes and deserializes correctly', () {
      final msg = ChatMessage(
        id: 'msg_100',
        senderId: 't1',
        senderName: 'Sr. Sana Fatima',
        senderRole: 'Teacher',
        text: 'Requesting book list PDF',
        timestamp: '10:00 AM',
        isMe: true,
        attachmentType: AttachmentType.pdf,
        attachmentName: 'Book_Request_List.pdf',
        attachmentSize: '245 KB',
        reactionEmoji: '❤️',
      );

      final json = msg.toJson();
      expect(json['id'], 'msg_100');
      expect(json['attachmentName'], 'Book_Request_List.pdf');
      expect(json['reactionEmoji'], '❤️');

      final restored = ChatMessage.fromJson(json);
      expect(restored.id, 'msg_100');
      expect(restored.senderName, 'Sr. Sana Fatima');
      expect(restored.attachmentType, AttachmentType.pdf);
    });

    test('PublicAnnouncement serializes and deserializes correctly', () {
      final ann = PublicAnnouncement(
        id: 'ann_1',
        title: 'Holiday Notice',
        body: 'Maktab will remain closed on Friday.',
        authorName: 'Main Owner',
        authorRole: 'Admin',
        timestamp: 'Today',
        targetAudience: 'All Members',
      );

      final json = ann.toJson();
      expect(json['title'], 'Holiday Notice');
      expect(json['targetAudience'], 'All Members');

      final restored = PublicAnnouncement.fromJson(json);
      expect(restored.title, 'Holiday Notice');
      expect(restored.authorRole, 'Admin');
    });
  });

  group('Community Chat Widget Tests', () {
    testWidgets('Renders Community Chat Screen with hierarchy banner & tabs', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(CommunityChatScreen(
        currentRole: AppRole.teacher,
        languageController: ctrl,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('Communication'), findsOneWidget);
      expect(find.textContaining('Manager'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Main Owner'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Book Request List'), findsAtLeastNWidgets(1));
    });

    testWidgets('Opens Announcement dialog when icon is pressed', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(CommunityChatScreen(
        currentRole: AppRole.manager,
        languageController: ctrl,
        initialOpenAnnouncementModal: true,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('اہم اعلان بھیجیں'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Announcement Title'), findsOneWidget);
    });
  });
}
