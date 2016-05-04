import Foundation
import UIKit
import SSZipArchive

public class HGTDownloader: NSObject, NSURLSessionDownloadDelegate {

    let onDownload:(String)->()
    let onError:(String)->()
    
    init(onDownload:(String)->(), onError:(String)->()) {
        self.onDownload = onDownload
        self.onError = onError
    }
    
    func downloadFile(remoteURL: NSURL) {
        //download identifier can be customized. I used the "ulr.absoluteString"
        let sessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(remoteURL.absoluteString)
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.downloadTaskWithURL(remoteURL)
        task.resume()
    }

    // called once the download is complete
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let response = downloadTask.response as! NSHTTPURLResponse
        let statusCode = response.statusCode
        // URL not found.. do not proceed.
        if (statusCode == 200) {
            //copy downloaded data to your documents directory with same names as source file
            let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
            let destinationUrl = documentsUrl!.URLByAppendingPathComponent(location.lastPathComponent!)
            let dataFromURL:NSData = NSData(contentsOfURL: location)!
            if (dataFromURL.writeToURL(destinationUrl, atomically: true)) {
                let status:Bool = SSZipArchive.unzipFileAtPath(destinationUrl.path!, toDestination: documentsUrl!.path!)
                if(status) {
                    deleteFile(destinationUrl.path!)
                    onDownload("some file name")
                } else {
                    onError("Problem unzipping file.")
                }
            }
        } else {
            NSLog("Received bad status code from sever.")
            onError("Problem downloading file.  Received bad status code from sever.")
        }
    }

    func deleteFile(fileName: String) {
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtPath(fileName)
        }
        catch let error as NSError {
            NSLog("Error deleteing file: " + fileName + ": \(error)")
        }
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
    }

    // to track progress
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }

    // if there is an error during download this will be called
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil) {
            NSLog("Download error: \(error)");
            onError("Problem downloading file.")
        }
    }
}
