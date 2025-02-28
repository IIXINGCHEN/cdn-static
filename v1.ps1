<#
.SYNOPSIS
    Windows 系统垃圾清理脚本 (生产环境版本)

.DESCRIPTION
    此 PowerShell 脚本旨在安全高效地清理 Windows 系统垃圾，提供多种清理选项，
    包括常用系统垃圾清理、腾讯软件垃圾专清和深度核心垃圾清理。

.NOTES
    文件名: SystemCleanup_V2025.3.1.ps1
    版本号: 2025.3.1
    维护人员: AI Full Stack Development Assistant
    更新日期: 2025-03-01
    编码: UTF-8 (PowerShell 脚本推荐使用 UTF-8 编码)

.LINK
    https://example.com (可替换为脚本相关文档或链接)

.SECURITY
    * 脚本需要管理员权限才能完整执行。
    * 深度核心垃圾清理选项具有较高风险，请谨慎使用。
    * 文件删除操作不可逆，请仔细检查清理选项和路径。
    * 建议在运行脚本前备份重要数据。
    * 脚本专为 Windows 10 及以上版本设计，其他版本可能存在兼容性问题。

.CAUTION
    请仔细阅读脚本说明和安全提示，谨慎操作！
#>

# 设置脚本为严格模式，有助于发现潜在错误
Set-StrictMode -Version Latest

# 定义脚本版本号
$ScriptVersion = "2025.3.1"

# 设置控制台标题和颜色
$Host.UI.RawUI.WindowTitle = "Windows System Cleanup Script (V$ScriptVersion)"
Write-Host "欢迎使用 Windows 系统垃圾清理脚本 (版本: $ScriptVersion)" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------" -ForegroundColor Green
Write-Host "程序目录: $(Get-Location)" -ForegroundColor Green

# 检查是否以管理员权限运行
function Is-Admin {
    # 检查当前用户是否属于管理员组
    ([Security.Principal.WindowsPrincipal]::Current -as [Security.Principal.WindowsPrincipal] ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Is-Admin)) {
    Write-Host "权限不足：本脚本需要管理员权限才能完整运行。" -ForegroundColor Red
    Write-Host "--------------------------------------------------------------------" -ForegroundColor Red
    Write-Host "尝试请求管理员权限..." -ForegroundColor Yellow
    # 使用 PowerShell 重新以管理员权限启动自身
    Start-Process -FilePath PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    return  # 退出当前脚本
}

Write-Host "管理员权限: 已获取" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------" -ForegroundColor Green
Write-Host "本脚本专为 Windows 10 及以上版本设计，旨在安全高效地清理系统垃圾。" -ForegroundColor Green
Write-Host "请仔细阅读选项说明，谨慎操作！" -ForegroundColor Yellow
Write-Host "" # 空行
Write-Host "今天是: $(Get-Date -Format "yyyy-MM-dd")  现在时刻: $(Get-Date -Format "HH:mm:ss")" -ForegroundColor Gray
Write-Host "" # 空行

# ----------------------------------------------------------------------------------
# 函数定义
# ----------------------------------------------------------------------------------

function Delete-Directory {
    param(
        [string]$DirPath,
        [string]$ErrorMessage = "删除目录失败"
    )
    Write-Host "删除目录: $DirPath" -ForegroundColor DarkGray # 输出操作日志
    try {
        Remove-Item -Path $DirPath -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable dirError
        if ($dirError) {
            # 使用字符串内插
            Write-Warning "$ErrorMessage: ${dirError.Exception.Message}"
        }
    }
}

function Delete-Files {
    param(
        [string]$FilePath,
        [string]$ErrorMessage = "删除文件失败"
    )
    Write-Host "删除文件: $FilePath" -ForegroundColor DarkGray # 输出操作日志
    try {
        Get-ChildItem -Path $FilePath -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue -ErrorVariable fileError
        if ($fileError) {
            # 使用字符串内插
            Write-Warning "$ErrorMessage: ${fileError.Exception.Message}"
        }
    }
}

