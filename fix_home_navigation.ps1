# Script pour corriger la navigation depuis l'accueil
$filePath = "c:\Users\FGA\Documents\Flutter\pharmacie\pharmacie\lib\views\home_view.dart"

Start-Sleep -Seconds 2

$content = Get-Content -Path $filePath -Raw -Encoding UTF8

# Ajouter l'import de pharmacy_responses_list_view
if ($content -notmatch "import 'pharmacy_responses_list_view.dart';") {
    $content = $content -replace "(import 'pharmacy_responses_view.dart';)", "`$1`nimport 'pharmacy_responses_list_view.dart';"
    Write-Host "Import ajoute"
}

# Remplacer MesCommandesView par PharmacyResponsesListView dans les deux endroits
$content = $content -replace "routeBuilder: \(\) => const MesCommandesView\(\),", "routeBuilder: () => const PharmacyResponsesListView(),"
$content = $content -replace "MaterialPageRoute\(builder: \(context\) => const MesCommandesView\(\)\)", "MaterialPageRoute(builder: (context) => const PharmacyResponsesListView())"

Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline

Write-Host "Navigation depuis l'accueil corrigee!"
