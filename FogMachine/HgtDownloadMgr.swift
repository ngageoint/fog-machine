//
//  Downloader.swift
//  FogMachine
//
//  Created by Ram Subramaniam on 2/1/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import UIKit
import SSZipArchive


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
        let response = downloadTask.response as! NSHTTPURLResponse
        let statusCode = response.statusCode
        // URL not found.. donot proceed.
        if (statusCode == 200) {
            //copy downloaded data to your documents directory with same names as source file
            let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
            let destinationUrl = documentsUrl!.URLByAppendingPathComponent(remoteURL!.lastPathComponent!)
            let dataFromURL:NSData = NSData(contentsOfURL: location)!
            if (dataFromURL.writeToURL(destinationUrl, atomically: true)) {
                let retFileName = self.unzipDownloadedFile(destinationUrl.path!, hgtFilePath: documentsUrl!.path!)
                //now it is time to do what is needed to be done after the download
                self.delegate?.didReceiveResponse!(retFileName)
            }
        }
    }
    
    func unzipDownloadedFile(strHgtZipFileWithPath: String, hgtFilePath: String) -> String {
        var strRet: String = String()
        //let hgtFilePath = documentsUrl!.path
        if (SSZipArchive.unzipFileAtPath(strHgtZipFileWithPath, toDestination: hgtFilePath)) {
            deleteHgtZipFile(strHgtZipFileWithPath)
            let range = strHgtZipFileWithPath.startIndex.advancedBy(0)..<strHgtZipFileWithPath.endIndex.advancedBy(-4)
            strRet = strHgtZipFileWithPath.substringWithRange(range)
        }
        return strRet
    }
    
    func deleteHgtZipFile(hgtZipFileName: String) {
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtPath(hgtZipFileName)
        }
        catch let error as NSError {
            print("Error Delete the zip file: " + hgtZipFileName + ": \(error)")
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
            print("Download error: \(error)");
            self.delegate?.didFailToReceieveResponse!("Download Error: \(error!.localizedDescription)")
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