function Stop-ProcessByName {
    param(
        [string]$ProcessName,
        [string]$ErrorMessage = "结束进程失败"
    )
    try {
        Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue -ErrorVariable processError
        if ($processError) {
            # 使用字符串内插
            Write-Warning "$ErrorMessage: ${processError.Exception.Message}"
        }
    }
    catch {
        # 使用 String Format 运算符 (-f) 修复 Write-Warning ("{0}: {1}" -f $ErrorMessage, $_.Exception.Message)
    }
}

function Cleanup-Exit {
    param(
        [string]$Message
    )
    Write-Host "" # 空行
    Write-Host "$Message........" -ForegroundColor Green
    Write-Host "" # 空行
    Write-Host "本脚本 5 秒后自动关闭..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    exit
}

function Cleanup-Exit-NoMessage {
    Write-Host "" # 空行
    Write-Host "本脚本 5 秒后自动关闭..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    exit
}

# ----------------------------------------------------------------------------------
# 主菜单和选项处理
# ----------------------------------------------------------------------------------

:Menu_Start

Write-Host "" # 空行
Write-Host "请选择要执行的清理操作：" -ForegroundColor Cyan
Write-Host "" # 空行
Write-Host " (1) 清理常用系统垃圾 (安全、快速)" -ForegroundColor Cyan
Write-Host " (2) 专清腾讯软件垃圾 (针对腾讯 QQ, 微信等)" -ForegroundColor Cyan
Write-Host " (3) 深度核心垃圾清理 (清理更多缓存、日志，<强调>高风险，请谨慎使用!</强调>)" -ForegroundColor Yellow
Write-Host " (4) 退出脚本" -ForegroundColor Cyan
Write-Host "" # 空行

$Input = Read-Host "请选择操作 (1-4)"

