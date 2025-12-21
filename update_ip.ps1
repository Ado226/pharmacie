# Script pour mettre à jour l'IP dans tous les fichiers
$oldIP = "192.168.11.184"
$newIP = "192.168.11.101"

$files = @(
    "lib\services\database_config.dart",
    "lib\core\utils\api_config.dart",
    "lib\core\config\api_config.dart",
    "lib\core\utils\constants.dart"
)

foreach ($file in $files) {
    $filePath = "c:\Users\FGA\Documents\Flutter\pharmacie\pharmacie\$file"
    if (Test-Path $filePath) {
        Write-Host "Mise a jour de $file..."
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8
        $content = $content -replace $oldIP, $newIP
        Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  -> OK"
    } else {
        Write-Host "  -> Fichier non trouve: $file"
    }
}

Write-Host "`nMise a jour terminee!"
Write-Host "Ancienne IP: $oldIP"
Write-Host "Nouvelle IP: $newIP"
