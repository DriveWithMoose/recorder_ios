//
//  SecondViewController.swift
//  basic_mapbox_sdk
//
//  Created by Rajen Dey on 9/30/21.
//

import UIKit

class DashboardViewController: UIViewController {

    @IBOutlet weak var mooseLabel: UILabel!
    @IBOutlet weak var driveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpMooseLabel()

        // Do any additional setup after loading the view.
    }
    
    func setUpMooseLabel() {
        mooseLabel.font = UIFont(name: mooseLabel.font.fontName, size: 50)
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
