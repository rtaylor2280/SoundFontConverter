# Xenopixel to Proffie Sound Font Converter v1.0
# Converts Xenopixel sound fonts to Proffie format
# Place script in Xenopixel font folder and run

# Sound type mapping table
$soundMapping = @{
    'begindrag' = 'bgndrag'
    'beginlock' = 'bgnlock'
    'beginmelt' = 'bgnmelt'
    'blaster'   = 'blst'
    'clash'     = 'clsh'
    'drag'      = 'drag'
    'enddrag'   = 'enddrag'
    'endlock'   = 'endlock'
    'endmelt'   = 'endmelt'
    'font'      = 'font'
    'force'     = 'force'
    'hum'       = 'hum'
    'in'        = 'in'
    'lock'      = 'lock'
    'melt'      = 'melt'
    'out'       = 'out'
    'preon'     = 'preon'
    'spin'      = 'spin'
    'stab'      = 'stab'
    'swing'     = 'swng'
    'swingh'    = 'swingh'
    'swingl'    = 'swingl'
    'track'     = 'track'
}

# Config file contents
$configIni = @"
# custom settings are required (not optional)
# always include custom ini files in the fontdir

## igniter settings

# hum will start x milliseconds Before ignition/out ends
# the default is 1000 (any value)

	humstart=900

# The volume of the hum sound. Can be 0-16 (or higher if desired), where 0 is muted.
# Default 15 - is no volume change
       volHum=15

# The volume for all effect sounds (entire sound font). Can be 0-24 (or higher if desired), where 0 is muted. Useful for volume matching with other sound fonts that are too loud/quiet.
# Default 16 - is no volume change
      volEff=16


# How fast (degrees per second) we have to swing before a swing effect is
# triggered. Default 250.
        ProffieOSSwingSpeedThreshold=250

# used in conjunction with AccentMaxSwingVolume to modulate fade in/out
# the default is 0.5 (0.01 to 2.0)

	ProffieOSSwingVolumeSharpness=0.7

# AccentMaxSwingVolume determines volume peak of fade in/out modulation
# the default is 2.0 x (1.0 to 3.0)

	ProffieOSMaxSwingVolume=3

# Specify what fraction of swing that must be played before a new swing can be
# started. Can be 0.0-1.0. Defaults to 0.5 (50%).
        ProffieOSSwingOverlap=0.5

# This is used to control the volume of the combined hum and smoothswings
# when an accent swing plays.                       
# Defaults to 0.2 (volume is decreased by 20% of swing volume)    
       ProffieOSSmoothSwingDucking=0.25

# How slow (degrees per second) the swing has to be before it's not considered a
# swing anymore. Default 200.
       ProffieOSSwingLowerThreshold=200

# Only used for non-smoothswing fonts. Specifies how aggressive a swing has to be to be considered a slash. Once we
# reach the ProffieOSSwingSpeedThreshold, rate of swing speed change is used to
# determine if it's a swing or a slash. Default 260

	ProffieOSSlashAccelerationThreshold=280



# If #define ENABLE_SPINS is defined. Number of degrees the blade must travel while staying above the
# swing threshold in order to trigger a spin sound.  Default is 360 or
# one full rotation.

        ProffieOSSpinDegrees=310.0


# Minimum acceleration for Accent Swing file Selection
#recommended value is 20.0 ~ 30.0
       ProffieOSMinSwingAcceleration=20.0


# Maximum acceleration for Accent Swing file Selection
#must be higher than Min value to enable selection
#recommended value is 100.0 ~ 150.0
       ProffieOSMaxSwingAcceleration=100.0
"@

$smoothswIni = @"
# custom settings are required (not optional)
# always include custom ini files in the fontdir

## smoothswing settings

# smoothswing version (should be 1 or 2)

# 1 when smoothsw.ini is not found then fallback to v1
# 2 smoothswing v2 <-- usually select this one!!

	Version=2

# degrees of rotations per second required to reach full volume
# the default is 450.0 (any value)

	SwingSensitivity=450

# smoothswing volume multiplier (defaults to 3x normal volume)
# the default is 3.0 (value between 1 and 5)

	MaxSwingVolume=3

# what percent the hum sound will decrease as swing increases
# the default is 75.0 (value between 1 and 100)

	MaximumHumDucking=80

# Non-linear swing response (higher values make it more non-linear)
# Values greater than 1 will result in the Smoothswing sound staying quieter 
# at lower speeds and then ramping up quickly to full volume a higher speeds. 
# Values less than 1 will result in the Smoothswing volume ramping up quickly 
# at lower speeds and then staying there as you approach full speed. 
# the default is 1.75 (any value)
        SwingSharpness=2

