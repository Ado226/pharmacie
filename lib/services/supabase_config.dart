// Fichier: lib/services/supabase_config.dart
// Configuration pour la connexion à Supabase

class SupabaseConfig {
  // URL de votre projet Supabase
  static const String supabaseUrl = 'https://zofrsgaltvsrdkxqfxfb.supabase.co';
  
  // Clé API anonyme (publique) de votre projet Supabase
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvZnJzZ2FsdHZzcmRreHFmeGZiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODM2MTk3MSwiZXhwIjoyMDYzOTM3OTcxfQ.XPa0vnc7zuKpMqNhLHYk4gN0YwWqjEaK0pmwU_aCGmU';
  
  // Nom de la table des prescriptions
  static const String prescriptionsTable = 'prescriptions';
  
  // Nom de la table des médicaments des prescriptions
  static const String prescriptionMedicationsTable = 'prescription_medications';
  
  // Nom de la table des médicaments
  static const String medicationsTable = 'medications';
  
  // Nom de la table des réponses des pharmacies
  static const String pharmacyResponsesTable = 'pharmacy_responses';
  
  // Nom de la table des pharmacies
  static const String pharmaciesTable = 'pharmacies';
  
  // Nom de la table des réponses des médicaments
  static const String medicationResponsesTable = 'medication_responses';
}
