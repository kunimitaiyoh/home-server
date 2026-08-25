---
name: storybooking-pages
description: Use when adding Storybook stories for Next.js App Router page components that are server components with data fetching
---

# Storybooking Pages

サーバーコンポーネントであるページに Storybook ストーリーを追加する手順。

## ファイル構成

`page.tsx` と同階層に以下を作成する:

```
src/app/(group)/some-page/
  page.tsx              # サーバーコンポーネント（データ取得）
  view.tsx              # プレゼンテーショナルコンポーネント（新規）
  view.stories.tsx      # ストーリー（新規）
```

## view.tsx

### 命名規則

- コンポーネント: `{Page}PageView`（例: `MenuPageView`, `DevicesPageView`）
- Props: `{Page}PageViewProps`

### Props 設計

API レスポンスオブジェクトをそのまま受け取る。スカラー値に分解しない。

- ページビューは画面全体のコンポーネントであり、将来的にレスポンスの他フィールドを参照する可能性が高い。スカラー値に分解すると、ビューの拡張のたびに props の変更が必要になる。
- 再利用を前提とする末端コンポーネントと異なり、ページビューは特定のページに結びついているため、`string` や `number` などの汎用的な型を受け取るべき理由がない。

```typescript
// ✅ Good: API レスポンスの型をそのまま使う
interface MenuPageViewProps {
  devices: ItemList<Device>;
  members: ItemList<ShallowMember>;
  summary: EventLogSummary;
  logs: ItemList<EventLog>;
}

// ❌ Bad: スカラー値に分解
interface MenuPageViewProps {
  devicesTotal: number;
  membersTotal: number;
}
```

- フィールド名に `Data` サフィックスを付けない（`devices` not `devicesData`）
- `React.FC<Props>` で型付けする

## page.tsx の修正

JSX を `view.tsx` に移動し、API レスポンスをそのまま渡す:

```tsx
return <MenuPageView devices={devices} members={members} summary={summary} logs={logs} />;
```

## サーバーアクションの DI

クライアントコンポーネントがサーバーアクション（`"use server"` モジュール）を直接インポートすると、`node:crypto` 等のサーバー専用モジュールがクライアントバンドルの依存ツリーに入り Storybook がビルドできない。サーバーアクションは props 経由で注入（DI）する。

### 依存の方向

```
page.tsx ── actions をインポートし view に渡す
  └─ view.tsx ── クライアントコンポーネントにアクション props を中継
       └─ *-form.tsx ── Props でアクションの型を定義・export（型の所有者）
            ↑ actions.ts ── import type で Props を参照し、関数の型を合わせる
```

クライアントコンポーネントが型の所有者になる理由: actions.ts に型を置くと、クライアントコンポーネントが actions.ts を `import type` する形になる。`import type` は実行時に消えるので直接の問題は起きないが、依存の方向が「クライアント → サーバーアクション」となり、本来の関係（サーバーアクションがクライアントの要求に適合する）と逆になる。クライアントコンポーネントが「自分が必要とするもの」を定義し、サーバーアクションがそれに合わせる。

### コード例

```tsx
// *-form.tsx: Props でアクションの型を定義
export interface DeviceFormProps {
  device: Device;
  updateDevice: (deviceId: string, formData: FormData) => Promise<void>;
}
export const DeviceForm: React.FC<DeviceFormProps> = ({ device, updateDevice }) => { ... };

// actions.ts: import type で Props を参照
import type { DeviceFormProps } from "./device-form";
export const updateDevice: DeviceFormProps["updateDevice"] = async (deviceId, formData) => { ... };

// view.tsx: アクション props の型は FormProps["actionName"] で参照
import type { DeviceFormProps } from "./device-form";
interface DeviceDetailPageViewProps {
  device: Device;
  updateDevice: DeviceFormProps["updateDevice"];
}

// page.tsx: 両者を結合
import { updateDevice } from "./actions";
return <DeviceDetailPageView device={device} updateDevice={updateDevice} />;
```

## view.stories.tsx

### 構造

```typescript
import type { Meta, StoryObj } from "@storybook/react";
import { fn } from "storybook/test";
import { MockPageLayout } from "@/test/mocks/layouts";
import { SomePageView } from "./view";

const meta = {
  title: "Pages/SomePageView",
  component: SomePageView,
  parameters: {
    layout: "fullscreen",
    nextjs: {
      appDirectory: true,
      navigation: { pathname: "/some-page" },  // レイアウトがパス名からナビの活性状態を決める場合に必要
    },
  },
  decorators: [(Story) => <MockPageLayout><Story /></MockPageLayout>],
} satisfies Meta<typeof SomePageView>;
```

### 共通モック

ページビューは実際のページと同じレイアウト・コンテキストプロバイダーの配下で描画する必要がある。複数のページストーリーで共有するモックは 1 箇所に集約する。プロジェクトに既存の共通モックがあればそれに従う。

以下のとおり責務ごとに分ける:

| ファイル | 責務 |
|---|---|
| `models.ts` | エンティティ値 |
| `stores.ts` | ストアに渡すデータの組み合わせ |
| `responses.ts` | API レスポンスのモック（ページストーリーの args 用） |
| `providers.tsx` | コンテキストプロバイダー群をまとめたラッパー |
| `layouts.tsx` | プロバイダー + レイアウト（decorator 用） |

- ページが属するレイアウトのモックを decorator に使う
- ページ固有のモックデータ（args）はストーリーファイル内に定義する

### アクション props のモック

アクション props には `fn()` (`storybook/test`) を使う。`args` に渡した `fn()` は arg のキーがモック名になり、呼び出しが Actions パネルに自動的にログされるため、`action()` (`storybook/actions`) を渡す必要はない。加えて `fn()` は spy なので、play 関数から呼び出しをアサートできる。

```tsx
args: {
  updateDevice: fn(),
  deleteDevice: fn(),
  device: { ... },
},
```

実装を渡さない `fn()` は実行時に `undefined` を返す。型は `Promise<void>` を満たすため `await` は通るが、呼び出し側が戻り値に `.then()` / `.catch()` を繋ぐ場合は `fn(async () => {})` のように実装を渡す。

### モックデータ

- Default ストーリーの値は、対応するデザイン資料（モックアップ等）があればそれに合わせる

### 検証

プロジェクトのフォーマットと lint を実行する（例: `pnpm format && pnpm lint`）。
