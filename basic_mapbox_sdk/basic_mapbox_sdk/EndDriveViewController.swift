//
//  EndDriveViewController.swift
//  basic_mapbox_sdk
//
//  Created by Rajen Dey on 10/13/21.
//

import UIKit

class EndDriveViewController: UIViewController {

    @IBOutlet var driveEndedLabel: UILabel!
    @IBOutlet weak var backToDashboardButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func setupDriveEndedLabel() {
        driveEndedLabel.font = UIFont(name: driveEndedLabel.font.fontName, size: 50)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
