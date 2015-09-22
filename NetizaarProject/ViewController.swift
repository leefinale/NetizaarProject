//
//  ViewController.swift
//  NetizaarProject
//
//  Created by Elex Lee on 9/14/15.
//  Copyright (c) 2015 Elex Lee. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    var imageURLArray: [String] = []
    var imageCache = [String:UIImage]()
    var container: CKContainer?
    var publicDB: CKDatabase?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        container = CKContainer.defaultContainer()
        publicDB = container!.publicCloudDatabase
        getImageURL()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageCell", forIndexPath: indexPath) as! ImageCollectionViewCell
        cell.backgroundColor = UIColor.whiteColor()
        if imageURLArray.count != 0 {
            if let image = imageCache[String(indexPath.row)] {
                cell.imageView.image = image
            } else {
                let session = NSURLSession.sharedSession()
                let imgURL = NSURL(string: imageURLArray[indexPath.row])
                let request: NSURLRequest = NSURLRequest(URL: imgURL!)
                let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                    if error == nil {
                        // Convert the downloaded data in to a UIImage object
                        let imageTemp = UIImage(data: data!)
                        // Store the image in to our cache
                        self.imageCache[String(indexPath.row)] = imageTemp
                        // Save image to directory
                        self.saveImageToCloud(imageTemp!, savePath: String(indexPath.row))
                        // Update the cell
                        dispatch_async(dispatch_get_main_queue(), {
                            if let cellToUpdate = self.imageCollectionView.cellForItemAtIndexPath(indexPath) as? ImageCollectionViewCell {
                                cellToUpdate.imageView.image = imageTemp
                            }
                        })
                    }
                    else {
                        print("Error: \(error!.localizedDescription)")
                    }
                })
                task.resume()
            }
        }
        return cell
    }
    
    func getImageURL() {
        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest()
        request.HTTPMethod = "GET"
        request.URL = NSURL(string: "https://api.500px.com/v1/photos?feature=editors&page=2&consumer_key=sUAfXzQnQA7tXDVAsD91gfG8KzjDGLnGsOoCw3TI")
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if let error = error {
                print(error)
            } else {
                let json = JSON(data: data!)
                for objects in json["photos"] {
                    let imageURL = objects.1["image_url"]
                    self.imageURLArray.append(imageURL.description)
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.imageCollectionView.reloadData()
                })
            }
        })
        task.resume()
    }
    
    func saveImageToCloud(image: UIImage, savePath: String) {
        let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
        let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
        
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)[0] as String
        let filePathToWrite = "\(paths)/\(savePath).png"
        print(filePathToWrite)
        UIImagePNGRepresentation(image)?.writeToFile(filePathToWrite, atomically: true)
        
        let file: CKAsset = CKAsset(fileURL: NSURL(fileURLWithPath: filePathToWrite))
        
        let newRecord:CKRecord = CKRecord(recordType: "ImageRecord")
        newRecord.setValue(file, forKey: "Image")
        
        if let database = publicDB {
            database.saveRecord(newRecord, completionHandler: {(record: CKRecord?, error: NSError?) in
                if error != nil {
                    NSLog(error!.localizedDescription)
                } else {
                    print("success")
                }
            })
        }
    }

}