# degrees per second needed to register as a swing
# the default is 20.0 (1 to 360)

	SwingStrengthThreshold=25

# how many degrees the crossover transition between the hi/low smoothswing takes
# the default is 45.0 (1 to 360)

	Transition1Degrees=45

# how many degrees per second until the first transition from hi/low smoothswing occurs
# the default is 160.0 (1 to 360)

	Transition2Degrees=160


# degrees required to trigger an accent swing
# when they are found in the fontdir
# default is 450

	AccentSwingSpeedThreshold=450

# G force required to trigger an accent slsh instead of a swng.
# if no slsh files are found, swng files are played instead.
# If not zero AND accent swings are on, this defines the threshold for when
# a swing is considered a slash. Unit is degrees per second **per second**.
# NOTE - While 260 is the default value, it is subjective. 
# The higher the accent swing threshold, the higher the slash threshold will need to be.
		
	AccentSlashAccelerationThreshold=100
"@

Write-Host "🎯 Xenopixel to Proffie Converter v1.0" -ForegroundColor Cyan
Write-Host "=====================================`n" -ForegroundColor Cyan

# Validate we're in a Xeno font folder
$iniFiles = Get-ChildItem -Path . -Filter "*.ini" -File
if ($iniFiles.Count -eq 0) {
    Write-Host "❌ ERROR: No .ini file found. Make sure you're in a Xenopixel font folder." -ForegroundColor Red
    exit 1
}
if ($iniFiles.Count -gt 1) {
    Write-Host "❌ ERROR: Multiple .ini files found. Expected exactly one." -ForegroundColor Red
    exit 1
}

# Extract font name
$iniContent = Get-Content $iniFiles[0].FullName -Raw
$fontNameMatch = [regex]::Match($iniContent, '^([^=]+)=')
if (-not $fontNameMatch.Success) {
    Write-Host "❌ ERROR: Could not extract font name from $($iniFiles[0].Name)" -ForegroundColor Red
    exit 1
}

$fontName = $fontNameMatch.Groups[1].Value.Trim()
$outputFolderName = $fontName -replace '\s+', '_'

Write-Host "📂 Font Name: $fontName" -ForegroundColor Green
Write-Host "📁 Output Folder: $outputFolderName`n" -ForegroundColor Green

# Check if output folder exists
if (Test-Path $outputFolderName) {
    $response = Read-Host "⚠️  Output folder '$outputFolderName' already exists. Overwrite? (y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "❌ Conversion cancelled." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $outputFolderName -Recurse -Force
}

# Scan WAV files
$wavFiles = Get-ChildItem -Path . -Filter "*.wav" -File
$fileGroups = @{}
$totalFiles = 0
$skippedFiles = @()

Write-Host "🔍 Processing WAV files..." -ForegroundColor Cyan

foreach ($wavFile in $wavFiles) {
    $fileName = $wavFile.BaseName.ToLower()
    
    # Match pattern: soundtype (n)
    $match = [regex]::Match($fileName, '^(.+?)\s+\((\d+)\)$')
    
    if (-not $match.Success) {
        Write-Host "   ⚠️  Skipping: $($wavFile.Name) (doesn't match expected format)" -ForegroundColor Yellow
        $skippedFiles += $wavFile.Name
        continue
    }
    
    $soundType = $match.Groups[1].Value.Trim()
    $number = [int]$match.Groups[2].Value
    
    # Map to Proffie sound type
    $proffieType = $soundMapping[$soundType]
    if (-not $proffieType) {
        Write-Host "   ⚠️  Skipping: $($wavFile.Name) (unknown sound type: $soundType)" -ForegroundColor Yellow
        $skippedFiles += $wavFile.Name
        continue
    }
    
    if (-not $fileGroups.ContainsKey($proffieType)) {
        $fileGroups[$proffieType] = @()
    }
    
    $fileGroups[$proffieType] += @{
        OriginalFile = $wavFile
        Number = $number
        ProffieType = $proffieType
    }
    
    $totalFiles++
}

Write-Host "   ✅ Found $totalFiles valid files in $($fileGroups.Count) sound categories`n" -ForegroundColor Green

if ($skippedFiles.Count -gt 0) {
    Write-Host "⚠️  Skipped files:" -ForegroundColor Yellow
    $skippedFiles | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
    Write-Host ""
}

# Create output structure
Write-Host "🏗️  Creating folder structure..." -ForegroundColor Cyan

New-Item -ItemType Directory -Path $outputFolderName -Force | Out-Null

foreach ($soundType in $fileGroups.Keys) {
    $subfolderPath = Join-Path $outputFolderName $soundType
    New-Item -ItemType Directory -Path $subfolderPath -Force | Out-Null
    Write-Host "   📁 Created: $soundType\" -ForegroundColor Green
}

