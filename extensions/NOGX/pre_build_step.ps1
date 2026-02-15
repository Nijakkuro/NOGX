$YYMACROS_project_full_filename = $env:YYMACROS_project_full_filename
$YYtempFolder = $env:YYtempFolder
$YYoutputFolder = $env:YYoutputFolder
$YYPLATFORM_name = $env:YYPLATFORM_name
$YYEXTOPT_NOGX_Enable = $env:YYEXTOPT_NOGX_Enable

Write-Host "[NOGX] pre_build_step"

if ($YYEXTOPT_NOGX_Enable -ne "True") {
	Write-Host "[NOGX] The extension is disabled."
	exit 0
}

Write-Host "[NOGX] Current platform: $YYPLATFORM_name"

if ($YYPLATFORM_name -ine "Opera GX" -and $YYPLATFORM_name -ine "operagx") {
	Write-Host "[NOGX] Aborting: This script is only for Opera GX platform."
	exit 0
}

function Validate-Json {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]$jsonContent
	)
	
	$jsonContentOut = $jsonContent -replace ',\s*}', '}'
	$jsonContentOut = $jsonContentOut -replace ',\s*]', ']'
	return $jsonContentOut;
}

function Get-AllGMExtensionFilenames {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]$projectFullFilename
	)
	
	$jsonContent = Get-Content -Raw -Path "$projectFullFilename"
	$jsonContent = Validate-Json -jsonContent "$jsonContent"
	
	$jsonStruct = $jsonContent | ConvertFrom-Json
	$resources = $jsonStruct.resources
	
	$filenames = @()
	
	$directory = Split-Path -Path $projectFullFilename
	
	foreach ($item in $resources) {
		if($item.id.path.StartsWith('extensions/')) {
			$extPath = ($item.id.path).Replace("/", "\")
			$filenames += "$directory\$extPath"
		}
	}
	
	return $filenames
}

function Get-HTML5CodeInjectionFromGMExt {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]$extensionFilename
	)
	
	$jsonContent = Get-Content -Raw -Path "$extensionFilename"
	$jsonContent = Validate-Json -jsonContent "$jsonContent"
	$jsonStruct = $jsonContent | ConvertFrom-Json
	
	[Int64]$mask = 1L -shl 34 # GX
	
	$flags = [Int64]$jsonStruct.copyToTargets
	
	if(($jsonStruct.html5Props) -and (($flags -band $mask) -ne 0)) {
		return $jsonStruct.HTML5CodeInjection
	}
	
	return ""
}

function Accumulate-AllHTML5CodeInjections {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string[]]$extensionFilenames
	)
	
	$allInjectors = ($extensionFilenames | ForEach-Object { Get-HTML5CodeInjectionFromGMExt -extensionFilename $_ }) -join ''
	
	$GM_HTML5_BrowserTitle = $env:YYPLATFORM_option_operagx_game_name
	$GM_HTML5_BackgroundColour = "#000000"
	$GM_HTML5_GameWidth = "640"
	$GM_HTML5_GameHeight = "360"
	$GM_HTML5_GameFolder = ""
	$GM_HTML5_GameFilename = ""
	$GM_HTML5_CacheBust = "$(Get-Random)"
	
	$allInjectors = $allInjectors.Replace("`${GM_HTML5_BrowserTitle}", $GM_HTML5_BrowserTitle
		).Replace("`${GM_HTML5_BackgroundColour}", $GM_HTML5_BrowserTitle
		).Replace("`${GM_HTML5_GameWidth}", $GM_HTML5_GameWidth
		).Replace("`${GM_HTML5_GameHeight}", $GM_HTML5_GameHeight
		).Replace("`${GM_HTML5_GameFolder}", $GM_HTML5_GameFolder
		).Replace("`${GM_HTML5_GameFilename}", $GM_HTML5_GameFilename
		).Replace("`${GM_HTML5_CacheBust}", $GM_HTML5_CacheBust)
	
	$optList = (Get-ChildItem Env: | Where-Object Name -like 'YYEXTOPT_*').Name
	
	foreach($opt in $optList) {
		$value = Get-Content "env:$opt"
		$allInjectors = $allInjectors.Replace("`${$opt}", $value)
	}
	
	[xml]$xmlDoc = "<content>$allInjectors</content>"
	
	$childElementNames = $xmlDoc.content.ChildNodes.LocalName | Select-Object -Unique
	
	$groups = @{}
	foreach ($node in $xmlDoc.content.ChildNodes) {
		if ($node.NodeType -eq 'Element') {
			$name = $node.LocalName
			if (-not $groups.ContainsKey($name)) {
				$groups[$name] = @()
			}
			$groups[$name] += [System.Net.WebUtility]::HtmlDecode($node.InnerXML)
		}
	}
	
	$groups["GM_HTML5_BrowserTitle"] = $GM_HTML5_BrowserTitle
	$groups["GM_HTML5_BackgroundColour"] = $GM_HTML5_BackgroundColour
	$groups["GM_HTML5_GameWidth"] = $GM_HTML5_GameWidth
	$groups["GM_HTML5_GameHeight"] = $GM_HTML5_GameHeight
	$groups["GM_HTML5_GameFolder"] = $GM_HTML5_GameFolder
	$groups["GM_HTML5_GameFilename"] = $GM_HTML5_GameFilename
	$groups["GM_HTML5_CacheBust"] = $GM_HTML5_CacheBust
	
	return $groups
}

function Inject-TextFile {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]$inputFilename,
		
		[Parameter(Mandatory)]
		[string]$outputFilename,
		
		[Parameter(Mandatory)]
		[hashtable]$injections
	)
	
	$content = Get-Content -Raw -Path $inputFilename -Encoding utf8
	
	$injections.GetEnumerator() | ForEach-Object {
		$content = $content.Replace("`${$($_.Key)}", "$($_.Value)")
	}
	
	$content | Out-File -FilePath $outputFilename -Encoding utf8
}

Write-Host "[NOGX] Getting all extension filenames from '$YYMACROS_project_full_filename'"
$extensionFilenames = Get-AllGMExtensionFilenames -projectFullFilename $YYMACROS_project_full_filename
Write-Host "[NOGX] Extensions:"
Write-Host $extensionFilenames

Write-Host "[NOGX] Accumulating all HTML injections:"
$injections = Accumulate-AllHTML5CodeInjections -extensionFilenames $extensionFilenames
$injections.GetEnumerator() | ForEach-Object {
	Write-Host "`$($($_.Key)) :"
	Write-Host "$($_.Value)"
}

$webfilesDir = [System.IO.Path]::Combine($PSScriptRoot, "..", "..", "webfiles")
$webfilesDirIndexFile = [System.IO.Path]::GetFullPath( [System.IO.Path]::Combine($webfilesDir, "index.html") )
$defaultIndexFile = [System.IO.Path]::Combine($PSScriptRoot, "index.html")

$sourceFile = $defaultIndexFile
if (Test-Path $webfilesDirIndexFile) {
	$sourceFile = $webfilesDirIndexFile
}

$outputFilename = [System.IO.Path]::Combine($YYtempFolder, "NOGX_index.html")

Write-Host "[NOGX] Injecting into 'index.html' ('$sourceFile' -> '$outputFilename')"
Inject-TextFile -inputFilename $sourceFile -outputFilename $outputFilename -injections $injections

Write-Host "[NOGX] The injection is complete. The resulting file is in '$outputFilename'"
exit 0

