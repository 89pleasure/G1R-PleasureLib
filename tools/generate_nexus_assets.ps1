param(
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\assets\nexus")
)

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Add-Type -AssemblyName System.Drawing

function New-Canvas([int]$Width, [int]$Height) {
    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    return @($bitmap, $graphics)
}

function Draw-RoundedRect($Graphics, $Brush, [float]$X, [float]$Y, [float]$Width, [float]$Height, [float]$Radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $Radius * 2
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    $Graphics.FillPath($Brush, $path)
    $path.Dispose()
}

function Draw-LineText($Graphics, [string]$Text, $Font, $Brush, [float]$X, [float]$Y) {
    $Graphics.DrawString($Text, $Font, $Brush, [System.Drawing.PointF]::new($X, $Y))
}

function Draw-Grid($Graphics, [int]$Width, [int]$Height, [int]$Step, [int]$Alpha) {
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb($Alpha, 255, 255, 255)), 1
    for ($x = 0; $x -le $Width; $x += $Step) {
        $Graphics.DrawLine($pen, $x, 0, $x, $Height)
    }
    for ($y = 0; $y -le $Height; $y += $Step) {
        $Graphics.DrawLine($pen, 0, $y, $Width, $y)
    }
    $pen.Dispose()
}

function Draw-Background($Graphics, [int]$Width, [int]$Height) {
    $rect = [System.Drawing.Rectangle]::new(0, 0, $Width, $Height)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(18, 24, 28)), ([System.Drawing.Color]::FromArgb(33, 38, 42)), 18
    $Graphics.FillRectangle($brush, $rect)
    $brush.Dispose()

    Draw-Grid $Graphics $Width $Height 48 14

    $accentPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(150, 82, 184, 142)), 5
    $Graphics.DrawLine($accentPen, 0, $Height - 26, $Width, $Height - 68)
    $accentPen.Dispose()

    $goldPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(135, 219, 166, 79)), 3
    $Graphics.DrawLine($goldPen, 0, 34, $Width, 96)
    $goldPen.Dispose()
}

function Save-Png($Bitmap, $Graphics, [string]$Path) {
    $Graphics.Dispose()
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Bitmap.Dispose()
}

$fontTitle = New-Object System.Drawing.Font "Segoe UI Semibold", 66, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fontTitleSmall = New-Object System.Drawing.Font "Segoe UI Semibold", 52, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fontSub = New-Object System.Drawing.Font "Segoe UI", 25, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fontBody = New-Object System.Drawing.Font "Segoe UI", 22, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fontMono = New-Object System.Drawing.Font "Consolas", 21, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fontMonoBig = New-Object System.Drawing.Font "Consolas", 28, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)

$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245, 248, 247))
$muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(190, 203, 199))
$green = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(92, 207, 154))
$gold = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(224, 174, 91))
$panel = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(188, 12, 16, 18))
$panel2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(205, 24, 29, 31))
$chip = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(225, 36, 48, 48))

$pair = New-Canvas 1300 372
$bitmap = $pair[0]
$graphics = $pair[1]
Draw-Background $graphics 1300 372
Draw-LineText $graphics "PleasureLib" $fontTitle $white 72 76
Draw-LineText $graphics "Shared UE4SS Lua helpers for Gothic 1 Remake mods" $fontSub $muted 78 166
Draw-RoundedRect $graphics $panel 774 74 410 188 10
Draw-LineText $graphics "local lib = require(...)" $fontMono $green 815 104
Draw-LineText $graphics "lib:find_object(path)" $fontMono $white 815 142
Draw-LineText $graphics "lib:register_hook(...)" $fontMono $white 815 180
Draw-LineText $graphics "lib:delay_game_thread(...)" $fontMono $gold 815 218
Draw-RoundedRect $graphics $chip 78 245 138 42 8
Draw-LineText $graphics "defensive" $fontBody $white 101 252
Draw-RoundedRect $graphics $chip 232 245 150 42 8
Draw-LineText $graphics "reusable" $fontBody $white 264 252
Draw-RoundedRect $graphics $chip 398 245 125 42 8
Draw-LineText $graphics "small" $fontBody $white 435 252
Save-Png $bitmap $graphics (Join-Path $OutputDir "pleasurelib-header-1300x372.png")

$pair = New-Canvas 1600 900
$bitmap = $pair[0]
$graphics = $pair[1]
Draw-Background $graphics 1600 900
Draw-LineText $graphics "PleasureLib" $fontTitle $white 110 92
Draw-LineText $graphics "A small shared runtime for UE4SS Lua mods" $fontSub $muted 116 184
Draw-RoundedRect $graphics $panel 112 286 560 370 12
Draw-LineText $graphics "What it centralizes" $fontTitleSmall $white 150 326
Draw-LineText $graphics "logging and safe calls" $fontBody $muted 164 422
Draw-LineText $graphics "INI parsing and file IO" $fontBody $muted 164 474
Draw-LineText $graphics "UE object validation" $fontBody $muted 164 526
Draw-LineText $graphics "StaticFindObject fallback cache" $fontBody $muted 164 578
Draw-LineText $graphics "delays and hook registration" $fontBody $muted 164 630
Draw-RoundedRect $graphics $panel2 800 226 610 470 12
Draw-LineText $graphics "local pleasureLib =" $fontMonoBig $green 850 282
Draw-LineText $graphics "  require(""pleasure_lib_loader"").new(MOD)" $fontMonoBig $white 850 328
Draw-LineText $graphics "" $fontMonoBig $white 850 374
Draw-LineText $graphics "pleasureLib:try(fn)" $fontMonoBig $gold 850 420
Draw-LineText $graphics "pleasureLib:find_object(path)" $fontMonoBig $white 850 466
Draw-LineText $graphics "pleasureLib:register_hook(path, fn)" $fontMonoBig $white 850 512
Draw-LineText $graphics "pleasureLib:delay_game_thread(ms, fn)" $fontMonoBig $white 850 558
Draw-LineText $graphics "pleasureLib:parse_ini(text)" $fontMonoBig $white 850 604
Draw-RoundedRect $graphics $chip 114 718 270 48 8
Draw-LineText $graphics "load-order fallback" $fontBody $white 143 728
Draw-RoundedRect $graphics $chip 416 718 204 48 8
Draw-LineText $graphics "idempotent" $fontBody $white 459 728
Draw-RoundedRect $graphics $chip 652 718 184 48 8
Draw-LineText $graphics "Lua only" $fontBody $white 704 728
Save-Png $bitmap $graphics (Join-Path $OutputDir "pleasurelib-gallery-1600x900.png")

$fontTitle.Dispose()
$fontTitleSmall.Dispose()
$fontSub.Dispose()
$fontBody.Dispose()
$fontMono.Dispose()
$fontMonoBig.Dispose()
$white.Dispose()
$muted.Dispose()
$green.Dispose()
$gold.Dispose()
$panel.Dispose()
$panel2.Dispose()
$chip.Dispose()

Get-ChildItem -LiteralPath $OutputDir -File -Filter "pleasurelib-*.png" | Select-Object FullName, Length
