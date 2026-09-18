import Foundation
@MainActor protocol VehicleRepositoryRev129 {
 func save(vehicle:GT500Vehicle) async throws
 func fetchVehicle(id:UUID) async throws -> GT500Vehicle?
 func fetchAllVehicles() async throws -> [GT500Vehicle]
}
@MainActor protocol TelemetryRepositoryRev129 {
 func fetchAllImportedLogs(forVehicle vehicleID:UUID) async throws -> [ImportedLog]
 func reloadDataset(for log:ImportedLog) throws -> ParsedLogData
 func clearDatasetCache()
}
@MainActor protocol InvestigationRepositoryRev129 {
 func save(investigation:Investigation) async throws
 func fetchAllInvestigations(forVehicle vehicleID:UUID) async throws -> [Investigation]
}
@MainActor protocol EvidenceRepositoryRev129 {
 func fetchEvidenceArtifacts(vehicleID:UUID?) async throws -> [PersistedEvidenceArtifact]
 func fetchMeasurementClaims(vehicleID:UUID?) async throws -> [PersistedMeasurementClaim]
}
extension DataRepository:VehicleRepositoryRev129,TelemetryRepositoryRev129,InvestigationRepositoryRev129,EvidenceRepositoryRev129 {}
@MainActor struct PredatorLabRepositoryDomainsRev129 {
 let vehicles:any VehicleRepositoryRev129;let telemetry:any TelemetryRepositoryRev129;let investigations:any InvestigationRepositoryRev129;let evidence:any EvidenceRepositoryRev129
 init(repository:DataRepository){vehicles=repository;telemetry=repository;investigations=repository;evidence=repository}
 static let boundary="Stable domain protocols narrow DataRepository access without changing persisted representation. This is an incremental decomposition seam, not a persistence migration."
}
