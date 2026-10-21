import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart'
    show
        DataManagementSection,
        ExamPrepStrings,
        FileSaver,
        PremiumBenefit,
        PremiumBenefitsCard,
        PremiumBenefitsStrings,
        historyCsvFileName,
        shareCsv;
import 'package:ukalab_core/ukalab_core.dart'
    show ExamConfig, PremiumFeature, Question, Term, historyCsv;

import 'package:ukalab_core/cross_promo.dart' show UkalabCrossPromoSection;
import 'package:ukalab_core/daily_goal.dart' show DailyGoalSetting;
import 'package:ukalab_core/reminder.dart' show ReminderSettingsSection;
import 'package:ukalab_core/exam_date.dart';
import '../data/data_parts.dart';
import '../data/history_store.dart';
import '../data/peer_stats_prep.dart';
import '../widgets/peer_stats_settings_tile.dart';
import 'exam_prep_entry.dart';
import 'mistake_note_screen.dart';

/// 設定の購入節に出す、プレミアムでできることの文言。このアプリで実際に
/// プレミアム限定になっている機能だけを載せる（価格は載せない）。
/// 学習履歴の書き出しは、設定の CSV ダウンロードが無料のため載せない。
const kItPassportPremiumBenefits = PremiumBenefitsStrings(
  title: 'プレミアムでできること',
  freeNote: '広告も表示されなくなります。問題・解説・基本の苦手特訓は、無料のまま使えます。'
      '模擬試験と今日の復習は、無料版だと回数に上限があります。',
  benefits: {
    PremiumFeature.weakDrill: PremiumBenefit(
      '弱点集中ドリル',
      '間違えた原因ごとの集計と推移を見ながら、弱点を集中して練習できます。',
    ),
    PremiumFeature.examEveMode: PremiumBenefit(
      '試験直前モード',
      '試験日の3日前から、最近間違えた問題などを見直せます。',
    ),
    PremiumFeature.tenMinutePlan: PremiumBenefit(
      '今日の10分プラン',
      '10分に収まる分だけ、今日解く問題を選びます。',
    ),
    PremiumFeature.mockExamHistory: PremiumBenefit(
      '模擬試験の成長グラフ',
      '複数回分の得点率を並べて、伸びを確かめられます。',
    ),
    PremiumFeature.customMockExam: PremiumBenefit(
      'カスタム模擬試験',
      '科目を指定して、模擬試験を出題できます。',
    ),
    PremiumFeature.readingReadAloud: PremiumBenefit(
      '解説読み物の読み上げ',
      '章ごとの解説読み物を、全文読み上げで聞けます。',
    ),
  },
);

