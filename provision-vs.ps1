# add support for building applications that target the .net 4.7.1 framework.
# NB we have to install netfx-4.7.1-devpack manually, because for some odd reason,
#    the setup is returning the -1073741819 (0xc0000005 STATUS_ACCESS_VIOLATION)
#    exit code even thou it installs successfully.
#    see https://github.com/jberezanski/ChocolateyPackages/issues/22
$archiveUrl = 'https://packages.chocolatey.org/netfx-4.7.1-devpack.4.7.2558.0.nupkg'
$archiveHash = 'e293769f03da7a42ed72d37a92304854c4a61db279987fc459d3ec7aaffecf93'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName.zip"
Write-Host 'Downloading the netfx-4.7.1-devpack package...'
Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Expand-Archive $archivePath "$archivePath.tmp"
Push-Location "$archivePath.tmp"
Remove-Item -Recurse _rels,package,*.xml
Set-Content -Encoding Ascii `
    tools/ChocolateyInstall.ps1 `
    ((Get-Content tools/ChocolateyInstall.ps1) -replace '0, # success','0,-1073741819, # success')
choco pack
choco install -y netfx-4.7.1-devpack -Source $PWD
Pop-Location

# add support for building applications that target the .net 4.6.2 framework.
choco install -y netfx-4.6.2-devpack

# see https://www.visualstudio.com/vs/
# see https://www.visualstudio.com/en-us/news/releasenotes/vs2017-relnotes
# see https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio
# see https://docs.microsoft.com/en-us/visualstudio/install/command-line-parameter-examples
# see https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/100404311/045b56eb413191d03850ecc425172a7d/vs_Community.exe'
$archiveHash = '995c5f356e567e0f2c8f6d744d9b59a88721b22667db9d505d500587b5c68d99'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Host 'Downloading the Visual Studio Setup Bootstrapper...'
Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host 'Installing Visual Studio...'
for ($try = 1; ; ++$try) {
    &$archivePath `
        --installPath C:\VisualStudio2017Community `
        --add Microsoft.VisualStudio.Workload.CoreEditor `
        --add Microsoft.VisualStudio.Workload.NetCoreTools `
        --add Microsoft.VisualStudio.Workload.NetWeb `
        --add Microsoft.VisualStudio.Workload.ManagedDesktop `
        --add Microsoft.VisualStudio.Workload.NativeDesktop `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop `
        --norestart `
        --quiet `
        --wait `
        | Out-String -Stream
    if ($LASTEXITCODE) {
        if ($try -le 5) {
            Write-Host "Failed to install Visual Studio with Exit Code $LASTEXITCODE. Trying again (hopefully the error was transient)..."
            Start-Sleep -Seconds 10
            continue
        }
        throw "Failed to install Visual Studio with Exit Code $LASTEXITCODE"
    }
    break
}
