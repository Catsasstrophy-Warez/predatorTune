import CoreLocation
import CoreMotion
import Foundation

/// Records the phone's GPS route and horizontal g-force while a Garage logging session runs.
/// Samples are taken at the motion rate and tagged with the most recent GPS fix; nothing is
/// recorded until the first fix arrives.
@MainActor
final class SessionMotionRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var sampleCount = 0

    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private var samples: [TrackSample] = []
    private var startDate = Date()
    private var lastFix: (latitude: Double, longitude: Double, speed: Double?)?
    private var lastSampleTime: TimeInterval = -1

    /// Motion updates at 10 Hz; samples are kept no faster than this.
    private static let sampleInterval: TimeInterval = 0.1

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .automotiveNavigation
    }

    func start() {
        guard !isRecording else { return }
        samples = []; sampleCount = 0; lastFix = nil; lastSampleTime = -1
        startDate = Date()
        isRecording = true

        if locationManager.authorizationStatus == .notDetermined { locationManager.requestWhenInUseAuthorization() }
        locationManager.startUpdatingLocation()

        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = Self.sampleInterval
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let motion else { return }
                self?.record(horizontalG: Self.horizontalG(motion))
            }
        }
    }

    /// Stops recording and returns the session's samples (empty if no GPS fix was obtained).
    func stop() -> [TrackSample] {
        guard isRecording else { return [] }
        isRecording = false
        locationManager.stopUpdatingLocation()
        motionManager.stopDeviceMotionUpdates()
        let recorded = samples
        samples = []
        return recorded
    }

    private func record(horizontalG: Double?) {
        guard isRecording, let fix = lastFix else { return }
        let time = Date().timeIntervalSince(startDate)
        guard time - lastSampleTime >= Self.sampleInterval * 0.9 else { return }
        lastSampleTime = time
        samples.append(TrackSample(time: time, latitude: fix.latitude, longitude: fix.longitude, speed: fix.speed, horizontalG: horizontalG))
        sampleCount = samples.count
    }

    fileprivate func updateFix(latitude: Double, longitude: Double, speed: Double?) {
        lastFix = (latitude, longitude, speed)
        // Without motion hardware, still record the route at the GPS rate.
        if !motionManager.isDeviceMotionActive { record(horizontalG: nil) }
    }

    /// User acceleration with its vertical (gravity-axis) component removed, in g.
    private nonisolated static func horizontalG(_ motion: CMDeviceMotion) -> Double {
        let a = motion.userAcceleration, g = motion.gravity
        let gravityLength = max(sqrt(g.x * g.x + g.y * g.y + g.z * g.z), 0.0001)
        let (ux, uy, uz) = (g.x / gravityLength, g.y / gravityLength, g.z / gravityLength)
        let vertical = a.x * ux + a.y * uy + a.z * uz
        let (hx, hy, hz) = (a.x - vertical * ux, a.y - vertical * uy, a.z - vertical * uz)
        return sqrt(hx * hx + hy * hy + hz * hz)
    }
}

extension SessionMotionRecorder: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0, location.horizontalAccuracy < 50 else { return }
        let latitude = location.coordinate.latitude, longitude = location.coordinate.longitude
        let speed = location.speed >= 0 ? location.speed : nil
        Task { @MainActor in self.updateFix(latitude: latitude, longitude: longitude, speed: speed) }
    }
}
