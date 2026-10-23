import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';

/// このアプリの資格。資格色（テーマの主色・解いた割合の濃淡など）はすべてここから決まる。
///
/// 新しい資格アプリでは、この1行を `UkalabCert.xxx`（ukalab_core の `UkalabCert`）に
/// 差し替えるだけでよい。色コードはコアの `UkalabCert` が持つので、アプリ側には書かない。
const UkalabCert kAppCert = UkalabCert.itPassport;

/// 現在の資格。テストや別資格では override して差し替える。
final appCertProvider = Provider<UkalabCert>((ref) => kAppCert);

/// [cert] の資格色（ライトは白文字用の濃い色、ダークは暗い文字用の明るい色）。
Color certColorFor(UkalabCert cert, Brightness brightness) =>
    brightness == Brightness.dark ? cert.dark : cert.light;
