# Focused asset checks. Run with PowerShell 7 on Windows after mask generation.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$resourceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$catalogText = [System.IO.File]::ReadAllText((Join-Path $resourceRoot 'html/foil-samples.js'))
$catalog = $catalogText.Substring($catalogText.IndexOf('{')).Trim().TrimEnd(';') | ConvertFrom-Json
$largestLevelCount = 0
foreach ($entry in $catalog.cards.PSObject.Properties) {
    $sourcePath = Join-Path $resourceRoot ('html/images/cards/' + $entry.Name)
    if ((Get-FileHash -LiteralPath $sourcePath).Hash -ne $entry.Value.sourceSha256) { throw "Stale mask/source changed: $($entry.Name)" }
    $source = [System.Drawing.Bitmap]::new($sourcePath)
    $dark = [System.Drawing.Bitmap]::new((Join-Path $resourceRoot ('html/' + $entry.Value.DARK)))
    $light = [System.Drawing.Bitmap]::new((Join-Path $resourceRoot ('html/' + $entry.Value.LIGHT)))
    try {
        if ($dark.Width -ne $light.Width -or $dark.Height -ne $light.Height) { throw 'Mask dimensions disagree' }
        $darkWeight = 0.0; $lightWeight = 0.0; $darkBrightness = 0.0; $lightBrightness = 0.0
        $alphaLevels = [System.Collections.Generic.HashSet[int]]::new()
        for ($y = 0; $y -lt $dark.Height; $y += 2) {
            for ($x = 0; $x -lt $dark.Width; $x += 2) {
                $d = $dark.GetPixel($x, $y).A
                $l = $light.GetPixel($x, $y).A
                if ($d + $l -gt [Math]::Ceiling(255 * $catalog.settings.intensity) + 1) { throw 'Mask complement/intensity exceeds its bound' }
                # Header, lower rules text and outer edge must remain completely unfoiled.
                if (($y -lt $dark.Height * 0.09 -or $y -gt $dark.Height * 0.66 -or $x -lt $dark.Width * 0.07 -or $x -gt $dark.Width * 0.94) -and ($d + $l -ne 0)) { throw 'Mask leaks outside artwork' }
                if ($d + $l -eq 0) { continue }
                [void]$alphaLevels.Add($d)
                $sx = [Math]::Min($source.Width - 1, [int](($x + 0.5) * $source.Width / $dark.Width))
                $sy = [Math]::Min($source.Height - 1, [int](($y + 0.5) * $source.Height / $dark.Height))
                $pixel = $source.GetPixel($sx, $sy)
                $brightness = (0.2126 * $pixel.R + 0.7152 * $pixel.G + 0.0722 * $pixel.B) / 255.0
                $darkWeight += $d; $lightWeight += $l
                $darkBrightness += $brightness * $d; $lightBrightness += $brightness * $l
            }
        }
        if ($darkWeight -eq 0 -or $lightWeight -eq 0) { throw 'Sample lacks DARK or LIGHT coverage' }
        $darkMean = $darkBrightness / $darkWeight
        $lightMean = $lightBrightness / $lightWeight
        if ($darkMean -ge $lightMean) { throw 'DARK/LIGHT luminance preference is reversed' }
        # Flat/bright placeholder art can legitimately have very few transition pixels.
        $largestLevelCount = [Math]::Max($largestLevelCount, $alphaLevels.Count)
        Write-Output ('PASS {0}: DARK brightness {1:N3} < LIGHT {2:N3}; {3} alpha levels; artwork and text bounds preserved' -f $entry.Name, $darkMean, $lightMean, $alphaLevels.Count)
    } finally { $source.Dispose(); $dark.Dispose(); $light.Dispose() }
}
if ($largestLevelCount -lt 128) { throw 'Sample set does not demonstrate smooth intensity transitions' }
