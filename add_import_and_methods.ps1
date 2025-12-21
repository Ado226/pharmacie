# Script pour ajouter l'import et les méthodes
$filePath = "c:\Users\FGA\Documents\Flutter\pharmacie\pharmacie\lib\views\pharmacy_responses_api_view.dart"

# Lire le contenu
$content = Get-Content -Path $filePath -Raw -Encoding UTF8

# 1. Ajouter l'import
$content = $content -replace "import 'payment_view.dart';", "import 'payment_view.dart';`nimport 'pharmacy_response_detail_view.dart';"

# 2. Ajouter la méthode _showResponseDetails avant _selectPharmacy
$newMethod = @"

  void _showResponseDetails(ReponsePharmacieApi response) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PharmacyResponseDetailView(
          response: response,
          commande: _commandeDetails!.commande,
        ),
      ),
    );
  }
"@

$content = $content -replace "  void _selectPharmacy\(ReponsePharmacieApi response, int index\) \{", "$newMethod`n`n  void _selectPharmacy(ReponsePharmacieApi response, int index) {"

# 3. Remplacer _buildPharmacyActionButton
$oldButton = @"
  Widget _buildPharmacyActionButton\(
    ReponsePharmacieApi response,
    bool isRecommended,
    int index,
  \) \{
    return Container\(
      width: double\.infinity,
      height: 64,
      decoration: BoxDecoration\(
        gradient: LinearGradient\(
          colors: isRecommended
              \? \[_accent, _accentLight\]
              : \[_primary, _primaryLight\],
        \),
        borderRadius: const BorderRadius\.only\(
          bottomLeft: Radius\.circular\(24\),
          bottomRight: Radius\.circular\(24\),
        \),
        boxShadow: \[
          BoxShadow\(
            color: \(isRecommended \? _accent : _primary\)\.withOpacity\(0\.3\),
            blurRadius: 12,
            offset: const Offset\(0, 4\),
          \),
        \],
      \),
      child: Material\(
        color: Colors\.transparent,
        child: InkWell\(
          borderRadius: const BorderRadius\.only\(
            bottomLeft: Radius\.circular\(24\),
            bottomRight: Radius\.circular\(24\),
          \),
          onTap: \(\) => _selectPharmacy\(response, index\),
          child: Container\(
            padding: const EdgeInsets\.symmetric\(horizontal: 24\),
            child: Row\(
              mainAxisAlignment: MainAxisAlignment\.center,
              children: \[
                const Icon\(
                  Icons\.shopping_cart_rounded,
                  color: Colors\.white,
                  size: 24,
                \),
                const SizedBox\(width: 12\),
                Text\(
                  isRecommended \? 'CHOISIR \(RECOMMANDÉ\)' : 'SÉLECTIONNER',
                  style: const TextStyle\(
                    fontSize: 16,
                    fontWeight: FontWeight\.w800,
                    color: Colors\.white,
                    letterSpacing: 0\.5,
                  \),
                \),
              \],
            \),
          \),
        \),
      \),
    \);
  \}
"@

$newButton = @"
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

$content = $content -replace $oldButton, $newButton

# Sauvegarder
Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline

Write-Host "Modifications appliquees avec succes!"