/// 「設定」タブ。課金（決定35）の購入・復元を提供する。広告はnoads/premiumの
/// どちらかを持つと自動的に非表示になる（`AdGate.adsHidden`）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    this.questions = const [],
    this.exam,
    this.terms = const [],
    this.fileSaver,
    this.now,
    this.focusPurchase = false,
  });

  /// 履歴CSVの保存（共有）処理。省略時は core の既定（Web はダウンロード、他は共有シート）。テスト用に差し替える。
  final FileSaver? fileSaver;

  /// 履歴CSVのファイル名の日付に使う現在時刻。省略時は [DateTime.now]。テスト用。
  final DateTime Function()? now;

  /// true なら、開いた直後に「購入」欄までスクロールする（ホームの推しカードからの誘導用）。
  final bool focusPurchase;

  /// 間違いノートの「解き直す」で演習画面を開くために使う。省略時は間違いノートの入口を出さない。
  final ExamConfig? exam;
  final List<Term> terms;

  /// 履歴CSVの分野集計で、記録に章が無い旧データを補うために使う。
  final List<Question> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement =
        ref.watch(entitlementStateProvider).valueOrNull ?? EntitlementState.free;
    final service = ref.watch(entitlementServiceProvider);
    final handsFree = ref.watch(handsFreeProvider);

    return ListView(
      // 購入欄は下の方にあり、ListView は画面外を作らないため、誘導時だけ全体を作ってスクロール先を確保する。
      // ignore: deprecated_member_use
      cacheExtent: focusPurchase ? 10000 : null,
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          title: Text('このアプリについて'),
          subtitle: Text(
            '「うかラボ ITパスポート」は、独立行政法人情報処理推進機構（IPA）とは'
            '無関係に開発・運営する非公式の学習アプリです。問題はすべて独自に作成しています。',
          ),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('バージョン'),
          // 実際にインストールされた版（pubspec の version）を読む。
          subtitle: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) =>
                Text(snapshot.hasData ? snapshot.data!.version : ''),
          ),
        ),
        const Divider(height: 24),
        SwitchListTile(
          title: const Text('ながら学習モード'),
          subtitle: const Text('大きな選択肢ボタンで、問題を読み上げます。'),
          value: handsFree.enabled,
          onChanged: (v) => ref.read(handsFreeProvider.notifier).setEnabled(v),
        ),
        if (handsFree.enabled)
          SwitchListTile(
            title: const Text('問題を読み上げる'),
            value: handsFree.speakQuestion,
            onChanged: (v) => ref.read(handsFreeProvider.notifier).setSpeakQuestion(v),
          ),
        ExamDateTile(
          date: ref.watch(examDateProvider),
          onChanged: (d) => ref.read(examDateProvider.notifier).setDate(d),
        ),
        // 送信側が未実装の間は出さない（kPeerStatsSettingsVisible = false）。
        if (kPeerStatsSettingsVisible)
          PeerStatsSettingsTile(settings: ref.watch(peerStatsSettingsProvider)),
        ListTile(
          key: const ValueKey('downloadHistoryCsv'),
          title: const Text('学習履歴をダウンロード（CSV）'),
          subtitle: const Text('日ごと・分野ごとの解答数と正答率。個人情報は含みません。'),
          onTap: () => _saveHistory(context, ref),
        ),
        const Divider(height: 24),
        _ScrollIntoViewOnce(
          enabled: focusPurchase,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('購入', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        if (entitlement.adsHidden)
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(entitlement.hasPremium ? 'プレミアムを購入済みです' : '広告非表示を購入済みです'),
          )
        else
          FutureBuilder<List<EntitlementOffer>>(
            future: service.offers(),
            builder: (context, snapshot) {
              final offers = snapshot.data ?? const [];
              if (offers.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  for (final offer in offers)
                    ListTile(
                      title: Text(offer.title),
                      trailing: FilledButton(
                        onPressed: () => _purchase(context, ref, offer),
                        child: Text(offer.priceString),
                      ),
                    ),
                ],
              );
            },
          ),
        TextButton(
          onPressed: () => _restore(context, ref),
          child: const Text('購入を復元'),
        ),
        if (!entitlement.hasPremium)
          const PremiumBenefitsCard(
            strings: kItPassportPremiumBenefits,
            features: [
              PremiumFeature.weakDrill,
              PremiumFeature.examEveMode,
              PremiumFeature.tenMinutePlan,
              PremiumFeature.mockExamHistory,
              PremiumFeature.customMockExam,
              PremiumFeature.readingReadAloud,
            ],
          ),
        const Divider(height: 24),
        const DailyGoalSetting(),
        const Divider(height: 24),
        const ReminderSettingsSection(),
        const Divider(height: 24),
        DataManagementSection(
          parts: itPassportDataParts,
          description: '学習進捗・解答履歴・自分用メモは、試験日・ブックマークを除いて、'
              '書き出し・読み込み・リセットができます。',
        ),
        CoreFeatureSettingsTiles(questions: questions),
        if (exam != null)
          ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('間違いノート'),
            subtitle: const Text('間違えた問題を見返して、解き直せます。'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openMistakeNote(context,
                exam: exam!, questions: questions, terms: terms),
          ),
        // 掲載リストが空なら何も表示しない。うかラボは大人向けなので保護者ゲートは不要。
        const UkalabCrossPromoSection(currentAppId: 'com.yourwish.ukalab.it_passport'),
      ],
    );
  }

  Future<void> _saveHistory(BuildContext context, WidgetRef ref) async {
    // 履歴は初回の読み取りで読み込みが始まるため、読み終えるのを待ってから使う。
    await ref.read(historyProvider.notifier).ready;
    final records = ref.read(historyProvider);
    final strings = ExamPrepStrings.ja;
    String? message;
    if (records.isEmpty) {
      message = 'まだ学習履歴がありません。';
    } else {
      try {
        final saved = await shareCsv(
          csv: historyCsv(records, questions),
          fileName: historyCsvFileName((now ?? DateTime.now)()),
          saver: fileSaver,
        );
        if (saved) message = strings.exportSaved;
      } catch (_) {
        message = strings.exportSaveFailed;
      }
    }
    if (!context.mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _purchase(BuildContext context, WidgetRef ref, EntitlementOffer offer) async {
    final outcome = await ref.read(entitlementServiceProvider).purchaseOffer(offer.id);
    if (!context.mounted) return;
    final message = switch (outcome) {
      PurchaseOutcome.success => '購入しました。',
      PurchaseOutcome.cancelled => '購入をキャンセルしました。',
      PurchaseOutcome.blockedByGate => '購入できませんでした。',
      PurchaseOutcome.failed => '購入に失敗しました。',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final state = await ref.read(entitlementServiceProvider).restore();
    if (!context.mounted) return;
    final message = state.adsHidden ? '購入を復元しました。' : '復元できる購入がありませんでした。';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// [enabled] なら、最初の描画の直後に自分が見える位置までスクロールする（1回だけ）。
class _ScrollIntoViewOnce extends StatefulWidget {
  const _ScrollIntoViewOnce({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_ScrollIntoViewOnce> createState() => _ScrollIntoViewOnceState();
}

class _ScrollIntoViewOnceState extends State<_ScrollIntoViewOnce> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(context, alignment: 0.1);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
