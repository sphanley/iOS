//
//  NotificationViewController.swift
//  NotificationContentExtension
//
//  Created by Robbie Trencheny on 9/9/16.
//  Copyright © 2016 Robbie Trencheny. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import MapKit
import MBProgressHUD

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    var hud: MBProgressHUD? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        print("Received a \(notification.request.content.categoryIdentifier) notification type")
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.detailsLabel.text = "Loading \(notification.request.content.categoryIdentifier)..."
        hud.offset = CGPoint(x: 0, y: -MBProgressMaxOffset+50)
        self.hud = hud
        switch (notification.request.content.categoryIdentifier) {
            case "map":
                mapHandler(notification)
            case "camera":
                cameraHandler(notification)
            default:
                return
        }
    }
    
    func mapHandler(_ notification: UNNotification) {
        let haDict = notification.request.content.userInfo["homeassistant"] as! [String:Any]
        guard let latitudeString = haDict["latitude"] as? String else { return }
        guard let longitudeString = haDict["longitude"] as? String else { return }
        let latitude = Double.init(latitudeString)! as CLLocationDegrees
        let longitude = Double.init(longitudeString)! as CLLocationDegrees
        
        let mapCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpanMake(0.1, 0.1)
        
        let options = MKMapSnapshotOptions()
        options.mapType = .standard
        options.showsPointsOfInterest = false
        options.showsBuildings = false
        options.region = MKCoordinateRegion(center: mapCoordinate, span: span)
        options.size = self.view.frame.size
        options.scale = self.view.contentScaleFactor
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start() { snapshot, error in
            
            let image = snapshot!.image
            
            let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: "")
            let pinImage = pin.image
            
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale);
            
            image.draw(at: CGPoint(x: 0, y: 0))
            
            let homePoint = snapshot?.point(for: mapCoordinate)
            pinImage?.draw(at: homePoint!)
            
            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let imageView = UIImageView(image: finalImage)
            imageView.frame = self.view.frame
            imageView.contentMode = .scaleAspectFit
            self.view.addSubview(imageView)
            self.hud!.hide(animated: true)
            self.preferredContentSize = CGSize(width: 0, height: imageView.frame.maxY)
        }
    }
    
    func cameraHandler(_ notification: UNNotification) {
        guard let incomingAttachment = notification.request.content.userInfo["attachment"] as? [String:Any] else { return }
        guard let attachmentString = incomingAttachment["url"] as? String else { return }
        guard let attachmentURL = URL(string: attachmentString) else { return }
        
        let imageView = UIImageView()
        imageView.frame = self.view.frame
        imageView.contentMode = .scaleAspectFit
        
        // TODO: Need to use the authentication information from HAAPI so that the image will be valid forever instead of 10 minutes
        let streamingController = MjpegStreamingController(imageView: imageView, contentURL: attachmentURL)
        streamingController.didFinishLoading = { _ in
            print("Finished loading")
            self.hud!.hide(animated: true)

            self.view.addSubview(imageView)
        }
        streamingController.play()
    }

}
