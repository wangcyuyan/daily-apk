# 每日自动更新 APK · 最小可运行 Demo

把"每天上网搜集、生成不同内容"的自动化任务做成手机 APK 的最小原型。
核心思想：**APK 只做轻薄浏览器壳，每天要变的内容放在远端，APK 启动即拉取最新**——装一次，永远最新，无需重打包。

## 架构（壳与内容分离）

```
[生成端] 每天定时抓取/生成 data.json  --push-->  [托管端] GitHub Pages (/data.json + index.html)  <--pull--  [APK壳] WebView 拉取渲染
```

- ① 生成端：`generator/generate_daily.py`
- ② 托管端：`docs/index.html` + `docs/data.json`（公开 HTTPS）
- ③ APK 壳：`apk-shell/`（Android Studio 工程）

## 目录结构

```
daily-apk-demo/
├── generator/
│   └── generate_daily.py     # 每日生成 data.json：心理哲学 + 毛选 各一条（精选库优先，可选联网）
├── docs/
│   ├── index.html            # 远程展示页，fetch data.json 渲染
│   └── data.json             # 托管的数据文件（每日更新）
├── apk-shell/                # Android Studio 工程（WebView 壳）
│   ├── settings.gradle
│   ├── build.gradle
│   └── app/...
└── README.md
```

## 1. 本地跑通生成端

```bash
cd generator
python generate_daily.py
# 产出 ../docs/data.json（部署时放在 Pages 根目录，与 index.html 同目录）
```

要点：
- 每天产出**两条固定栏目**：`psychology`（心理哲学）+ `mao`（毛选精选），每条都带 `plain` 字段（大白话解释）。
- 内容按"当天日期"做哈希种子选取 → 同日一致、跨天自动切换。
- **B 模式（实时生成，默认 `MODE="live"`）**：心理哲学每天 LLM 实时写一条新概念+大白话；毛选从 `marxists.org` 真实文库按天轮换真实原文，LLM 只写大白话（绝不编造毛选原文）。无网/无 LLM 密钥时自动回退内置真实段落库，仍准确、不空屏。
- **A 模式（仅精选库）**：设 `GEN_MODE=curated` 关闭实时，纯用 `PSYCHOLOGY_POOL`/`MAO_POOL`（各 14 条真实内容+大白话）。
- **毛选铁律**：原文只来自内置真实库或真实文库，LLM 权限仅限于写"大白话解释"，不得生成/改写毛选原文。
- 推荐源：毛选真实文库 `marxists.org/chinese/maozedong/`；心理哲学由 LLM 每日新写。

## 2. 部署托管（GitHub Pages）

1. 把整个仓库推到 GitHub。
2. 仓库 **Settings → Pages → Source** 选 `Deploy from a branch`，branch 选 `main`，folder 选 `/docs`。
3. 打开 `https://<用户名>.github.io/<仓库名>/index.html` 验证能看到当天内容。
4. 每日更新：用 WorkBuddy 自动化（或服务器 cron）运行 `generate_daily.py`，把新 `data.json` 提交回仓库，Pages 自动生效。

> 为什么用整页 `index.html` 而不是直接 fetch JSON？因为 `index.html` 与 `data.json` 同域，
> 天然没有跨域（CORS）问题；APK 只需 `loadUrl` 一个页面即可。

## 3. 编译 APK

1. 用 **Android Studio** 打开 `apk-shell/`。
2. 修改 `MainActivity.java` 里的 `REMOTE_URL` 为你自己的 Pages 地址。
3. **Build → Build Bundle(s)/APK(s) → Build APK**。
4. 安装到手机，打开即看到当天内容；每天自动刷新（`onResume` + 时间戳缓存破坏）。

> 本环境无 Android SDK，故只生成源码、未执行 `gradle build`，编译需在你本地完成。

## 关键注意点

- **APK 永不重打包**：内容每日在远端更新。
- **必须 HTTPS**：安卓 9+ 默认拦截明文 HTTP。
- **禁用缓存 + 时间戳**：`LOAD_NO_CACHE` + `?t=时间戳`，保证拿到当天最新。
- **跨域**：同域整页方案已规避。
- **在线打包工具慎用**：可能注入广告、索取权限，正式用途别用。
