#  NOTE: If you receive the warning 'Script Execution is disabled on this system' run the following code: Set-ExecutionPolicy RemoteSigned
#  TODO: Prompt for version number.
#  TODO: Minify CSS and JavaScript for obfuscation purposes. (maybe just JavaScript)
$version = '0.98';
$rootPath = ${env:userprofile} + '\Documents\GitHub\StreamusChromeExtension'

$manifestFile = $rootPath + '\manifest.json';

$versionManifestEntry =  '"version": "' + $version + '"';

Write-Output $versionManifestEntry;

#  Update the version number of the manifest.
(Get-Content $manifestFile) | 

    #  Find the line that looks like: "version: #.##" and update it with current version
    Foreach-Object {$_ -replace '"version": "[0-9]\.[0-9][0-9]"', $versionManifestEntry} |
    
Set-Content -Encoding UTF8 $manifestFile

$deploymentPath = $rootPath + '\Deploy';

#  Create a deployment directory if it does not already exist. This will be the staging area for deploying the client/server.
if( !(Test-Path $deploymentPath) )
{
    New-Item -ItemType directory -Path $deploymentPath
}
else {
    #  Clear out the deployment folder if it already exists.
    Get-ChildItem $deploymentPath | Remove-Item -Recurse
}

#  Copy the StreamsChromeExtension folder's contents to deployment.
$excludedDeployEntities = @('*.csproj', '*.csproj.user', '*.suo', '*.sln', '*.pem', '*.crx', 'bin', 'obj', 'Properties', '*.git', '*.idea', 'Deploy', 'New design', '*.gitattributes', '*.gitignore', 'LICENSE', 'README.md', '*.zip', '*.ps1');

Get-ChildItem $rootPath -Exclude $excludedDeployEntities | Copy-Item -destination $deploymentPath -Recurse

$deployedManifestFile = $deploymentPath + '\manifest.json';

(Get-Content $deployedManifestFile) | 

    #  Remove permissions that're only needed for debugging.
    Where-Object {$_ -notmatch '"key": "'} |

    #  Remove manifest key -- can't upload to Chrome Web Store if this entry exists in manifest.json, but helps with debugging.
    Where-Object {$_ -notmatch '"http://localhost:61975/Streamus/",'} |
    
Set-Content -Encoding UTF8 $deployedManifestFile

#  Ensure that localDebug is set to false in settings.js -- local debugging is for development only.
$deployedSettingsFile = $deploymentPath + '\js\background\model\settings.js';

(Get-Content $deployedSettingsFile) | 
    #  Find the line that looks like: "localDebug: true" and set it to false. Local debugging is for development only.
    Foreach-Object {$_ -replace "localDebug: true", "localDebug: false"} | 
Set-Content $deployedSettingsFile


#  7-Zip must be installed on the target system for this to work.
#  Inspiration from: http://stackoverflow.com/questions/1153126/how-to-create-a-zip-archive-with-powershell
function create-7zip([String] $aDirectory, [String] $aZipfile){
    [string]$pathToZipExe = "C:\Program Files\7-zip\7z.exe";
    [Array]$arguments = "a", "-tzip", "$aZipfile", "$aDirectory", "-r";
    & $pathToZipExe $arguments;
}

#  Zip up package ready for deployment.
$deployZipPath = $rootPath + '\Streamus v' + $version + '.zip';

create-7zip $deploymentPath $deployZipPath