# Copy and rename files
Write-Host "`n📋 Converting files..." -ForegroundColor Cyan

foreach ($soundType in $fileGroups.Keys | Sort-Object) {
    $files = $fileGroups[$soundType]
    $subfolderPath = Join-Path $outputFolderName $soundType
    
    foreach ($file in $files | Sort-Object Number) {
        $newFileName = "$($soundType)$($file.Number).wav"
        $destinationPath = Join-Path $subfolderPath $newFileName
        
        Copy-Item $file.OriginalFile.FullName $destinationPath
        Write-Host "   ✅ $($file.OriginalFile.Name) → $soundType\$newFileName" -ForegroundColor Green
    }
}

# Handle boot folder (copy font.wav if it exists)
if ($fileGroups.ContainsKey('font')) {
    $bootPath = Join-Path $outputFolderName 'boot'
    New-Item -ItemType Directory -Path $bootPath -Force | Out-Null
    
    $fontFile = $fileGroups['font'] | Sort-Object Number | Select-Object -First 1
    $bootDestination = Join-Path $bootPath 'boot1.wav'
    Copy-Item $fontFile.OriginalFile.FullName $bootDestination
    
    Write-Host "   ✅ Created boot\boot1.wav from $($fontFile.OriginalFile.Name)" -ForegroundColor Green
}

# Create config files
Write-Host "`n⚙️  Creating configuration files..." -ForegroundColor Cyan

$configPath = Join-Path $outputFolderName 'config.ini'
Set-Content -Path $configPath -Value $configIni -Encoding UTF8
Write-Host "   ✅ Created: config.ini" -ForegroundColor Green

# Create smoothsw.ini if swing variants exist
$needsSmoothsw = $fileGroups.ContainsKey('swingl') -or $fileGroups.ContainsKey('swingh')
if ($needsSmoothsw) {
    $smoothswPath = Join-Path $outputFolderName 'smoothsw.ini'
    Set-Content -Path $smoothswPath -Value $smoothswIni -Encoding UTF8
    Write-Host "   ✅ Created: smoothsw.ini (swing variants detected)" -ForegroundColor Green
}

# Handle readme.txt
Write-Host "`n📝 Creating readme.txt..." -ForegroundColor Cyan

$existingTxtFiles = Get-ChildItem -Path . -Filter "*.txt" -File
$existingContent = ""

if ($existingTxtFiles.Count -gt 0) {
    # Use content from first txt file found
    $existingContent = Get-Content $existingTxtFiles[0].FullName -Raw
    Write-Host "   📖 Found existing: $($existingTxtFiles[0].Name)" -ForegroundColor Green
}

# Generate conversion summary
$conversionSummary = @"


=====================================
CONVERSION SUMMARY
=====================================
Converted: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source: Xenopixel font
Target: Proffie format
Font Name: $fontName
Original .ini file: $($iniFiles[0].Name)

Files Converted: $totalFiles
Sound Categories: $($fileGroups.Count)

Sound Type Breakdown:
"@

foreach ($soundType in $fileGroups.Keys | Sort-Object) {
    $count = $fileGroups[$soundType].Count
    $conversionSummary += "`n  - $soundType`: $count files"
}

if ($skippedFiles.Count -gt 0) {
    $conversionSummary += "`n`nSkipped Files ($($skippedFiles.Count)):"
    foreach ($skipped in $skippedFiles) {
        $conversionSummary += "`n  - $skipped"
    }
}

$conversionSummary += "`n`nConfiguration Files Created:"
$conversionSummary += "`n  - config.ini"
if ($needsSmoothsw) {
    $conversionSummary += "`n  - smoothsw.ini"
}

$conversionSummary += "`n`nConverter: Xenopixel to Proffie v1.0"
$conversionSummary += "`n====================================="

$finalContent = $existingContent + $conversionSummary
$readmePath = Join-Path $outputFolderName 'readme.txt'
Set-Content -Path $readmePath -Value $finalContent -Encoding UTF8

Write-Host "   ✅ Created: readme.txt with conversion summary" -ForegroundColor Green

# Final summary
Write-Host "`n🎉 Conversion Complete!" -ForegroundColor Green
Write-Host "=====================================`n" -ForegroundColor Green
Write-Host "📂 Output Folder: $outputFolderName" -ForegroundColor White
Write-Host "📊 Files Converted: $totalFiles" -ForegroundColor White
Write-Host "📁 Sound Categories: $($fileGroups.Count)" -ForegroundColor White

if ($skippedFiles.Count -gt 0) {
    Write-Host "⚠️  Files Skipped: $($skippedFiles.Count)" -ForegroundColor Yellow
}

Write-Host "`n✨ Your Proffie sound font is ready!" -ForegroundColor Cyan