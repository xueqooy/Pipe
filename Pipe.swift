//
//  Pipe.swift
//  Pipe
//
//  Created by xueqooy on 2022/5/9.
//

import Foundation

private let pipeValueUserInfoKey = "Pipe.Value"

private class PipeContext {
    var isInvalidated: Bool = false

    var hasSunk: Bool = false
    var latestValue: Any?
}


public class PipeChannel {
    public var isInvalidated: Bool {
        context.isInvalidated
    }
    
    fileprivate let name: NSNotification.Name
    fileprivate let context: PipeContext
    
    fileprivate init(name: NSNotification.Name, context: PipeContext) {
        self.name = name
        self.context = context
    }
}


public class PipeSinkChannel<T>: PipeChannel {
    @discardableResult
    public func write(_ value: T?) -> Bool {
        if self.isInvalidated {
            return false
        }
        
        context.hasSunk = true
        context.latestValue = value
        
        var userInfo: [AnyHashable : Any]?
        if let value = value {
            userInfo = [pipeValueUserInfoKey : value]
        }
        
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
        
        return true
    }
}


public class PipeSourceToken {
    fileprivate weak var observer: AnyObject?
    
    deinit {
        invalidate()
    }
    
    public func invalidate() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }
}


public class PipeSourceChannel<T>: PipeChannel {
    private var tokens = WeakArray<PipeSourceToken>()
    
    deinit {
        invalidateTokens()
    }
    
    fileprivate func invalidateTokens() {
        tokens.elements.forEach{ $0.invalidate() }
    }
    
    public func read(onQueue queue: OperationQueue? = nil, replay: Bool = false, block: @escaping (T?) -> Void) -> PipeSourceToken? {
        if self.isInvalidated {
            return nil
        }
        
        let token = PipeSourceToken()
        token.observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: queue, using: { note in
            let value = note.userInfo?[pipeValueUserInfoKey]
            block(value as? T)
        })
        
        tokens.append(token)
                
        if replay && context.hasSunk {
            block(context.latestValue as? T)
        }
        
        return token
    }
}


public class Pipe<T> {
    
    private let context = PipeContext()
    
    public let sinkChannel: PipeSinkChannel<T>
    public let sourceChannel: PipeSourceChannel<T>
    
    public init() {
        let name = Notification.Name(rawValue: "Pipe-" + UUID().uuidString)
        
        sinkChannel = PipeSinkChannel<T>(name: name, context: context)
        sourceChannel = PipeSourceChannel<T>(name: name, context: context)
    }
    
    deinit {
        context.isInvalidated = true
        sourceChannel.invalidateTokens()
    }
}

