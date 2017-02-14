//
//  URLSession+CorrectedResumeData.swift
//  Quran
//
// Taken From Stackoverflow
// http://stackoverflow.com/questions/39346231/resume-nsurlsession-on-ios10
//

import Foundation

func correct(requestData data: Data?) -> Data? {
    guard let data = data else {
        return nil
    }
    if NSKeyedUnarchiver.unarchiveObject(with: data) != nil {
        return data
    }
    guard let archive = (try? PropertyListSerialization.propertyList(from: data, options: [.mutableContainersAndLeaves], format: nil)) as? NSMutableDictionary else {
        return nil
    }
    // Rectify weird __nsurlrequest_proto_props objects to $number pattern
    var k = 0
    while ((archive["$objects"] as? NSArray)?[1] as? NSDictionary)?.object(forKey: "$\(k)") != nil {
        k += 1
    }
    var i = 0
    while ((archive["$objects"] as? NSArray)?[1] as? NSDictionary)?.object(forKey: "__nsurlrequest_proto_prop_obj_\(i)") != nil {
        let arr = archive["$objects"] as? NSMutableArray
        if let dic = arr?[1] as? NSMutableDictionary, let obj = dic["__nsurlrequest_proto_prop_obj_\(i)"] {
            dic.setObject(obj, forKey: "$\(i + k)" as NSString)
            dic.removeObject(forKey: "__nsurlrequest_proto_prop_obj_\(i)")
            arr?[1] = dic
            archive["$objects"] = arr
        }
        i += 1
    }
    if ((archive["$objects"] as? NSArray)?[1] as? NSDictionary)?.object(forKey: "__nsurlrequest_proto_props") != nil {
        let arr = archive["$objects"] as? NSMutableArray
        if let dic = arr?[1] as? NSMutableDictionary, let obj = dic["__nsurlrequest_proto_props"] {
            dic.setObject(obj, forKey: "$\(i + k)" as NSString)
            dic.removeObject(forKey: "__nsurlrequest_proto_props")
            arr?[1] = dic
            archive["$objects"] = arr
        }
    }
    /* I think we have no reason to keep this section in effect
     for item in (archive["$objects"] as? NSMutableArray) ?? [] {
     if let cls = item as? NSMutableDictionary, cls["$classname"] as? NSString == "NSURLRequest" {
     cls["$classname"] = NSString(string: "NSMutableURLRequest")
     (cls["$classes"] as? NSMutableArray)?.insert(NSString(string: "NSMutableURLRequest"), at: 0)
     }
     }*/
    // Rectify weird "NSKeyedArchiveRootObjectKey" top key to NSKeyedArchiveRootObjectKey = "root"
    if let obj = (archive["$top"] as? NSMutableDictionary)?.object(forKey: "NSKeyedArchiveRootObjectKey") as AnyObject? {
        (archive["$top"] as? NSMutableDictionary)?.setObject(obj, forKey: NSKeyedArchiveRootObjectKey as NSString)
        (archive["$top"] as? NSMutableDictionary)?.removeObject(forKey: "NSKeyedArchiveRootObjectKey")
    }
    // Reencode archived object
    let result = try? PropertyListSerialization.data(fromPropertyList: archive, format: PropertyListSerialization.PropertyListFormat.binary, options: PropertyListSerialization.WriteOptions())
    return result
}

func getResumeDictionary(_ data: Data) -> NSMutableDictionary? {
    // In beta versions, resumeData is NSKeyedArchive encoded instead of plist
    var iresumeDictionary: NSMutableDictionary? = nil
    if #available(iOS 10.0, OSX 10.12, *) {
        var root : AnyObject? = nil
        let keyedUnarchiver = NSKeyedUnarchiver(forReadingWith: data)
        
        do {
            root = try keyedUnarchiver.decodeTopLevelObject(forKey: "NSKeyedArchiveRootObjectKey") ?? nil
            if root == nil {
                root = try keyedUnarchiver.decodeTopLevelObject(forKey: NSKeyedArchiveRootObjectKey)
            }
        } catch {}
        keyedUnarchiver.finishDecoding()
        iresumeDictionary = root as? NSMutableDictionary
        
    }
    
    if iresumeDictionary == nil {
        do {
            iresumeDictionary = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions(), format: nil) as? NSMutableDictionary;
        } catch {}
    }
    
    return iresumeDictionary
}

func correctResumeData(_ data: Data?) -> Data? {
    let kResumeCurrentRequest = "NSURLSessionResumeCurrentRequest"
    let kResumeOriginalRequest = "NSURLSessionResumeOriginalRequest"
    
    guard let data = data, let resumeDictionary = getResumeDictionary(data) else {
        return nil
    }
    
    resumeDictionary[kResumeCurrentRequest] = correct(requestData: resumeDictionary[kResumeCurrentRequest] as? Data)
    resumeDictionary[kResumeOriginalRequest] = correct(requestData: resumeDictionary[kResumeOriginalRequest] as? Data)
    
    let result = try? PropertyListSerialization.data(fromPropertyList: resumeDictionary, format: PropertyListSerialization.PropertyListFormat.xml, options: PropertyListSerialization.WriteOptions())
    return result
}


extension URLSession {
    func correctedDownloadTask(withResumeData resumeData: Data) -> URLSessionDownloadTask {
        let kResumeCurrentRequest = "NSURLSessionResumeCurrentRequest"
        let kResumeOriginalRequest = "NSURLSessionResumeOriginalRequest"
        
        let cData = correctResumeData(resumeData) ?? resumeData
        let task = self.downloadTask(withResumeData: cData)
        
        // a compensation for inability to set task requests in CFNetwork.
        // While you still get -[NSKeyedUnarchiver initForReadingWithData:]: data is NULL error,
        // this section will set them to real objects
        if let resumeDic = getResumeDictionary(cData) {
            if task.originalRequest == nil, let originalReqData = resumeDic[kResumeOriginalRequest] as? Data, let originalRequest = NSKeyedUnarchiver.unarchiveObject(with: originalReqData) as? NSURLRequest {
                task.setValue(originalRequest, forKey: "originalRequest")
            }
            if task.currentRequest == nil, let currentReqData = resumeDic[kResumeCurrentRequest] as? Data, let currentRequest = NSKeyedUnarchiver.unarchiveObject(with: currentReqData) as? NSURLRequest {
                task.setValue(currentRequest, forKey: "currentRequest")
            }
        }
        
        return task
    }
}
