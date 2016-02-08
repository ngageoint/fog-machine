//
//  Downloader.swift
//  FogMachine
//
//  Created by Ram Subramaniam on 2/1/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import UIKit

@objc protocol HgtDownloadMgrDelegate {
    optional func didReceiveResponse(destinationPath: String)
    optional func didFailToReceieveResponse(error: String)
}

class HgtDownloadMgr: NSObject, NSURLSessionDownloadDelegate {
    var remoteURL : NSURL?
    var delegate: HgtDownloadMgrDelegate?
    var downloadComplete:Bool = false
    
    override init() {
        super.init()
    }
    
    //is called once the download is complete
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        //copy downloaded data to your documents directory with same names as source file
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let destinationUrl = documentsUrl!.URLByAppendingPathComponent(remoteURL!.lastPathComponent!)
        let dataFromURL = NSData(contentsOfURL: location)
        
        if (dataFromURL != nil && !downloadComplete) {
            downloadComplete = true
            dataFromURL!.writeToURL(destinationUrl, atomically: true)
            //now it is time to do what is needed to be done after the download
            self.delegate?.didReceiveResponse!(destinationUrl.path!)
        }
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
    }
    
    //this is to track progress
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }
    
    // if there is an error during download this will be called
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil) {
            print("Download with error: \(error!.localizedDescription)");
            self.delegate?.didFailToReceieveResponse!("Error \(error!.localizedDescription)")
        }
    }
    
    //method to be called to download
    func downloadHgtFile(remoteURL: NSURL) {
        self.remoteURL = remoteURL
        //download identifier can be customized. I used the "ulr.absoluteString"
        
        let sessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(remoteURL.absoluteString)
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.downloadTaskWithURL(remoteURL)
        task.resume()
    }
}





