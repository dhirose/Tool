<#
【概要】
Gitのリモートリポジトリとローカルリポジトリの全てのブランチの同期をとるツール

【詳細】
以下の順で処理を行いリモートと同期をとる
①「git fetch --prune」でリモート追跡ブランチを更新する
②リモートにあり、ローカルに存在しないブランチを作成する
③リモートになく、ローカルに存在するブランチを削除する
④ローカルブランチの更新
  ・switchする ⇒ switchが成功すればpullする

[設定]
GitConf.jsonの以下の項目を変更することで、

CYCLE_EXECUTION：周期実行のON/OFF設定
SLEEP_TIME_HOURS：周期実行時の待機時間（時）
SLEEP_TIME_MINUTES：周期実行時の待機時間（分）
SLEEP_TIME_SECONDS：周期実行時の待機時間（秒）
SHOW_WARN_FOR_GIT_PULL：ローカルブランチ更新時にGitコマンドの使用を控えるよう警告表示する
#>

# 実行ファイルのフルパスを取得して、親ディレクトリを取得する
[string]$contextPath = $MyInvocation.MyCommand.Path | Split-Path -Parent
. "${contextPath}\classes\StandardPrinter.ps1"
. "${contextPath}\classes\Git.ps1"

# JSONファイルから設定値を読み込む
$conf = Get-Content -Path "${contextPath}\GitSyncConf.json" | ConvertFrom-Json

[Git]$git = [Git]::new([bool]$conf.SHOW_WARN_FOR_GIT_PULL)
[StandardPrinter]$printer = [StandardPrinter]::new()
[bool]$is_cycle_exe = [bool]$conf.CYCLE_EXECUTION
do {
    $git.syncBranches()
    $printer.print("↓↓↓ ※同期終了後のブランチ確認のための出力 ↓↓↓")
    git branch --all
    $printer.print("↓↓↓ ※verboseも出力 ↓↓↓")
    git branch -vv
    if($is_cycle_exe) {
        # スリープ時間の合計秒数で算出
        [int]$totalSeconds = ([int]$conf.SLEEP_TIME_HOURS * 60 * 60) + ([int]$conf.SLEEP_TIME_MINUTES * 60) + [int]$conf.SLEEP_TIME_SECONDS

        # 1秒ごとに更新するループ
        for([int]$i = 1; $i -le $totalSeconds; $i++) {
            # 進捗状況をパーセンテージ（％）で算出
            $percentComplete = [int](($i / $totalSeconds) * 100)
            $status = "進行状況: $i/$totalSeconds 秒（残り $($totalSeconds-$i)秒） - $percentComplete% 完了"
            # プログレスバーのステータスを更新
            Write-Progress -Activity "スリープ中" -Status $status -PercentComplete $percentComplete
            Start-Sleep -Seconds 1
        }
        # プログレスバーを消去する
        Write-Progress -Activity "スリープ終了" -Status "進行状況: 5/5 秒(0)" -PercentComplete 100 -Completed
    }
} while($is_cycle_exe)