# Script pour mettre à jour la navigation
$filePath = "c:\Users\FGA\Documents\Flutter\pharmacie\pharmacie\lib\views\mes_commandes_view.dart"

Start-Sleep -Seconds 2

$content = Get-Content -Path $filePath -Raw -Encoding UTF8

# Remplacer l'import
$content = $content -replace "import 'pharmacy_responses_api_view.dart';", "import 'pharmacy_responses_list_view.dart';"

# Remplacer la navigation
$content = $content -replace "PharmacyResponsesApiView\(commandeId: id\)", "PharmacyResponsesListView()"

Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline

Write-Host "Navigation mise a jour avec succes!"
