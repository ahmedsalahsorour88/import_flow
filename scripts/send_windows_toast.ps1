param(
    [string]$Title = "ImportFlow ERP",
    [string]$Message = "Alert Notification",
    [string]$Urgency = "High"
)

try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $textNodes = $template.GetElementsByTagName("text")
    $textNodes.Item(0).AppendChild($template.CreateTextNode($Title)) | Out-Null
    $textNodes.Item(1).AppendChild($template.CreateTextNode($Message)) | Out-Null
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("ImportFlow ERP")
    $notification = [Windows.UI.Notifications.ToastNotification]::new($template)
    $notifier.Show($notification)
    Write-Output "TOAST_SUCCESS"
} catch {
    # Fallback to System.Windows.Forms Balloon if WinRT toast is unavailable
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.SystemIcons]::Warning
        $notify.BalloonTipTitle = $Title
        $notify.BalloonTipText = $Message
        $notify.Visible = $True
        $notify.ShowBalloonTip(5000)
        Start-Sleep -Milliseconds 500
        $notify.Dispose()
        Write-Output "BALLOON_SUCCESS"
    } catch {
        Write-Output "TOAST_FAILED: $_"
    }
}
