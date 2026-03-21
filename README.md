# codex-app-switcher

一个用于快速切换 Codex 账号并启动 Codex 的 macOS 工具。

## 打包 `.app`（最简单）

在仓库根目录执行：

```bash
./scripts/package-app.sh
```

打包结果：

```bash
./dist/codex-app-switcher.app
```

启动：

```bash
open ./dist/codex-app-switcher.app
```

## 隐私保护（推荐）

安装仓库内置的 `pre-commit` 扫描钩子（会在提交前检查常见密钥和敏感文件名）：

```bash
./scripts/install-git-hooks.sh
```

如果钩子拦截了提交，可先把可疑文件移出暂存区再提交：

```bash
git restore --staged <file>
```
