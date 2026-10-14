import 'package:flutter/widgets.dart';

/// 子を画面の中央に置きつつ、高さが足りないとき（文字を大きくした端末・狭い画面）は
/// スクロールで全体に届くようにする。`Center` + `Column(min)` だと、収まらない分が
/// 下にはみ出して切れ、ボタンに触れなくなるため、その代わりに使う。
class ScrollableCenter extends StatelessWidget {
  const ScrollableCenter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
