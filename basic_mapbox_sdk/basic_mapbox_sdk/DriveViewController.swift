import MapboxVision
import MapboxVisionSafety
import UIKit

/**
 * "Safety alerts" example demonstrates how to utilize events from MapboxVisionSafetyManager
 * to alert a user about exceeding allowed speed limit and potential collisions with other cars.
 */

// Custom UIView to draw a red bounding box
class BoundingBoxView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Transparent view with a red border
        backgroundColor = .clear
        layer.borderWidth = 3
        layer.borderColor = UIColor.red.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DriveViewController: UIViewController {
    private var cameraVideoSource: CameraVideoSource!
    private var visionManager: VisionManager!
    private var visionSafetyManager: VisionSafetyManager!
    private let visionViewController = VisionPresentationViewController()

    private var vehicleState: VehicleState?
    private var speedLimits: SpeedLimits?
    private var roadDescription: RoadDescription?
    private var worldDescription: WorldDescription? // to get objects and positions
    private var frameDetections: FrameDetections? // to get objects and bounding boxes
    private var frameSignClassifications: FrameSignClassifications? // to get signs
    private var camera: Camera?
    
    @IBOutlet weak var endDriveButton: UIButton!
    private var dataHandler: DataHandler = DataHandler()
    private var motionManager: CMMotionManager = CMMotionManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cameraVideoSource = CameraVideoSource()
        // create VisionManager, VisionSafetyManager, register as their delegates to receieve events
        self.visionManager = VisionManager.create(videoSource: cameraVideoSource)
        self.visionManager.delegate = self
        self.visionSafetyManager = VisionSafetyManager.create(visionManager: visionManager)
        self.visionSafetyManager.delegate = self

        // configure Vision view to display sample buffers from video source
        self.visionViewController.set(visionManager: visionManager)
        // add Vision view as a child view
        self.addVisionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.cameraVideoSource.start()
        self.visionManager.start()
        self.startRecording()
        
        
        self.setupEndDriveButton()
        self.motionManager.startAccelerometerUpdates()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.cameraVideoSource.stop()
        self.visionManager.stopRecording()
        self.visionManager.stop() // also stops recording
        
        self.visionSafetyManager.destroy()
        self.visionManager.destroy()
        self.dataHandler.destroy()
    }
    
    private func startRecording() {
        let documentDirURL = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        try? self.visionManager.startRecording(to: documentDirURL[0] + "/drive_data/")
    }

    private func addVisionView() {
        self.addChild(visionViewController)
        self.view.addSubview(visionViewController.view)
        visionViewController.didMove(toParent: self)
    }

    private func updateCollisionDrawing() {
        for subview in self.view.subviews {
            if subview.isKind(of: BoundingBoxView.self) {
                subview.removeFromSuperview()
            }
        }
        
        if let detections = self.frameDetections?.detections {
            for detection in detections {
                let relativeBBox = detection.boundingBox
                let cameraFrameSize = frameDetections!.frame.image.size.cgSize

                // calculate absolute coordinates
                let bboxInCameraFrameSpace = CGRect(
                    x: relativeBBox.origin.x * cameraFrameSize.width,
                    y: relativeBBox.origin.y * cameraFrameSize.height,
                    width: relativeBBox.size.width * cameraFrameSize.width,
                    height: relativeBBox.size.height * cameraFrameSize.height
                )

                // at this stage, bbox has the coordinates in the camera frame space
                // you should convert it to the view space saving the aspect ratio

                // first, construct left-top and right-bottom coordinates of a bounding box
                var leftTop = CGPoint(x: bboxInCameraFrameSpace.origin.x,
                                      y: bboxInCameraFrameSpace.origin.y)
                var rightBottom = CGPoint(x: bboxInCameraFrameSpace.maxX,
                                          y: bboxInCameraFrameSpace.maxY)

                // then convert the points from the camera frame space into the view frame space
                leftTop = leftTop.convertForAspectRatioFill(from: cameraFrameSize,
                                                            to: view.bounds.size)
                rightBottom = rightBottom.convertForAspectRatioFill(from: cameraFrameSize,
                                                                    to: view.bounds.size)

                // finally, construct a bounding box in the view frame space
                let bboxInViewSpace = CGRect(x: leftTop.x,
                                             y: leftTop.y,
                                             width: rightBottom.x - leftTop.x,
                                             height: rightBottom.y - leftTop.y)

                // draw a collision detection alert
                self.view.addSubview(BoundingBoxView(frame: bboxInViewSpace))
            }
        }
    }
    
    func setupEndDriveButton() {
        self.view.addSubview(endDriveButton)
    }
}

