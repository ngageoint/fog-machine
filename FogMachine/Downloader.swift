//
//  Downloader.swift
//  FogMachine
//
//  Created by Ram Subramaniam on 2/1/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import SSZipArchive

class Downloader : NSObject, NSURLSessionDownloadDelegate {
    var remoteURL : NSURL?
    // will be used to do whatever is needed once download is complete
    var dataViewController : DataViewController?
    
    init(dataViewController : DataViewController) {
        self.dataViewController = dataViewController
    }
    
    //is called once the download is complete
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        //copy downloaded data to your documents directory with same names as source file
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let destinationUrl = documentsUrl!.URLByAppendingPathComponent(remoteURL!.lastPathComponent!)
        let dataFromURL = NSData(contentsOfURL: location)
        dataFromURL!.writeToURL(destinationUrl, atomically: true)
        //now it is time to do what is needed to be done after the download
        dataViewController!.downloadComplete(String(destinationUrl))
    }
    
    //this is to track progress
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }
    
    // if there is an error during download this will be called
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil) {
            print("Download completed with error: \(error!.localizedDescription)");
        }
    }
    
    //method to be called to download
    func download(remoteURL: NSURL) {
        self.remoteURL = remoteURL
        //download identifier can be customized. I used the "ulr.absoluteString"
        let sessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(remoteURL.absoluteString)
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.downloadTaskWithURL(remoteURL)
        task.resume()
    }
   
}

