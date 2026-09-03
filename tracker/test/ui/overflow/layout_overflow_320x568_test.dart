// Layout overflow sweep - 320x568 minimum window. One size per file: each
// *_test.dart runs in its own flutter_tester process, giving the sweep a
// fresh libisar native worker pool (see layout_overflow_sweep.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/test_helpers.dart';
import 'layout_overflow_sweep.dart';

void main() {
  setUpAll(initIsarCore);
  testWidgets('no overflow at 320x568-min', (tester) async {
    await sweepSize(tester, '320x568-min', const Size(320, 568));
  });
}
