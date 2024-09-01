<#################################################################
# 【概要】
# GitHubからアクセストークンを使用してリポジトリの一覧を取得して、結果をファイル出力する 。
# 
# 【詳細】
# GitHubが提供するリポジトリ一覧を取得するAPIをcurlで実行して、結果を結果を.\outputフォルダにテキスト形式で出力する。
# 出力するファイルは以下。
# ・repository_name.txt　リポジトリ名を出力したファイル
# ・ssh_clone_url.txt　sshでクローンする用のURLを出力したファイル
# ・https_clone_url.txt　HTTPS用でクローンする用のURLを出力したファイル
# ・raw_data.txt　GitHubAPIのJSONレスポンス
# private、publicの可視性問わず、全てのリポジトリを取得する
#
# [事前準備]
# アクセストークンを使用するため、アクセストークンを生成して設定すること。
#
# [参考サイト]
# GitHubのリポジトリを一覧化する（public/private両対応）
# 　https://qiita.com/emergent/items/a557246a0c0bf9d50a11
# GitHub公式 API仕様書
# 　https://docs.github.com/ja/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-a-user
##################################################################>

function fileOutput([string]$outputFileName, [string]$val) {
    New-Item "${C_CURRENT_DIR}\output\${outputFileName}" -ItemType File -Force -Value ${val}
}

# 実行ファイルのフルパスを取得して、そこから3つ上のディレクトリ(toolフォルダパス)を取得する
[string]$toolContextPath = $MyInvocation.MyCommand.Path | Split-Path -Parent | Split-Path -Parent
# インポート
. "${toolContextPath}\conf\GitHub\GitHubApiConf.ps1"
. "${toolContextPath}\conf\GitHub\GitHubConnectionConf.ps1"

# GitHubからリポジトリの一覧を取得する
[string]$mediaType = """Accept: application/vnd.github+json"""
[string]$authorization = """Authorization: Bearer ${C_GITHUB_PERSONAL_ACCESS_TOKEN}"""
[string]$uri = $C_GITHUB_API_BASE_URL + $C_GITHUB_API_URI_GET_USER_REPOS
[string]$curlCmd = "curl -X GET -H ${mediaType} -H ${authorization} ${uri}"
[string]$apiExeResult = Invoke-Expression $curlCmd
[object[]]$resultJson = ConvertFrom-Json $apiExeResult

# 取得した結果からファイルに出力するために、ファイル出力用文字列を作成する。
[System.Text.StringBuilder]$names = New-Object System.Text.StringBuilder
[System.Text.StringBuilder]$sshCloneUrls = New-Object System.Text.StringBuilder
[System.Text.StringBuilder]$httpsCloneUrls = New-Object System.Text.StringBuilder
for([int]$i = 0; $i -lt $resultJson.Count; $i++) {
    $names.Append($resultJson[$i].name)
    $sshCloneUrls.Append($resultJson[$i].ssh_url)
    $httpsCloneUrls.Append($resultJson[$i].clone_url)
    if ($i -ne $resultJson.Count - 1) {
        $names.Append("`r`n")
        $sshCloneUrls.Append("`r`n")
        $httpsCloneUrls.Append("`r`n")
    }
}

# ファイル出力
Set-Variable -Option Constant -Name C_CURRENT_DIR -Value ($MyInvocation.MyCommand.Path | Split-Path -Parent)
fileOutput "repository_name.txt" $names.ToString()
fileOutput "ssh_clone_url.txt" $sshCloneUrls.ToString()
fileOutput "https_clone_url.txt" $httpsCloneUrls.ToString()
fileOutput "raw_data.txt" $apiExeResult # TODO: JSONを整形してファイル出力したい。(jqコマンドを使えばできる？)