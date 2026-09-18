// PredatorLab/Services/DurableEntityStore.swift
// Rev14: iOS 16-compatible Core Data persistence using a programmatic model.
// Preferences remain in UserDefaults; large evidence files remain in Application Support.

import Foundation
#if canImport(CoreData)
import CoreData
#endif

enum DurableEntityKind: String, CaseIterable {
    case vehicle, session, investigation, serviceRecord, importedLog, validationReport, forensicAnnotation, postJobRCA, evidenceAttachment, rcaAttachmentLink, measurementClaim, measurementClaimRevision, technicalTruth, technicalTruthRevision, evidenceArtifact, evidenceTruthReview, calibrationGenome, calibrationDifferenceManifest, calibrationFlashEvent, tuneExperiment, tuneLogContract, tuneArtifactDescriptor, trackAddictSession, tdnLineageEvent, calibrationSemanticRecord, spatialFlightRecorderAnchor, vcmParameterObservation, vcmNavigatorCapture, vcmScannerSemanticReview, calibrationTruthDebtSnapshot, calibrationDependencyGraph, calibrationBlastRadius, tuneConclusionExplanation, torqueFirstOutAnalysis, scannerPollingBudgetPlan, trc75ShiftCohortComparison, stableWindowAnalysis, lambdaDeviationFingerprint, sparkKnockChronology, thermalDerateFingerprint, interventionSeparation, distributionComparison, adaptiveExperimentRecommendation, highLoadPullReconstruction, calibrationLogCorrelation, pullRepeatabilityAssessment, experimentClosurePlan, scannerContractPlan, tuneEvidenceWorkspace, mpvi4DeviceSnapshot, mpvi4TelemetrySession, mpvi4PowerIncident, mpvi4AcquisitionBenchmark, mpvi4ExperimentProfile, mpvi4EvidenceIngestion, rev83ConfigBContract, rev83HPLCorrelation, rev83ForensicCase
}

struct DurableEntityEnvelope: Codable {
    let id: UUID
    let vehicleID: UUID?
    let kind: String
    let payload: Data
    let updatedAt: Date
}

/// Small JSON-payload entity store. The domain models remain Codable and migration-safe while
/// Core Data supplies transactions, indexed lookup and a durable database on iOS 16.
final class DurableEntityStore {
#if canImport(CoreData)
    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "PredatorLab", managedObjectModel: model)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { assertionFailure("PredatorLab Core Data store failed to load: \(loadError)") }
        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save<T: Codable>(_ value: T, id: UUID, vehicleID: UUID?, kind: DurableEntityKind) throws {
        let context = container.viewContext
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "PLRecord")
        fetch.fetchLimit = 1
        fetch.predicate = NSPredicate(format: "id == %@ AND kind == %@", id as CVarArg, kind.rawValue)
        let object = try context.fetch(fetch).first ?? NSEntityDescription.insertNewObject(forEntityName: "PLRecord", into: context)
        object.setValue(id, forKey: "id")
        object.setValue(vehicleID, forKey: "vehicleID")
        object.setValue(kind.rawValue, forKey: "kind")
        object.setValue(try JSONEncoder().encode(value), forKey: "payload")
        object.setValue(Date(), forKey: "updatedAt")
        try context.save()
    }

    func fetch<T: Codable>(_ type: T.Type, id: UUID, kind: DurableEntityKind) throws -> T? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PLRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@ AND kind == %@", id as CVarArg, kind.rawValue)
        guard let data = try container.viewContext.fetch(request).first?.value(forKey: "payload") as? Data else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }

    func fetchAll<T: Codable>(_ type: T.Type, kind: DurableEntityKind, vehicleID: UUID? = nil) throws -> [T] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PLRecord")
        if let vehicleID {
            request.predicate = NSPredicate(format: "kind == %@ AND vehicleID == %@", kind.rawValue, vehicleID as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "kind == %@", kind.rawValue)
        }
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        return try container.viewContext.fetch(request).compactMap { object in
            guard let data = object.value(forKey: "payload") as? Data else { return nil }
            return try JSONDecoder().decode(type, from: data)
        }
    }

    func delete(id: UUID, kind: DurableEntityKind) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PLRecord")
        request.predicate = NSPredicate(format: "id == %@ AND kind == %@", id as CVarArg, kind.rawValue)
        for object in try container.viewContext.fetch(request) { container.viewContext.delete(object) }
        try container.viewContext.save()
    }

    func deleteAll() throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PLRecord")
        try container.viewContext.execute(NSBatchDeleteRequest(fetchRequest: request))
        try container.viewContext.save()
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription(); entity.name = "PLRecord"; entity.managedObjectClassName = "NSManagedObject"
        func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let a = NSAttributeDescription(); a.name = name; a.attributeType = type; a.isOptional = optional; return a
        }
        let id = attribute("id", .UUIDAttributeType)
        let vehicleID = attribute("vehicleID", .UUIDAttributeType, optional: true)
        let kind = attribute("kind", .stringAttributeType)
        let payload = attribute("payload", .binaryDataAttributeType); payload.allowsExternalBinaryDataStorage = true
        let updatedAt = attribute("updatedAt", .dateAttributeType)
        entity.properties = [id, vehicleID, kind, payload, updatedAt]
        entity.uniquenessConstraints = [["id", "kind"]]
        model.entities = [entity]
        return model
    }
#else
    // Linux/source-validation fallback. Production iOS builds use Core Data above.
    private var records: [String: Data] = [:]
    init(inMemory: Bool = false) {}
    private func key(_ id: UUID, _ kind: DurableEntityKind) -> String { "\(kind.rawValue)|\(id.uuidString)" }
    func save<T: Codable>(_ value: T, id: UUID, vehicleID: UUID?, kind: DurableEntityKind) throws { records[key(id, kind)] = try JSONEncoder().encode(value) }
    func fetch<T: Codable>(_ type: T.Type, id: UUID, kind: DurableEntityKind) throws -> T? { guard let data=records[key(id,kind)] else{return nil}; return try JSONDecoder().decode(type,from:data) }
    func fetchAll<T: Codable>(_ type: T.Type, kind: DurableEntityKind, vehicleID: UUID? = nil) throws -> [T] { try records.filter{$0.key.hasPrefix(kind.rawValue+"|")}.map{try JSONDecoder().decode(type,from:$0.value)} }
    func delete(id: UUID, kind: DurableEntityKind) throws { records.removeValue(forKey:key(id,kind)) }
    func deleteAll() throws { records.removeAll() }
#endif
}
