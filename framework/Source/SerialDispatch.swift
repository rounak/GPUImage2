import Foundation

#if os(Linux)
// For now, disable GCD on Linux and run everything on the main thread

protocol SerialDispatch {
}
    
extension SerialDispatch {
    func runOperationAsynchronously(operation:() -> ()) {
        operation()
    }
    
    func runOperationSynchronously(operation:() -> ()) {
        operation()
    }
    
    func runOperationSynchronously(operation:() throws -> ()) throws {
        try operation()
    }
    
    func runOperationSynchronously<T>(operation:() throws -> T) throws -> T {
        return try operation()
    }
}

#else

func runAsynchronouslyOnMainQueue(mainThreadOperation:() -> ()) {
    if (NSThread.isMainThread()) {
        mainThreadOperation()
    } else {
        dispatch_async(dispatch_get_main_queue(), mainThreadOperation)
    }
}

func runOnMainQueue(mainThreadOperation:() -> ()) {
    if (NSThread.isMainThread()) {
        mainThreadOperation()
    } else {
        dispatch_sync(dispatch_get_main_queue(), mainThreadOperation)
    }
}

@warn_unused_result func runOnMainQueue<T>(mainThreadOperation:() -> T) -> T {
    var returnedValue: T!
    runOnMainQueue {
        returnedValue = mainThreadOperation()
    }
    return returnedValue
}

// MARK: -
// MARK: SerialDispatch extension

protocol SerialDispatch {
    var serialDispatchQueue:dispatch_queue_t { get }
    var dispatchQueueKey:UnsafePointer<Void> { get }
}

extension SerialDispatch {
    func runOperationAsynchronously(operation:() -> ()) {
        dispatch_async(self.serialDispatchQueue, operation)
    }
    
    func runOperationSynchronously(operation:() -> ()) {
        // TODO: Verify this works as intended
        let context = UnsafeMutablePointer<Void>(Unmanaged<dispatch_queue_t>.passUnretained(self.serialDispatchQueue).toOpaque())
        if (dispatch_get_specific(self.dispatchQueueKey) == context) {
            operation()
        } else {
            dispatch_sync(self.serialDispatchQueue, operation)
        }
    }
    
    func runOperationSynchronously(operation:() throws -> ()) throws {
        var caughtError:ErrorType? = nil
        runOperationSynchronously {
            do {
                try operation()
            } catch {
                caughtError = error
            }
        }
        if (caughtError != nil) {throw caughtError!}
    }
    
    func runOperationSynchronously<T>(operation:() throws -> T) throws -> T {
        var caughtError:ErrorType? = nil
        var returnedValue: T!
        runOperationSynchronously {
            do {
                returnedValue = try operation()
            } catch {
                caughtError = error
            }
        }
        if (caughtError != nil) {throw caughtError!}
        return returnedValue
    }
}
#endif