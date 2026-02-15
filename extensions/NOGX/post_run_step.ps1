$YYPLATFORM_name = $env:YYPLATFORM_name
$YYoutputFolder = $env:YYoutputFolder
$YYprojectName = $env:YYprojectName
$YYTARGET_runtime = $env:YYTARGET_runtime
$YYtempFolder = $env:YYtempFolder

$YYEXTOPT_NOGX_Enable = $env:YYEXTOPT_NOGX_Enable

Write-Host "[NOGX] post_run_step"

if ($YYEXTOPT_NOGX_Enable -ne "True") {
	Write-Host "[NOGX] The extension is disabled."
	exit 0
}

Write-Host "[NOGX] Current platform: $YYPLATFORM_name"

if ($YYPLATFORM_name -ine "Opera GX" -and $YYPLATFORM_name -ine "operagx") {
	Write-Host "[NOGX] Aborting: This script is only for Opera GX platform."
	exit 0
}

$outputDir = [System.IO.Path]::Combine($YYoutputFolder, "runner")
$webfilesDir = [System.IO.Path]::Combine($PSScriptRoot, "..", "..", "webfiles")
$webfilesDir = [System.IO.Path]::GetFullPath($webfilesDir)
$defaultIndexFile = [System.IO.Path]::Combine($PSScriptRoot, "index.html")

Write-Host "[NOGX] Project name: $YYprojectName"
Write-Host "[NOGX] Target runtime: $YYTARGET_runtime"
Write-Host "[NOGX] Output dir: $outputDir"
Write-Host "[NOGX] Webfiles dir: $webfilesDir"

if (!(Test-Path $outputDir)) {
	Write-Error "[NOGX] Output directory does not exist."
	exit 1
}

if (Test-Path $webfilesDir) {
	Write-Host "[NOGX] Copying 'webfiles' folder content."
	Copy-Item -Path "$webfilesDir\*" -Destination $outputDir -Recurse -Force
} else {
	Write-Host "[NOGX] 'webfiles' folder does not exist."
}

$sourceFile = [System.IO.Path]::Combine($YYtempFolder, "NOGX_index.html")
if (!(Test-Path $sourceFile)) {
	Write-Host "[NOGX] '$sourceFile' does not exist."
	exit 1
}

if ($YYTARGET_runtime -ieq "YYC") {
	$indexFile = Join-Path $outputDir "index.html"
	$runnerFile = Join-Path $outputDir "$YYprojectName.html"
	Copy-Item -Path $sourceFile -Destination $indexFile -Force
	Copy-Item -Path $sourceFile -Destination $runnerFile -Force

	$jsFile = Join-Path $outputDir "$YYprojectName.js"
	if (Test-Path $jsFile) {
		Move-Item -Path $jsFile -Destination (Join-Path $outputDir "runner.js") -Force
	}
}
elseif ($YYTARGET_runtime -ieq "VM") {
	$indexFile = Join-Path $outputDir "index.html"
	$runnerFile = Join-Path $outputDir "runner.html"
	Copy-Item -Path $sourceFile -Destination $indexFile -Force
	Copy-Item -Path $sourceFile -Destination $runnerFile -Force
}
else {
	Write-Error "[NOGX] Unknown runtime target '$YYTARGET_runtime'."
	exit 1
}

Write-Host "[NOGX] Done."
exit 0

