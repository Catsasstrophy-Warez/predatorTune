import Foundation

@MainActor
extension DataRepository {
    // MARK: - Vehicle Operations

    func save(vehicle: GT500Vehicle) async throws {
        try entityStore.save(vehicle, id: vehicle.id, vehicleID: vehicle.id, kind: .vehicle)
    }

    func fetchVehicle(id: UUID) async throws -> GT500Vehicle? {
        let decoder = JSONDecoder()
        if let stored = try entityStore.fetch(GT500Vehicle.self, id: id, kind: .vehicle) { return stored }
        guard let data = UserDefaults.standard.data(forKey: "vehicle_\(id)") else { return nil }
        let legacy = try decoder.decode(GT500Vehicle.self, from: data)
        try entityStore.save(legacy, id: legacy.id, vehicleID: legacy.id, kind: .vehicle)
        return legacy
    }

    func fetchAllVehicles() async throws -> [GT500Vehicle] {
        do {
            let stored = try entityStore.fetchAll(GT500Vehicle.self, kind: .vehicle)
            if !stored.isEmpty { return stored }
        } catch { recordPersistenceIssue(domain: "vehicleStore", error: error) }
        let decoder = JSONDecoder(); let ids = UserDefaults.standard.stringArray(forKey: "vehicle_ids") ?? []
        let legacy = ids.compactMap { idString -> GT500Vehicle? in
            guard let data = UserDefaults.standard.data(forKey: "vehicle_\(idString)") else { return nil }
            do { return try decoder.decode(GT500Vehicle.self, from: data) } catch { recordPersistenceIssue(domain: "vehicle", recordID: idString, error: error); return nil }
        }
        for value in legacy { try? entityStore.save(value, id: value.id, vehicleID: value.id, kind: .vehicle) }
        return legacy
    }

    // MARK: - Session Operations

    func save(session: Session) async throws {
        try entityStore.save(session, id: session.id, vehicleID: session.vehicleID, kind: .session)
    }

    func fetchSession(id: UUID) async throws -> Session? {
        let decoder = JSONDecoder()
        if let stored = try entityStore.fetch(Session.self, id: id, kind: .session) { return stored }
        guard let data = UserDefaults.standard.data(forKey: "session_\(id)") else { return nil }
        let legacy = try decoder.decode(Session.self, from: data)
        try entityStore.save(legacy, id: legacy.id, vehicleID: legacy.vehicleID, kind: .session)
        return legacy
    }

    func fetchAllSessions(forVehicle vehicleID: UUID) async throws -> [Session] {
        let stored = try entityStore.fetchAll(Session.self, kind: .session, vehicleID: vehicleID)
        if !stored.isEmpty { return stored.sorted { $0.date > $1.date } }
        let decoder = JSONDecoder()
        let ids = UserDefaults.standard.stringArray(forKey: "session_ids") ?? []
        let sessions = ids.compactMap { idString -> Session? in
            guard let data = UserDefaults.standard.data(forKey: "session_\(idString)") else { return nil }
            do { return try decoder.decode(Session.self, from: data) } catch { recordPersistenceIssue(domain: "session", recordID: idString, error: error); return nil }
        }.filter { $0.vehicleID == vehicleID }

        return sessions.sorted { $0.date > $1.date }
    }

    // MARK: - Investigation Operations

    func save(investigation: Investigation) async throws {
        try entityStore.save(investigation, id: investigation.id, vehicleID: investigation.vehicleID, kind: .investigation)
    }

    func fetchAllInvestigations(forVehicle vehicleID: UUID) async throws -> [Investigation] {
        let stored = try entityStore.fetchAll(Investigation.self, kind: .investigation, vehicleID: vehicleID)
        if !stored.isEmpty { return stored }
        let decoder = JSONDecoder()
        let ids = UserDefaults.standard.stringArray(forKey: "investigation_ids") ?? []
        return ids.compactMap { idString -> Investigation? in
            guard let data = UserDefaults.standard.data(forKey: "investigation_\(idString)") else { return nil }
            do { return try decoder.decode(Investigation.self, from: data) } catch { recordPersistenceIssue(domain: "investigation", recordID: idString, error: error); return nil }
        }.filter { $0.vehicleID == vehicleID }
    }

    // MARK: - Service Record Operations

    func save(serviceRecord: ServiceRecord) async throws {
        try entityStore.save(serviceRecord, id: serviceRecord.id, vehicleID: serviceRecord.vehicleID, kind: .serviceRecord)
    }

    func fetchAllServiceRecords(forVehicle vehicleID: UUID) async throws -> [ServiceRecord] {
        let stored = try entityStore.fetchAll(ServiceRecord.self, kind: .serviceRecord, vehicleID: vehicleID)
        if !stored.isEmpty { return stored.sorted { $0.date > $1.date } }
        let decoder = JSONDecoder()
        let ids = UserDefaults.standard.stringArray(forKey: "servicerecord_ids") ?? []
        let records = ids.compactMap { idString -> ServiceRecord? in
            guard let data = UserDefaults.standard.data(forKey: "servicerecord_\(idString)") else { return nil }
            do { return try decoder.decode(ServiceRecord.self, from: data) } catch { recordPersistenceIssue(domain: "serviceRecord", recordID: idString, error: error); return nil }
        }.filter { $0.vehicleID == vehicleID }

        return records.sorted { $0.date > $1.date }
    }


}