switch ($Input) {
    "1" {
        Write-Host "" # 空行
        Write-Host "正在执行常用系统垃圾清理，请稍候..." -ForegroundColor Green
        Write-Host "--------------------------------------------------------------------" -ForegroundColor Green
        Write-Host "清理类型: 常用系统垃圾 (安全、快速)" -ForegroundColor Green

        # 删除补丁备份目录
        Delete-Directory -DirPath "$env:windir\$hf_mig$" -ErrorMessage "删除补丁备份目录失败"
        # 删除补丁卸载文件夹
        Get-ChildItem -Path "$env:windir\$NtUninstall*" -Directory | ForEach-Object {
            Delete-Directory -DirPath $_.FullName -ErrorMessage "删除补丁卸载文件夹失败")
        }

        # 删除临时文件和日志文件
        Delete-Files -FilePath "$env:SystemDrive\*.tmp"
        Delete-Files -FilePath "$env:SystemDrive\*._mp"
        Delete-Files -FilePath "$env:SystemDrive\*.log"
        Delete-Files -FilePath "$env:SystemDrive\*.gid"
        Delete-Files -FilePath "$env:SystemDrive\*.chk"
        Delete-Files -FilePath "$env:SystemDrive\*.old"
        Delete-Files -FilePath "$env:SystemDrive\recycled\*.*"
        Delete-Files -FilePath "$env:windir\*.bak"
        Delete-Files -FilePath "$env:windir\prefetch\*.*"
        Delete-Directory -DirPath "$env:windir\temp" # 删除目录后 PowerShell 会自动重新创建
        New-Item -ItemType Directory -Path "$env:windir\temp" -Force # 重新创建 temp 目录
        Delete-Files -FilePath "$env:UserProfile\cookies\*.*"
        Delete-Files -FilePath "$env:UserProfile\Local Settings\Temporary Internet Files\*.*" # 注意: 'Local Settings' 在较新系统上可能是重定向的
        Delete-Files -FilePath "$env:UserProfile\Local Settings\Temp\*.*" # 注意: 'Local Settings' 在较新系统上上可能是重定向的
        Delete-Files -FilePath "$env:LocalAppData\Temp\*.*"
        Delete-Files -FilePath "$env:UserProfile\Recent\*.*"

        Cleanup-Exit "常用系统垃圾清理完毕"
        break
    }
    "2" {
        Write-Host "" # 空行
        Write-Host "正在执行腾讯软件垃圾专清，请稍候..." -ForegroundColor Green
        Write-Host "--------------------------------------------------------------------" -ForegroundColor Green
        Write-Host "清理类型: 腾讯软件垃圾专清 (针对腾讯 QQ, 微信等)" -ForegroundColor Green

        # 结束腾讯相关进程 (尝试结束，忽略错误)
        Stop-ProcessByName -ProcessName "Tencent TenioDL for Game.exe"
        Stop-ProcessByName -ProcessName "QQMicroGameBoxTray.exe"
        Stop-ProcessByName -ProcessName "QQMicroGameBoxService.exe"

        # 删除腾讯软件垃圾文件
        Delete-Files -FilePath "$env:UserProfile\AppData\Roaming\Tencent\QQMGBDownload\*.*"
        Delete-Files -FilePath "$env:LocalAppData\Tencent\Cross\*.*"
        Delete-Files -FilePath "$env:UserProfile\AppData\Roaming\Tencent\QQMicroGameBox\*.*"
        Delete-Files -FilePath "$env:UserProfile\AppData\Roaming\Tencent\QQMiniGameBox\*.*"
        Delete-Files -FilePath "$env:UserProfile\AppData\Roaming\Tencent\QQMiniDL\*.*"
        Delete-Files -FilePath "$env:UserProfile\AppData\Roaming\Tencent\游戏人生cross\*.*"
        Delete-Files -FilePath "$env:LocalAppData\Tencent\QQPet\*.*"
        # 注意: Program Files 路径可能需要根据实际安装路径调整
        # 可以使用 Get-Item "HKLM:\SOFTWARE\Tencent\QQMicroGameBoxService" | Get-ItemProperty | Select-Object InstallPath 命令来获取安装路径
        # 如果无法获取安装路径，请手动修改以下路径
        Delete-Files -FilePath "C:\Program Files (x86)\Tencent\QQMicroGameBoxService\*.*"
        Delete-Files -FilePath "$env:UserProfile\Roaming\Tencent\Logs\*.*" # 注意: Roaming 路径可能与 AppData\Roaming 相同，取决于系统配置
        Delete-Files -FilePath "$env:UserProfile\AppData\Roaming\Tencent\QQGAMETempest\Download\*.*"
        Delete-Files -FilePath "$env:UserProfile\AppData\Roaming\Tencent\QQ\Temp\*.*"

        Cleanup-Exit "腾讯软件垃圾清理完毕"
        break
    }
    "3" {
        Write-Host "" # 空行
        Write-Host "正在执行深度核心垃圾清理，请稍候... (高风险，请谨慎使用!)" -ForegroundColor Yellow
        Write-Host "--------------------------------------------------------------------" -ForegroundColor Yellow
        Write-Host "清理类型: 深度核心垃圾清理 (<强调>高风险，请谨慎使用!</强调>)" -ForegroundColor Yellow

        # 清空回收站 (使用 PowerShell 命令)
        Write-Host "" # 空行
        Write-Host "正在清空回收站......" -ForegroundColor DarkGray
        Clear-RecycleBin -Confirm:$false

        # 删除临时文件
        Write-Host "" # 空行
        Write-Host "正在删除临时文件......" -ForegroundColor DarkGray
        Delete-Files -FilePath "$env:TEMP\*"
        Delete-Directory -DirPath "$env:TEMP" # 删除目录后 PowerShell 会自动重新创建
        New-Item -ItemType Directory -Path "$env:TEMP" -Force # 重新创建 TEMP 目录

        # 删除最近打开的文档痕迹
        Write-Host "" # 空行
        Write-Host "正在删除最近打开的文档痕迹......" -ForegroundColor DarkGray
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" -Force -ErrorAction SilentlyContinue

        # 删除主流浏览器缓存
        Write-Host "" # 空行
        Write-Host "正在删除主流浏览器缓存......" -ForegroundColor DarkGray

        # Chrome 缓存
        Write-Host "  正在删除 Chrome 缓存......" -ForegroundColor DarkGray
        Delete-Files -FilePath "$env:LocalAppData\Google\Chrome\User Data\Default\Cache\*"
        Delete-Files -FilePath "$env:LocalAppData\Google\Chrome\User Data\Default\Code Cache\*"

        # Firefox 缓存
        Write-Host "  正在删除 Firefox 缓存......" -ForegroundColor DarkGray
        Delete-Files -FilePath "$env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\cache2\entries\*" # 注意: Firefox Profile 路径可能需要动态获取

        # Edge 缓存
        Write-Host "  正在删除 Edge 缓存......" -ForegroundColor DarkGray
        Delete-Files -FilePath "$env:LocalAppData\Microsoft\Edge\User Data\Default\Cache\*"
        Delete-Files -FilePath "$env:LocalAppData\Microsoft\Edge\User Data\Default\Code Cache\*"

        # 删除腾讯软件缓存
        Write-Host "" # 空行
        Write-Host "正在删除腾讯软件缓存......" -ForegroundColor DarkGray

        # QQ 缓存
        Write-Host "  正在删除 QQ 缓存......" -ForegroundColor DarkGray
        Delete-Files -FilePath "$env:APPDATA\Tencent\QQ\Cache\*"

        # 微信缓存
        Write-Host "  正在删除 微信缓存......" -ForegroundColor DarkGray
        Delete-Files -FilePath "$env:APPDATA\Tencent\WeChat\XCache\*"

        # 优化：检查并删除其他临时文件目录
        Write-Host "" # 空行
        Write-Host "正在检查并删除其他临时文件目录......" -ForegroundColor DarkGray
        Delete-Files -FilePath "C:\Windows\Temp\*"
        # 注意: 此路径可能需要更精确的通配符或循环处理，避免删除其他用户的临时文件
        Delete-Files -FilePath "$env:UserProfile\AppData\Local\Temp\*"

        # 优化：清理系统日志文件 (高风险操作，请谨慎使用!)
        Write-Host "" # 空行
        Write-Host "<强调>正在清理系统日志文件 (高风险操作，可能影响系统问题排查!)</强调>......" -ForegroundColor Yellow
        Write-Host "<警告>请注意：清理系统日志文件会删除重要的系统事件记录，可能影响故障排查和安全审计。强烈建议仅在必要时使用此选项，并确保您了解潜在的风险。</警告>" -ForegroundColor Red
        Get-EventLog -LogName * -ErrorAction SilentlyContinue | ForEach-Object {
            wevtutil cl "$($_.Log)"
        }

        # 优化：清理系统更新缓存 (DISM 组件清理)
        Write-Host "" # 空行
        Write-Host "正在清理系统更新缓存 (DISM 组件清理)......" -ForegroundColor DarkGray
        dism /online /cleanup-image /startcomponentcleanup

        Cleanup-Exit "深度核心垃圾清理完毕"
        break
    }
    "4" {
        Cleanup-Exit-NoMessage # 退出脚本，不显示清理完成消息
        break
    }
    default {
        Write-Host "无效的选项，请选择 1, 2, 3 或 4。" -ForegroundColor Red
        Start-Sleep -Seconds 2
        goto Menu_Start # 返回主菜单
    }
}

# ----------------------------------------------------------------------------------
# 脚本结束
# ----------------------------------------------------------------------------------