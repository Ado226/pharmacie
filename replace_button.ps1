# Script pour remplacer le bouton avec plusieurs tentatives
$filePath = "c:\Users\FGA\Documents\Flutter\pharmacie\pharmacie\lib\views\pharmacy_responses_api_view.dart"

$maxAttempts = 5
$attempt = 0
$success = $false

while (-not $success -and $attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "Tentative $attempt sur $maxAttempts..."

    try {
        # Attendre un peu
        Start-Sleep -Seconds 2

        # Lire le contenu
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8

        # Pattern à rechercher (simplifié)
        $pattern = "return Container\(\s+width: double\.infinity,\s+height: 64,\s+decoration: BoxDecoration\(\s+gradient: LinearGradient\(\s+colors: isRecommended\s+\? \[_accent, _accentLight\]\s+: \[_primary, _primaryLight\],\s+\),\s+borderRadius: const BorderRadius\.only\(\s+bottomLeft: Radius\.circular\(24\),\s+bottomRight: Radius\.circular\(24\),\s+\),\s+boxShadow: \[\s+BoxShadow\(\s+color: \(isRecommended \? _accent : _primary\)\.withOpacity\(0\.3\),\s+blurRadius: 12,\s+offset: const Offset\(0, 4\),\s+\),\s+\],\s+\),\s+child: Material\(\s+color: Colors\.transparent,\s+child: InkWell\(\s+borderRadius: const BorderRadius\.only\(\s+bottomLeft: Radius\.circular\(24\),\s+bottomRight: Radius\.circular\(24\),\s+\),\s+onTap: \(\) => _selectPharmacy\(response, index\),\s+child: Container\(\s+padding: const EdgeInsets\.symmetric\(horizontal: 24\),\s+child: Row\(\s+mainAxisAlignment: MainAxisAlignment\.center,\s+children: \[\s+const Icon\(\s+Icons\.shopping_cart_rounded,\s+color: Colors\.white,\s+size: 24,\s+\),\s+const SizedBox\(width: 12\),\s+Text\(\s+isRecommended \? 'CHOISIR \(RECOMMANDÉ\)' : 'SÉLECTIONNER',\s+style: const TextStyle\(\s+fontSize: 16,\s+fontWeight: FontWeight\.w800,\s+color: Colors\.white,\s+letterSpacing: 0\.5,\s+\),\s+\),\s+\],\s+\),\s+\),\s+\),\s+\),\s+\);"

        # Chercher l'index du début de _buildPharmacyActionButton
        $startIndex = $content.IndexOf("Widget _buildPharmacyActionButton(")
        if ($startIndex -eq -1) {
            Write-Host "Fonction _buildPharmacyActionButton non trouvee!"
            exit 1
        }

        # Trouver la fin de la fonction (le } qui la ferme)
        $openBraces = 0
        $foundStart = $false
        $endIndex = -1

        for ($i = $startIndex; $i -lt $content.Length; $i++) {
            if ($content[$i] -eq '{') {
                $openBraces++
                $foundStart = $true
            }
            elseif ($content[$i] -eq '}') {
                $openBraces--
                if ($foundStart -and $openBraces -eq 0) {
                    $endIndex = $i + 1
                    break
                }
            }
        }

        if ($endIndex -eq -1) {
            Write-Host "Fin de la fonction non trouvee!"
            exit 1
        }

        # Extraire la fonction actuelle
        $oldFunction = $content.Substring($startIndex, $endIndex - $startIndex)

        # Nouvelle fonction
        $newFunction = @"
Widget _buildPharmacyActionButton(
    ReponsePharmacieApi response,
    bool isRecommended,
    int index,
  ) {
    return Row(
      children: [
        // Bouton "Voir Détail"
        Expanded(
          flex: 1,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[700]!, Colors.grey[600]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[700]!.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                ),
                onTap: () => _showResponseDetails(response),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'VOIR DÉTAIL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Bouton "Sélectionner"
        Expanded(
          flex: 1,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isRecommended
                    ? [_accent, _accentLight]
                    : [_primary, _primaryLight],
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isRecommended ? _accent : _primary).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(24),
                ),
                onTap: () => _selectPharmacy(response, index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRecommended ? 'CHOISIR' : 'SÉLECTIONNER',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
"@

        # Remplacer
        $newContent = $content.Replace($oldFunction, $newFunction)

        # Sauvegarder
        Set-Content -Path $filePath -Value $newContent -Encoding UTF8 -NoNewline

        Write-Host "Modification reussie!"
        $success = $true
    }
    catch {
        Write-Host "Erreur: $_"
        Write-Host "Nouvelle tentative dans 2 secondes..."
    }
}

if (-not $success) {
    Write-Host "Echec apres $maxAttempts tentatives."
    exit 1
}
