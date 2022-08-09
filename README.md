# Pipe
A alternative to NSNotificationCenter

# Usage
```swift
// Automatically invalidate on release.
var pipe: Pipe<String>?

// Automatically invalidate on release.
var token1: PipeSourceToken?
var token2: PipeSourceToken?

foo() {
    pipe = Pipe<String>()

    // Source1
    token1 = pipe?.sourceChannel.read { value in
        print("source 1: \(value)")
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        // Broadcast a value.
        self.pipe?.sinkChannel.write("郑念真 520")
        
        // Source2: Receive value on main queue, and replay latest value.
        token2 = pipe?.sourceChannel.read(onQueue: .main, replay: true) { value in
            print("source 2: \(value)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Manual invalidation, Source1 will not receive value again.
            self.token1?.invalidate()
            
            self.pipe?.sinkChannel.write("1314")
            self.pipe = nil
        }
    }
}

foo()

// print
// source 1: 郑念真 520
// source 2: 郑念真 520
// source 2: 1314
```
