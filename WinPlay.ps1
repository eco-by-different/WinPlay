# WinPlay 1.0
# Minimal Windows-only media player for Windows PowerShell 5.1
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$native = @'
using System;
using System.Runtime.InteropServices;
public static class WinPlayNative {
    [DllImport("kernel32.dll")] static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")] static extern uint SetThreadExecutionState(uint esFlags);
    public static void HideConsole() { IntPtr h = GetConsoleWindow(); if (h != IntPtr.Zero) ShowWindow(h, 0); }
    public static void KeepAwake(bool active) { SetThreadExecutionState(active ? 0x80000003u : 0x80000000u); }
}
'@
Add-Type -TypeDefinition $native -Language CSharp
[WinPlayNative]::HideConsole()
[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinPlay 1.0 - powered by Windows" Width="760" Height="500"
        MinWidth="520" MinHeight="340" WindowStartupLocation="CenterScreen"
        Background="#0B0E13" Foreground="#F2F2F2" FontFamily="Segoe UI" FontSize="12">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Foreground" Value="#F2F2F2"/>
            <Setter Property="Background" Value="#202530"/>
            <Setter Property="BorderBrush" Value="#566174"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,6"/>
            <Setter Property="Margin" Value="0,0,6,0"/>
            <Setter Property="MinWidth" Value="86"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="ButtonBorder" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ButtonBorder" Property="Background" Value="#2B3442"/>
                                <Setter TargetName="ButtonBorder" Property="BorderBrush" Value="#2F80D0"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="ButtonBorder" Property="Background" Value="#1476D4"/>
                                <Setter TargetName="ButtonBorder" Property="BorderBrush" Value="#76B7F2"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="Slider">
            <Setter Property="Foreground" Value="#1476D4"/>
        </Style>
    </Window.Resources>
    <Grid x:Name="Root" Margin="14" AllowDrop="True">
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Border x:Name="VideoBorder" Background="Black" MinHeight="180">
            <Grid>
                <MediaElement x:Name="Player" LoadedBehavior="Manual" UnloadedBehavior="Manual"
                              Stretch="Uniform" ScrubbingEnabled="True" Volume="0.70"/>
                <TextBlock x:Name="DropHint" Text="DROP MEDIA HERE" Foreground="#F1C232"
                           FontSize="16" FontWeight="SemiBold" HorizontalAlignment="Center"
                           VerticalAlignment="Center" IsHitTestVisible="False"/>
            </Grid>
        </Border>
        <Grid x:Name="TimelinePanel" Grid.Row="1" Margin="0,10,0,5">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="48"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="48"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="CurrentTime" Text="00:00" VerticalAlignment="Center"/>
            <Slider x:Name="Timeline" Grid.Column="1"
                    Margin="8,0" IsMoveToPointEnabled="True" Focusable="False"/>
            <TextBlock x:Name="TotalTime" Grid.Column="2" Text="00:00"
                       HorizontalAlignment="Right" VerticalAlignment="Center"/>
        </Grid>
        <Grid x:Name="Controls" Grid.Row="2" Margin="0,3,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="110"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="OpenButton" Content="OPEN"/>
            <Button x:Name="PlayButton" Grid.Column="1" Content="PLAY"/>
            <Button x:Name="StopButton" Grid.Column="2" Content="STOP"/>
            <TextBlock Grid.Column="4" Text="VOL" Margin="8,0,8,0" VerticalAlignment="Center"/>
            <Slider x:Name="Volume" Grid.Column="5" Minimum="0" Maximum="1" Value="0.70"
                    VerticalAlignment="Center" Focusable="False"/>
        </Grid>
        <TextBlock x:Name="Status" Grid.Row="3" Text="Ready. Drop a file or click Open."
                   Foreground="#B8C4D8" FontStyle="Italic" Margin="2,10,0,0"/>
    </Grid>
</Window>
'@
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
'Root','VideoBorder','Player','DropHint','TimelinePanel','Timeline','CurrentTime','TotalTime','Controls','OpenButton','PlayButton','StopButton','Volume','Status' | ForEach-Object {
    Set-Variable -Name $_ -Value $window.FindName($_)
}
$state = @{ Loaded=$false; Playing=$false; Seeking=$false; Fullscreen=$false
    OldState=$null; LastVolume=0.70; PauseWhenOpened=$false }
function Format-Time([TimeSpan]$time) {
    if ($time.TotalHours -ge 1) { '{0}:{1:00}:{2:00}' -f [int]$time.TotalHours, $time.Minutes, $time.Seconds }
    else { '{0:00}:{1:00}' -f [int]$time.TotalMinutes, $time.Seconds }
}
function Set-Playing([bool]$value) {
    $state.Playing = $value
    $PlayButton.Content = if ($value) { 'PAUSE' } else { 'PLAY' }
    [WinPlayNative]::KeepAwake($value)
}
function Open-Media([string]$path) {
    if (-not [IO.File]::Exists($path)) { return }
    try {
        $Player.Stop()
        $Player.Close()
        $Player.Source = $null
        Set-Playing $false
        $state.Loaded = $false
        $state.PauseWhenOpened = $true
        $Timeline.Value = 0
        $Timeline.Maximum = 1
        $CurrentTime.Text = '00:00'
        $TotalTime.Text = '00:00'
        $DropHint.Visibility = 'Visible'
        $DropHint.Text = 'LOADING...'
        $Status.Text = 'Loading: ' + [IO.Path]::GetFileName($path)
        $Player.Source = [Uri]$path
        $Player.Play()
    }
    catch {
        $state.Loaded = $false
        $state.PauseWhenOpened = $false
        $DropHint.Text = 'DROP MEDIA HERE'
        $Status.Text = 'Unable to open the selected file.'
    }
}
function Toggle-Play {
    if (-not $state.Loaded) { return }
    if ($state.Playing) {
        $Player.Pause()
        Set-Playing $false
        $Status.Text = 'Paused.'
    } else {
        $Player.Play()
        Set-Playing $true
        $Status.Text = 'Playing.'
    }
}
function Stop-Media {
    if (-not $state.Loaded) { return }
    $Player.Stop()
    $Player.Position = [TimeSpan]::Zero
    $Timeline.Value = 0
    $CurrentTime.Text = '00:00'
    Set-Playing $false
    $Status.Text = 'Stopped.'
}
function Seek-By([double]$seconds) {
    if (-not $state.Loaded) { return }
    $target = [Math]::Max(0, [Math]::Min($Timeline.Maximum, $Player.Position.TotalSeconds + $seconds))
    $Player.Position = [TimeSpan]::FromSeconds($target)
}
function Toggle-Mute {
    if ($Volume.Value -gt 0) {
        $state.LastVolume = $Volume.Value
        $Volume.Value = 0
    } else {
        $Volume.Value = $state.LastVolume
    }
}
function Toggle-Fullscreen {
    if (-not $state.Fullscreen) {
        $state.OldState = $window.WindowState
        $window.WindowState = 'Normal'
        $window.WindowStyle = 'None'
        $window.ResizeMode = 'NoResize'
        $Root.Margin = 0
        $TimelinePanel.Visibility = 'Collapsed'
        $Controls.Visibility = 'Collapsed'
        $Status.Visibility = 'Collapsed'
        $window.WindowState = 'Maximized'
        [Windows.Input.Mouse]::OverrideCursor = [Windows.Input.Cursors]::None
        $state.Fullscreen = $true
    } else {
        $window.WindowState = 'Normal'
        $window.WindowStyle = 'SingleBorderWindow'
        $window.ResizeMode = 'CanResize'
        $Root.Margin = 14
        $TimelinePanel.Visibility = 'Visible'
        $Controls.Visibility = 'Visible'
        $Status.Visibility = 'Visible'
        $window.WindowState = $state.OldState
        [Windows.Input.Mouse]::OverrideCursor = $null
        $state.Fullscreen = $false
    }
}
$OpenButton.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Title = 'Open media'
    $dialog.Filter = 'Media files|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.m4v;*.mp3;*.wav;*.wma;*.m4a;*.aac;*.flac|All files|*.*'
    if ($dialog.ShowDialog($window)) { Open-Media $dialog.FileName }
})
$PlayButton.Add_Click({ Toggle-Play })
$StopButton.Add_Click({ Stop-Media })
$Player.Volume = $Volume.Value
$Volume.Add_ValueChanged({ $Player.Volume = $Volume.Value })
$Root.Add_PreviewDragOver({
    param($sender, $e)
    $e.Effects = if ($e.Data.GetDataPresent([Windows.DataFormats]::FileDrop)) { 'Copy' } else { 'None' }
    $e.Handled = $true
})
$Root.Add_Drop({
    param($sender, $e)
    $files = $e.Data.GetData([Windows.DataFormats]::FileDrop)
    if ($files -and -not [IO.Directory]::Exists($files[0])) { Open-Media $files[0] }
})
$Player.Add_MediaOpened({
    $state.Loaded = $true
    if ($state.PauseWhenOpened) {
        $Player.Pause()
        $Player.Position = [TimeSpan]::Zero
        $state.PauseWhenOpened = $false
    }
    $hasVideo = $Player.NaturalVideoWidth -gt 0 -and $Player.NaturalVideoHeight -gt 0
    $fileName = [IO.Path]::GetFileName($Player.Source.LocalPath)
    if ($hasVideo) {
        $DropHint.Visibility = 'Collapsed'
    } else {
        $DropHint.Text = 'AUDIO  |  ' + $fileName
        $DropHint.Visibility = 'Visible'
    }
    if ($Player.NaturalDuration.HasTimeSpan) {
        $Timeline.Maximum = $Player.NaturalDuration.TimeSpan.TotalSeconds
        $TotalTime.Text = Format-Time $Player.NaturalDuration.TimeSpan
    }
    $Status.Text = if ($hasVideo) { 'Ready: ' + $fileName } else { 'Ready (audio): ' + $fileName }
})
$Player.Add_MediaEnded({
    $Player.Stop()
    $Timeline.Value = 0
    $CurrentTime.Text = '00:00'
    Set-Playing $false
    $Status.Text = 'Finished.'
})
$Player.Add_MediaFailed({
    param($sender, $e)
    $state.Loaded = $false
    $state.PauseWhenOpened = $false
    Set-Playing $false
    $DropHint.Text = 'DROP MEDIA HERE'
    $DropHint.Visibility = 'Visible'
    $Status.Text = 'Windows could not play this media: ' + $e.ErrorException.Message
})
$Timeline.Add_PreviewMouseLeftButtonDown({ $state.Seeking = $true })
$Timeline.Add_PreviewMouseLeftButtonUp({
    if ($state.Loaded) { $Player.Position = [TimeSpan]::FromSeconds($Timeline.Value) }; $state.Seeking = $false
})
$VideoBorder.Add_MouseLeftButtonDown({ param($sender, $e); if ($e.ClickCount -eq 2) { Toggle-Fullscreen } })
$keyHandler = [Windows.Input.KeyEventHandler]{
    param($sender, $e)
    switch ($e.Key) {
        ([Windows.Input.Key]::Space) { Toggle-Play; $e.Handled = $true }
        ([Windows.Input.Key]::Left)  { Seek-By -5; $e.Handled = $true }
        ([Windows.Input.Key]::Right) { Seek-By 5; $e.Handled = $true }
        ([Windows.Input.Key]::Up)    { $Player.Volume = [Math]::Min(1.0, $Player.Volume + 0.05); $Volume.Value = $Player.Volume; $e.Handled = $true }
        ([Windows.Input.Key]::Down)  { $Player.Volume = [Math]::Max(0.0, $Player.Volume - 0.05); $Volume.Value = $Player.Volume; $e.Handled = $true }
        ([Windows.Input.Key]::M)     { Toggle-Mute; $e.Handled = $true }
        ([Windows.Input.Key]::F11)   { Toggle-Fullscreen; $e.Handled = $true }
        ([Windows.Input.Key]::Escape) { if ($state.Fullscreen) { Toggle-Fullscreen; $e.Handled = $true } }
        ([Windows.Input.Key]::O) { if ([Windows.Input.Keyboard]::Modifiers -band [Windows.Input.ModifierKeys]::Control) { $OpenButton.RaiseEvent((New-Object Windows.RoutedEventArgs([Windows.Controls.Button]::ClickEvent))); $e.Handled = $true } }
        { $_ -eq [Windows.Input.Key]::PageUp -or $_ -eq [Windows.Input.Key]::PageDown } { $e.Handled = $true }
    }
}
$window.AddHandler([Windows.Input.Keyboard]::PreviewKeyDownEvent, $keyHandler, $true)
$timer = New-Object Windows.Threading.DispatcherTimer -Property @{ Interval=[TimeSpan]::FromMilliseconds(250) }
$timer.Add_Tick({
    if ($state.Loaded -and -not $state.Seeking) {
        $Timeline.Value = [Math]::Min($Timeline.Maximum, $Player.Position.TotalSeconds)
        $CurrentTime.Text = Format-Time $Player.Position
    }
})
$timer.Start()
$window.Add_Closed({
    [Windows.Input.Mouse]::OverrideCursor = $null
    $timer.Stop()
    $Player.Close()
    [WinPlayNative]::KeepAwake($false)
})
[void]$window.ShowDialog()