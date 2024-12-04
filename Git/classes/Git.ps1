class Git {
    [string[]]$remoteBrancheList
    [string[]]$localBrancheList
    [bool]$showWarningForGitPull
    [string]$contextPatha = "${PSScriptRoot}\StandardPrinter.ps1"
    [StandardPrinter]$printer

    Git([bool]$showWarningForGitPull) {
        # リポジトリのパスを指定
        #Set-Location -Path "C:\Users\hirok\!work\Git\kiroku"
        Set-Location -Path ($PSScriptRoot | Split-Path -Parent | Split-Path -Parent)
        $this.showWarningForGitPull = $showWarningForGitPull
        $this.printer = [StandardPrinter]::new()
    }

    # 全体の同期を実行
    [void]syncBranches() {
        $this.printer.print("同期を開始")
        # フェッチしてリモートのブランチ情報を更新 & リモート追跡ブランチを整理する
        $this.printer.print("リモート追跡ブランチの更新")
        git fetch --prune
        
        $this.remoteBrancheList = git branch -r | ForEach-Object { $_.Trim() } | Where-Object { $_ -notmatch 'HEAD' }
        $this.localBrancheList = git branch | ForEach-Object { $_.Trim("* ").Trim() }

        $this.syncRemoteBranchesToLocal()
        $this.deleteUntrackedLocalBranches()
        if($this.showWarningForGitPull) {
            $this.showWarnForGitPull()
        }
        $this.mergeChangesToLocalBranches()
    }

    # ローカルに存在しないリモートブランチを作成
    [void]syncRemoteBranchesToLocal(){
        $this.printer.print("リモートにあり、ローカルに存在しないブランチを作成")
        foreach ($remoteBranch in $this.remoteBrancheList) {
            $branchName = $remoteBranch -replace "origin/", ""
            if ($this.localBrancheList -notcontains $branchName) {
                $this.printer.print("ブランチ作成:$branchName")
                git branch $branchName $remoteBranch
            }
        }
    }

    # リモートに存在しないローカルブランチを削除
    [void]deleteUntrackedLocalBranches(){
        $this.printer.print("リモートになく、ローカルに存在するブランチを削除")
        foreach ($localBranch in $this.localBrancheList) {
            $remoteBranch = "origin/$localBranch"
            if ($this.remoteBrancheList -notcontains $remoteBranch) {
                $this.printer.print("ブランチ削除:{$localBranch}")
                git branch -d $localBranch
            }
        }
    }

    # 変更があるブランチをローカルブランチに反映
    [void]mergeChangesToLocalBranches() {
        $this.printer.print("ローカルブランチの更新")
        # 現在のブランチを取得
        $currentBranch = git branch --show-current
        foreach ($remoteBranch in $this.remoteBrancheList) {
            $branchName = $remoteBranch -replace "origin/", ""
            if ($this.localBrancheList -contains $branchName) {
                $this.printer.print("ブランチ切替:$branchName")
                git switch $branchName
                if ($?) {
                    # git switchコマンドが成功した場合、pullする
                    $this.printer.print("ブランチの更新:$branchName")
                    git pull origin $branchName
                }
            }
        }
        $this.printer.print("元のブランチに戻る:$currentBranch")
        # 元のブランチに戻る
        git switch $currentBranch
    }

    # 変更があるブランチをローカルブランチに反映
    [void]showWarnForGitPull() {
        # System.Windows.Forms をロード
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        # ポップアップフォームを作成
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "警告"
        $form.Width = 1200
        $form.Height = 400
        $form.StartPosition = "CenterScreen"
        $form.Location = New-Object System.Drawing.Point(0, 0)  # 画面左上に表示
        $form.TopMost = $true
        $form.BackColor = [System.Drawing.Color]::Yellow  # 背景色を黄色に設定

        # ラベルを作成してフォームに追加
        $label = New-Object System.Windows.Forms.Label
        $label.Text = @"
        これは警告メッセージです

        リモートの全てのブランチを自動でプルします。
        プルする際にローカルブランチの切替が行われます。
        本処理が実行されている間は、Git関連のコマンドの実行を控えることを推奨します。

        ・この警告ウィンドウは5分間の間表示されます。5分経過すると自動でウィンドウが閉じます。
        ・ウィンドウが表示されている間は、Gitプルは行われません。
        ・Gitプルしても問題ない場合は、ご自身でウィンドウの[×]ボタンを押して閉じるか、5分経過してウィンドウが閉じられるのをお待ちください。
        ・Gitプルしたくない場合は、この警告ウィンドウが表示されている間にツールを停止してください。
"@
        $label.AutoSize = $true
        $label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $label.Location = New-Object System.Drawing.Point(50, 30)
        $form.Controls.Add($label)

        # タイマーを設定して5秒後にフォームを閉じる
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = (5 * 60 * 1000)  # 5分（ミリ秒指定）
        $timer.Add_Tick({
            $timer.Stop()
            $form.Close()
        })
        # タイマーを開始
        $timer.Start()
        # フォームをモーダルで表示（表示中は他の処理を停止）
        $form.ShowDialog()
        # フォームが閉じるのを待つ
        $form.Dispose()
    }
}