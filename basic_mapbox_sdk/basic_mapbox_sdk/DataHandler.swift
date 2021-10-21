//
//  DataHandler.swift
//  basic_mapbox_sdk
//
//  Created by Rajen Dey on 10/15/21.
//

import Foundation

class DataHandler {
    private var fileURL: URL!
    
    public var timestamp: Int! = 0
    public var vehicle_speed: String! = "DNE"
    public var vehicle_accel: String! = "DNE"
    public var lane_position: String! = "DNE"
    public var speed_limit: String! = "DNE"
    public var following_dist: String! = "DNE"
    
    init() {
        self.fileURL = createFile(header: "timestamp,following_dist,user_speed,user_accel,speed_limit,lane_position\n", fileName: "driver_info")
    }
    
    private func createFile(header: String, fileName: String) -> URL {
        let documentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentDirURL.appendingPathComponent(fileName).appendingPathExtension("csv")
        try! header.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    public func writeData() {
        let lineToAdd = "\(timestamp!),\(following_dist!),\(vehicle_speed!),\(vehicle_accel!),\(speed_limit!),\(lane_position!)\n"
        if let fileUpdater = try? FileHandle(forUpdating: self.fileURL) {
            fileUpdater.seekToEndOfFile()
            fileUpdater.write(lineToAdd.data(using: .utf8)!)
            fileUpdater.closeFile()
        }
        self.timestamp += 1
    }
    
    public func destroy() {
        if let fileUpdater = try? FileHandle(forUpdating: self.fileURL) {
            fileUpdater.closeFile()
        }
    }
}