extension DriveViewController: VisionManagerDelegate {
    func visionManager(_ visionManager: VisionManagerProtocol,
                       didUpdateVehicleState vehicleState: VehicleState) {
        // dispatch to the main queue in order to sync access to `VehicleState` instance
        DispatchQueue.main.async { [weak self] in
            self?.vehicleState = vehicleState
        }
    }
    
    func visionManager(_ visionManager: VisionManagerProtocol,
                       didUpdateRoadDescription roadDescription: RoadDescription) {
        DispatchQueue.main.async { [weak self] in
            self?.roadDescription = roadDescription
        }
    }
    
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateFrameSignClassifications frameSignClassifications: FrameSignClassifications) {
        DispatchQueue.main.async { [weak self] in
            self?.frameSignClassifications = frameSignClassifications
        }
    }
    
    func visionManager(_ visionManager: VisionManagerProtocol,
                       didUpdateFrameDetections frameDetections: FrameDetections) {
        DispatchQueue.main.async { [weak self] in
            self?.frameDetections = frameDetections
        }
    }
    
    //
    func visionManager(_ visionManager: VisionManagerProtocol,
                       didUpdateWorldDescription worldDescription: WorldDescription) {
        DispatchQueue.main.async { [weak self] in
            self?.worldDescription = worldDescription
        }
    }
    
    // only works in real world
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateCamera camera: Camera) {
        DispatchQueue.main.async { [weak self] in
            self?.camera = camera
            if camera.calibrationProgress > 0 {
                print("didUpdateCamera", camera.calibrationProgress)
            }
        }
    }

    func visionManagerDidCompleteUpdate(_ visionManager: VisionManagerProtocol) {
        // dispatch to the main queue in order to work with UIKit elements
        DispatchQueue.main.async { [weak self] in
            // update UI elements
            if let self = self {
                self.updateCollisionDrawing()
                if let vehicleState = self.vehicleState {
                    self.dataHandler.vehicle_speed = "\(vehicleState.speed)"
                }
                if self.motionManager.isAccelerometerAvailable {
                    if let accelerometerData = self.motionManager.accelerometerData {
                        self.dataHandler.vehicle_accel = "\(max(accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z))"
                    }
                }
                if let roadDescription = self.roadDescription {
                    self.dataHandler.lane_position = "\(roadDescription.relativePositionInLane)"
                }
                if let signClassifications = self.frameSignClassifications?.signs {
                    for signClassification in signClassifications {
                        if signClassification.sign.type == SignType.speedLimit {
                            self.dataHandler.speed_limit = "\(signClassification.sign.number)"
                        }
                    }
                }
                if let worldDescription = self.worldDescription {
                    if let roadDescription = self.roadDescription {
                        if roadDescription.currentLaneIndex >= 0 && roadDescription.currentLaneIndex < roadDescription.lanes.count {
                            let lane = roadDescription.lanes[roadDescription.currentLaneIndex]
                            let objects = worldDescription.objects(in: lane)
                            var closestX = Double.infinity
                            for object in objects {
                                if object.detectionClass == DetectionClass.car {
                                    if object.position.x < closestX {
                                        closestX = object.position.x
                                    }
                                }
                            }
                            self.dataHandler.following_dist = "\(closestX)"
                        }
                    }
                }
                self.dataHandler.writeData()
            }
        }
    }
}

extension DriveViewController: VisionSafetyManagerDelegate {
    
    //https://docs.mapbox.com/ios/vision/api/safety/0.13.1/Protocols/VisionSafetyManagerDelegate.html#/s:18MapboxVisionSafety0bC15ManagerDelegateP06visioncD0_25didUpdateRoadRestrictionsyAA0bcD0C_So07MBVRoadJ0CtF
    // camera must be calibrated for this function to be called
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager,
                             didUpdateRoadRestrictions roadRestrictions: RoadRestrictions) {
        // dispatch to the main queue in order to sync access to `SpeedLimits` instance
        DispatchQueue.main.async { [weak self] in
            // save currenly applied speed limits
            print(roadRestrictions)
            print(roadRestrictions.speedLimits)
            self?.speedLimits = roadRestrictions.speedLimits
        }
    }
}
