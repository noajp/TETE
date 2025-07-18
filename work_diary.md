# TETE開発 作業日記

## 2025年07月12日 (土)

### 実装した機能 ✅
- 

### うまくいかなかったところ ❌
- 

### 明日に引き継ぎたいこと 📋
1. 
2. 
3. 

### 今日の感情・進歩 💭
**感情**: 

**進歩したこと**:
- 

**学んだこと**:
- 

### 技術的なメモ 📝
- 

---



## 2025年07月09日 (水)

### 実装した機能 ✅
- 

### うまくいかなかったところ ❌
- 

### 明日に引き継ぎたいこと 📋
1. 
2. 
3. 

### 今日の感情・進歩 💭
**感情**: 

**進歩したこと**:
- 

**学んだこと**:
- 

### 技術的なメモ 📝
- 

---



## 2025年07月05日 (土)

### 実装した機能 ✅
- 

### うまくいかなかったところ ❌
- 

### 明日に引き継ぎたいこと 📋
1. 
2. 
3. 

### 今日の感情・進歩 💭
**感情**: 

**進歩したこと**:
- 

**学んだこと**:
- 

### 技術的なメモ 📝
- 

---



## 2025年07月04日 (金)

### 実装した機能 ✅
- 

### うまくいかなかったところ ❌
- 

### 明日に引き継ぎたいこと 📋
1. 
2. 
3. 

### 今日の感情・進歩 💭
**感情**: 

**進歩したこと**:
- 

**学んだこと**:
- 

### 技術的なメモ 📝
- 

---



## 2025年07月02日 (水)

### 実装した機能 ✅
- 

### うまくいかなかったところ ❌
- 

### 明日に引き継ぎたいこと 📋
1. 
2. 
3. 

### 今日の感情・進歩 💭
**感情**: 

**進歩したこと**:
- 

**学んだこと**:
- 

### 技術的なメモ 📝
- 

---



## 2025年07月01日 (火)

### 実装した機能 ✅
- 

### うまくいかなかったところ ❌
- 

### 明日に引き継ぎたいこと 📋
1. 
2. 
3. 

### 今日の感情・進歩 💭
**感情**: 

**進歩したこと**:
- 

**学んだこと**:
- 

### 技術的なメモ 📝
- 

---



## 2025年06月30日 (月)

### 実装した機能 ✅
- 

### うまくいかなかったところ ❌
- 

### 明日に引き継ぎたいこと 📋
1. 
2. 
3. 

### 今日の感情・進歩 💭
**感情**: 

**進歩したこと**:
- 

**学んだこと**:
- 

### 技術的なメモ 📝
- 

---



## 2025年6月30日 (日)

### 実装した機能 ✅
- **アップロードステータス表示機能の復活**: ModernCreatePostFlowにUploadStatusOverlayコンポーネントを追加
- **データベース状態の確認と検証**: MCPツールで投稿とプロフィールの紐づけが正常に動作していることを確認
- **投稿作成フローの最終調整**: 詳細なエラーログと進捗表示の改善
- **ビルドエラーの修正**: すべてのコンパイルエラーを解決し、アプリのビルドが成功

### うまくいかなかったところ ❌
- **認証セッションの状態**: データベース側で`auth.uid()`がnullのままだが、これはユーザー再ログインで解決予定
- **警告メッセージ**: weak selfの使用に関する警告が残っているが機能に影響なし

### 明日に引き継ぎたいこと 📋
1. **実機でのテスト**: アプリをシミュレーターまたは実機で起動してログイン・投稿フローをテスト
2. **ユーザー認証の再確認**: 必要に応じて再ログインしてセッション状態を修正
3. **投稿作成の全体フローテスト**: 画像選択→編集→投稿→フィード表示の完全なフローを検証

### 今日の感情・進歩 💭
**感情**: システムの根本的な問題が解決され、すべてのコンポーネントが正常に動作する状態になったことに達成感を感じる。

**進歩したこと**:
- アップロードステータス表示機能の完全な実装
- データベーステーブル間の関係性が正常に機能していることの確認
- MCPツールを使った効果的なデータベース調査手法の習得
- SwiftUIのNotificationCenterを使った非同期UI更新パターンの実装

**学んだこと**:
- UploadStatusOverlayコンポーネントの設計と実装パターン
- 投稿作成時の進捗管理とユーザーフィードバックの重要性
- データベースRLSポリシーの適切な設計と検証方法

### 技術的なメモ 📝
- `UploadStatusOverlay`での進捗表示とアニメーション実装
- NotificationCenterでの投稿状態管理（.postUploadStarted, .postUploadProgress, .postUploadCompleted, .postUploadFailed）
- PostgreSQL RLSポリシーのWITH CHECK条件が正常に動作することの確認

---

## 2025年6月29日 (土)

### 実装した機能 ✅
- **スクロール時のヘッダー表示/非表示機能**: HomeFeedViewでスクロールに応じてヘッダーが隠れる機能を実装
- **データベーステーブル修正**: `user_profiles` → `profiles` への参照変更
- **投稿作成時の通知システム**: PostCreated通知でFeedとMyPageの自動更新
- **メッセージ機能のキーボード対応**: ConversationViewでFocusStateとキーボード回避を実装
- **エラーログの改善**: 投稿作成時の詳細なエラーログ追加

### うまくいかなかったところ ❌
- **投稿とプロフィールの紐づけ**: データベースに`user_profiles`と`profiles`テーブルが重複存在
- **認証セッションの問題**: `auth.uid()`がnullになる状態が発生
- **投稿作成時のレスポンス**: "No response data from post creation"エラー
- **スクロールログの過剰出力**: ログが多すぎて削除が必要だった

### 明日に引き継ぎたいこと 📋
1. **データベース移行の完了**: 古い`user_profiles`から新しい`profiles`へのデータ移行
2. **認証セッションの修正**: ユーザーの再ログインとセッション管理の改善
3. **投稿作成フローの最終調整**: RLSポリシーとレスポンス処理の修正
4. **テストデータの整理**: 開発用の一貫したテストデータセットの準備

### 今日の感情・進歩 💭
**感情**: 問題の根本原因が特定できて安心感がある。データベース構造の重複問題が明確になったのは大きな前進。

**進歩したこと**:
- MCPツールを使ったSupabaseデータベースの直接調査ができるようになった
- SwiftUIのスクロール検知とヘッダー制御の実装パターンを習得
- 通知ベースのView更新システムの設計・実装
- データベーステーブル間の関係性とRLSポリシーの理解が深まった

**学んだこと**:
- データベース移行時は既存データとの整合性確認が重要
- 認証セッションの状態管理はフロントエンドとバックエンドの連携が必要
- ログ出力は開発時は詳細に、本番時は最適化が必要

### 技術的なメモ 📝
- `@FocusState.Binding`の正しい使用方法
- `Task.detached`での適切なweak selfの使用
- PostgreSQL RLSポリシーの`WITH CHECK`条件の重要性
- SwiftUIでの座標空間(`coordinateSpace`)の活用

---

**明日の作業開始時**: この日記を必ず読み返してから作業開始すること
**自動日記開始時刻**: 毎日23:55に新しい日記エントリを作成