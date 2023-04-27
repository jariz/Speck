
public class Speck: SpeckRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Speck$_free(ptr)
        }
    }
}
extension Speck {
    public convenience init() {
        self.init(ptr: __swift_bridge__$Speck$new())
    }
}
public class SpeckRefMut: SpeckRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class SpeckRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension SpeckRef {
    public func init<GenericToRustStr: ToRustStr>(_ username: GenericToRustStr, _ password: GenericToRustStr) async throws -> RustString {
        func onComplete(cbWrapperPtr: UnsafeMutableRawPointer?, rustFnRetVal: __private__ResultPtrAndPtr) {
            let wrapper = Unmanaged<CbWrapper$Speck$init>.fromOpaque(cbWrapperPtr!).takeRetainedValue()
            if rustFnRetVal.is_ok {
                wrapper.cb(.success(RustString(ptr: rustFnRetVal.ok_or_err!)))
            } else {
                wrapper.cb(.failure(RustString(ptr: rustFnRetVal.ok_or_err!)))
            }
        }

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<RustString, Error>) in
            let callback = { rustFnRetVal in
                continuation.resume(with: rustFnRetVal)
            }

            let wrapper = CbWrapper$Speck$init(cb: callback)
            let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

            return password.toRustStr({ passwordAsRustStr in
                    return username.toRustStr({ usernameAsRustStr in
                    __swift_bridge__$Speck$init(wrapperPtr, onComplete, ptr, usernameAsRustStr, passwordAsRustStr)
                })
                })
        })
    }
    class CbWrapper$Speck$init {
        var cb: (Result<RustString, Error>) -> ()
    
        public init(cb: @escaping (Result<RustString, Error>) -> ()) {
            self.cb = cb
        }
    }
}
extension Speck: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Speck$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Speck$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Speck) {
        __swift_bridge__$Vec_Speck$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Speck$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Speck(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<SpeckRef> {
        let pointer = __swift_bridge__$Vec_Speck$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return SpeckRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<SpeckRefMut> {
        let pointer = __swift_bridge__$Vec_Speck$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return SpeckRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Speck$len(vecPtr)
    }
}



