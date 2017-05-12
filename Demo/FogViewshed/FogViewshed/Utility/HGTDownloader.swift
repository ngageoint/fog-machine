import Foundation
import UIKit
import SSZipArchive

open class HGTDownloader: NSObject, URLSessionDownloadDelegate {

    static let DOWNLOAD_SERVER = "https://dds.cr.usgs.gov/srtm/version2_1/SRTM3/"
    
    let onDownload: (String) -> ()
    let onError: (String) -> ()
    
    init(onDownload: @escaping (String)->(), onError: @escaping (String)->()) {
        self.onDownload = onDownload
        self.onError = onError
    }
    
    func downloadFile(_ hgtFileName: String) {
        let srtmDataRegion: String = HGTRegions().getRegion(hgtFileName)
        if (srtmDataRegion.isEmpty == false) {
            let hgtFilePath: String = HGTDownloader.DOWNLOAD_SERVER + srtmDataRegion + "/" + hgtFileName + ".zip"
            let hgtURL = URL(string: hgtFilePath)
            let sessionConfig = URLSessionConfiguration.background(withIdentifier: hgtURL!.absoluteString)
            let session = Foundation.URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
            let task = session.downloadTask(with: hgtURL!)
            task.resume()
        }
    }

    // called once the download is complete
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let response = downloadTask.response as! HTTPURLResponse
        let statusCode = response.statusCode
        // URL not found, do not proceed
        if (statusCode == 200) {
            //copy downloaded data to your documents directory with same name as source file
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let destinationUrl = documentsUrl!.appendingPathComponent(location.lastPathComponent)
            let dataFromURL: Data = try! Data(contentsOf: location)
            if ((try? dataFromURL.write(to: destinationUrl, options: [.atomic])) != nil) {
                let status: Bool = SSZipArchive.unzipFile(atPath: destinationUrl.path, toDestination: documentsUrl!.path)
                if(status) {
                    deleteFile(destinationUrl.path)
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

    func deleteFile(_ fileName: String) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: fileName)
        }
        catch let error as NSError {
            NSLog("Error deleting file: " + fileName + ": \(error)")
        }
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    }

    // to track progress
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }

    // if there is an error during download this will be called
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if(error != nil) {
            NSLog("Download error: \(String(describing: error))")
            onError("Problem downloading file.")
        }
    }
}
