# Windows development-time generator; uses built-in System.Drawing, not gameplay Canvas.
[CmdletBinding()]
param(
    [ValidateRange(0.0, 1.0)][double]$Threshold = 0.45,
    [ValidateRange(0.001, 1.0)][double]$Softness = 0.30,
    [ValidateRange(0.0, 1.0)][double]$Intensity = 1.0,
    [ValidateRange(128, 768)][int]$Width = 384
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$resourceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$settings = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'foil-samples.json') -Raw | ConvertFrom-Json
foreach ($settingName in @('Threshold', 'Softness', 'Intensity', 'Width')) {
    if (-not $PSBoundParameters.ContainsKey($settingName)) {
        Set-Variable -Name $settingName -Value $settings.($settingName.ToLowerInvariant())
    }
}
if ($Threshold -lt 0 -or $Threshold -gt 1 -or $Softness -le 0 -or $Softness -gt 1 -or $Intensity -lt 0 -or $Intensity -gt 1 -or $Width -lt 128 -or $Width -gt 768) {
    throw 'Invalid mask settings in foil-samples.json'
}
if ($settings.samples.Count -gt 8) { throw 'Sample-only generator: at most eight explicitly selected cards.' }
if ($settings.artworkPolygon.Count -lt 3) { throw 'Artwork polygon needs at least three points.' }
foreach ($point in $settings.artworkPolygon) {
    if ($point.Count -ne 2 -or $point[0] -lt 0 -or $point[0] -gt 1 -or $point[1] -lt 0 -or $point[1] -gt 1) { throw 'Invalid normalized polygon point.' }
}
$outputDirectory = Join-Path $resourceRoot 'html/images/foil'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$catalog = [ordered]@{}

foreach ($filename in $settings.samples) {
    if ([System.IO.Path]::GetFileName($filename) -ne $filename -or $filename -notmatch '\.png$') { throw 'Samples must be card PNG filenames.' }
    $sourcePath = Join-Path $resourceRoot ('html/images/cards/' + $filename)
    $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    $source = [System.Drawing.Bitmap]::new($sourcePath)
    $height = [int][Math]::Round($Width * $source.Height / $source.Width)
    $art = [System.Drawing.Bitmap]::new($Width, $height)
    $region = [System.Drawing.Bitmap]::new($Width, $height)
    $dark = [System.Drawing.Bitmap]::new($Width, $height)
    $light = [System.Drawing.Bitmap]::new($Width, $height)
    try {
        # Crop to the artwork bounding box before downsampling/analysis; exterior is transparent.
        $points = [System.Drawing.PointF[]]@($settings.artworkPolygon | ForEach-Object { [System.Drawing.PointF]::new($_[0] * $Width, $_[1] * $height) })
        $minX = [int][Math]::Floor(($points.X | Measure-Object -Minimum).Minimum)
        $maxX = [int][Math]::Ceiling(($points.X | Measure-Object -Maximum).Maximum)
        $minY = [int][Math]::Floor(($points.Y | Measure-Object -Minimum).Minimum)
        $maxY = [int][Math]::Ceiling(($points.Y | Measure-Object -Maximum).Maximum)
        $graphics = [System.Drawing.Graphics]::FromImage($art)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $destination = [System.Drawing.RectangleF]::new($minX, $minY, $maxX - $minX, $maxY - $minY)
            $crop = [System.Drawing.RectangleF]::new($minX * $source.Width / $Width, $minY * $source.Height / $height, ($maxX - $minX) * $source.Width / $Width, ($maxY - $minY) * $source.Height / $height)
            $graphics.DrawImage($source, $destination, $crop, [System.Drawing.GraphicsUnit]::Pixel)
        } finally { $graphics.Dispose() }
        $graphics = [System.Drawing.Graphics]::FromImage($region)
        try {
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $graphics.FillPolygon([System.Drawing.Brushes]::White, $points)
        } finally { $graphics.Dispose() }

        for ($y = $minY; $y -lt $maxY; $y++) {
            for ($x = $minX; $x -lt $maxX; $x++) {
                $coverage = $region.GetPixel($x, $y).A / 255.0
                if ($coverage -eq 0) { continue }
                $pixel = $art.GetPixel($x, $y)
                # Weighted sRGB brightness, not physical linear-light luminance. Smoothstep avoids a hard binary edge.
                $luminance = (0.2126 * $pixel.R + 0.7152 * $pixel.G + 0.0722 * $pixel.B) / 255.0
                $t = [Math]::Clamp(($luminance - ($Threshold - $Softness / 2)) / $Softness, 0.0, 1.0)
                $weight = $t * $t * (3 - 2 * $t)
                $alphaScale = 255 * $Intensity * $coverage * $pixel.A / 255.0
                $dark.SetPixel($x, $y, [System.Drawing.Color]::FromArgb([int][Math]::Round($alphaScale * (1 - $weight)), 255, 255, 255))
                $light.SetPixel($x, $y, [System.Drawing.Color]::FromArgb([int][Math]::Round($alphaScale * $weight), 255, 255, 255))
            }
        }
        $stem = [System.IO.Path]::GetFileNameWithoutExtension($filename)
        $dark.Save((Join-Path $outputDirectory ($stem + '.dark.png')), [System.Drawing.Imaging.ImageFormat]::Png)
        $light.Save((Join-Path $outputDirectory ($stem + '.light.png')), [System.Drawing.Imaging.ImageFormat]::Png)
        $catalog[$filename] = [ordered]@{
            DARK = 'images/foil/' + $stem + '.dark.png'
            LIGHT = 'images/foil/' + $stem + '.light.png'
            sourceSha256 = $sourceHash
        }
        if ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -ne $sourceHash) { throw "Original artwork changed: $filename" }
        Write-Output "Generated DARK/LIGHT: $filename (${Width}x${height})"
    } finally {
        $source.Dispose(); $art.Dispose(); $region.Dispose(); $dark.Dispose(); $light.Dispose()
    }
}
$payload = [ordered]@{
    settings = [ordered]@{ threshold = $Threshold; softness = $Softness; intensity = $Intensity; width = $Width; artworkPolygon = $settings.artworkPolygon }
    cards = $catalog
} | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText((Join-Path $resourceRoot 'html/foil-samples.js'), "// Generated by tools/generate-foil-masks.ps1; sample-only cached alpha masks.`nwindow.BSTAR_FOIL_SAMPLES = $payload;`n", [System.Text.UTF8Encoding]::new($false))
