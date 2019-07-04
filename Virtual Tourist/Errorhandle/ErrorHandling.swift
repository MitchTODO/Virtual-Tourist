//
//  ErrorHandling.swift
//  Virtual Tourist
//
//  Created by Tucker on 6/25/19.
//  Copyright © 2019 Tucker. All rights reserved.
//

import Foundation
import UIKit

/*
 MARK: MapViewController, AddPinViewController, TableViewController Errors
 INFO: Maps user strings to approprate errors
 */

enum CustomErrors: Error {
    case empty
    case noPitcturesForLocation
    case majorError
    case invalidConnection
    case cantSave
}

extension CustomErrors: CustomStringConvertible {
    var description: String {
        switch self {
        case .empty: return "Empty Location or URL"
        case .noPitcturesForLocation: return "No picture exist for location"
        case .majorError: return "Error as occurd"
        case .invalidConnection: return "Check network"
        case .cantSave: return "Internal Error as occurd"
        }
    }
}

/*
 MARK: alertErrors
 INFO: allows for error strings to be presented
 NOTE:
 Extending error to make it alertable
 displays alert from source controller
 */

extension Error {
    
    func alert(with controller: UIViewController) {
        let message = self as NSError
        
        let alertController = UIAlertController(title: nil, message: "\(message.localizedDescription)", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alertController.addAction(okAction)
        controller.present(alertController, animated: true, completion: nil)
    }
}

