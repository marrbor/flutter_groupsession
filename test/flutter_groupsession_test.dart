import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_groupsession/flutter_groupsession.dart';

void main() {
  test('login and load schedule', () async {
    final ga = GSessionAccessor('', '', '');
    await ga.login();
    print(ga.dump());
    final l = await ga.getEvents(DateTime.now(), 14);
    l.forEach((e) => print(e.dump()));
    final ver = await ga.getVersion();
    print(ver);
  });
}
