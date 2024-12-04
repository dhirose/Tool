class StandardPrinter {

    StandardPrinter() {
    }

    [void] print([string]$msg) {
        Write-Host "$(Get-Date -Format "[yyyy-MM-d HH:mm:ss.fff]")$msg"
    }

    [void] println([string]$msg) {
        Write-Host "$(Get-Date -Format "[yyyy-MM-d HH:mm:ss.fff]")$msg"
        Write-Host
    }

    [void] br() {
        Write-Host
    }
}