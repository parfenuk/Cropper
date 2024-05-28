//
//  DragAcceptingView.swift
//  Cropper
//
//  Created by Miraslau Parafeniuk on 28.05.24.
//

import Cocoa

class DragAcceptingView: NSView {
    
    weak var parent: CropViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self])
        ? .copy : []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        if let url = sender
            .draggingPasteboard
            .readObjects(forClasses: [NSURL.self],
                         options: [.urlReadingFileURLsOnly: true])?.first as? NSURL,
           let path = url.path {
            parent?.didLoadFile(from: path)
        }
        
        return true
    }
}
