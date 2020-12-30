//
//  main.swift
//  Test
//
//  Created by Cantin Xu on 2020/12/23.
//

import Foundation
import AppKit
import CoreGraphics
import CoreFoundation
import Carbon.HIToolbox


let app = NSApplication.shared
var touchHash = [Int:NSTouch]()
let clickThreshold = 0.15 //150ms
var hasTouchEffect = false

func keyboardKeyDown(key: CGKeyCode) {
    let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
    let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
    event?.post(tap: CGEventTapLocation.cghidEventTap)
    print("key \(key) is down")
}
//松开按键
func keyboardKeyUp(key: CGKeyCode) {
    let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
    let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
    event?.post(tap: CGEventTapLocation.cghidEventTap)
    print("key \(key) is released")
}

func cmdShiftPress(key: CGKeyCode) {
    let cmd_shift_down = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: true);
    cmd_shift_down?.flags = CGEventFlags(rawValue: (CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue))
    cmd_shift_down?.post(tap: CGEventTapLocation.cghidEventTap);

    let cmd_shift_up = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: false);
    cmd_shift_up?.flags = CGEventFlags(rawValue: (CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue))
    cmd_shift_up?.post(tap: CGEventTapLocation.cghidEventTap);
}

func cmdPress(key: CGKeyCode) {
    let cmd_shift_down = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: true);
    cmd_shift_down?.flags = CGEventFlags(rawValue: (CGEventFlags.maskCommand.rawValue))
    cmd_shift_down?.post(tap: CGEventTapLocation.cghidEventTap);

    let cmd_shift_up = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: false);
    cmd_shift_up?.flags = CGEventFlags(rawValue: (CGEventFlags.maskCommand.rawValue))
    cmd_shift_up?.post(tap: CGEventTapLocation.cghidEventTap);
}

func cmdClick(event: CGEvent) {
    let cmd_down = CGEvent(keyboardEventSource: nil, virtualKey: 0x37, keyDown: true);
    cmd_down?.flags = CGEventFlags(rawValue: (CGEventFlags.maskCommand.rawValue))
    cmd_down?.post(tap: CGEventTapLocation.cgSessionEventTap);

    let mouseDown = CGEvent(mouseEventSource: nil,
                        mouseType: .leftMouseDown,
                        mouseCursorPosition: event.location,
                        mouseButton: .left
                        )
    mouseDown?.post(tap: .cgSessionEventTap)


    let mouseUp = CGEvent(mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: event.location,
            mouseButton: .left
            )
    mouseUp?.post(tap: .cgSessionEventTap)

    let cmd_up = CGEvent(keyboardEventSource: nil, virtualKey: 0x37, keyDown: false);
    cmd_up?.flags = CGEventFlags(rawValue: (CGEventFlags.maskCommand.rawValue))
    cmd_up?.post(tap: CGEventTapLocation.cgSessionEventTap);
}



class AppDelegate: NSObject, NSApplicationDelegate, NSGestureRecognizerDelegate {
    let window = NSWindow(contentRect: NSMakeRect(200, 200, 400, 200),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false,
                          screen: nil)


    public func checkAccess() -> Bool{
        //get the value for accesibility
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        //set the options: false means it wont ask
        //true means it will popup and ask
        let options = [checkOptPrompt: true]
        //translate into boolean value
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        return accessEnabled
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {

            // ignore mouseup if has multiple touches
            if (type == CGEventType.leftMouseUp) {
                //debugPrint((NSEvent(cgEvent:event)!))
                if (touchHash.count > 1) {
                    // true means multiple touches on trackpad, we can use it on the first touch end event later.
                    hasTouchEffect = true
                    return nil
                }
            }

            if (type.rawValue == 29) {
                let s = NSEvent(cgEvent: event)
                let touches = s!.allTouches()
                //debugPrint(touches)

                for case let touch in touches {
                    // the first touch end event occurs right after mouseUp event
                    // So we check the touchEffect here and set it back to false
                    var touchEffect = false
                    if (touch.phase == .ended || touch.phase == .cancelled) {
                        touchEffect = hasTouchEffect
                        hasTouchEffect = false
                    }

                    if (touch.type == .direct) {
                        continue  //touch from the touch bar
                    }

                    if (touchHash[touch.identity.hash] != nil) {
                        if (touch.phase == .ended || touch.phase == .cancelled) {
                            touchHash.removeValue(forKey: touch.identity.hash)
                        }

                        if (touch.phase == .ended) {
                            let stationaryTouches = touches.filter { touch in
                                switch touch.phase {
                                    case .stationary:
                                        return true
                                    case .moved:
                                         let beganTouch = (touchHash[touch.identity.hash])!
                                         return abs(beganTouch.normalizedPosition.x - touch.normalizedPosition.x) < 0.05 && abs(beganTouch.normalizedPosition.y - touch.normalizedPosition.y) < 0.05
                                    default:
                                    return false
                                }
                            }
                            let leftStationaryTouches = stationaryTouches.filter { t in
                                return t.normalizedPosition.x < touch.normalizedPosition.x
                            }

                            // do nothing when release the not clicking touch
                            //if (multipleTouchesClick || (beganTime != nil && abs((beganTime?.timeIntervalSinceNow)!) > clickThreshold)) {
                            //} else {
                            if (touchEffect) {
                                if stationaryTouches.count == 2 {
                                    switch leftStationaryTouches.count {
                                    case 0:
                                        //left click
                                        debugPrint("left")
                                        cmdClick(event: event)
                                    case 1:
                                        debugPrint("Middle")
                                        cmdPress(key: 0x0D) //press cmd + w
                                    case 2:
                                        debugPrint("right")
                                    default: break
                                    }

                                } else {
                                    if stationaryTouches.count == 1 {
                                        if leftStationaryTouches.count == 1 {
                                            debugPrint("press }")
                                            cmdShiftPress(key: 0x1e) //press cmd + }
                                        } else {
                                            debugPrint("press {")
                                            cmdShiftPress(key: 0x21) //press cmd  + {
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if touch.phase == .began {
                        touchHash[touch.identity.hash] = touch
                    }


                    //debugPrint(touch)
                }
            }

            return Unmanaged.passRetained(event)
        }

        //        NSEventMask eventMask = NSEventMaskGesture|NSEventMaskMagnify|NSEventMaskSwipe|NSEventMaskRotate|NSEventMaskBeginGesture|NSEventMaskEndGesture
        //kCGEventMaskForAllEvents
        // debugPrint(CGEventType.leftMouseDown.rawValue)
        //debugPrint(1 << NX_ALLEVENTS)

        //        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue) | (1 << CGEventType.leftMouseDragged.rawValue)
        // debugPrint(CGEventType.leftMouseDown.rawValue)
        //debugPrint(NX_SUBTYPE_MOUSE_TOUCH)


        // debugPrint(NSEvent.EventTypeMask.leftMouseDown.rawValue)


        debugPrint(checkAccess())
        //let eventMask =  4294967295 // kCGEventMaskForAllEvents, copied from Obj-C header file
        //let eventMask = 1 << 29 // NSEventTypeGesture is 29, copied from Obj-C header file
        let eventMask = (1 << 29) | (1 << CGEventType.leftMouseUp.rawValue)
        guard let eventTap = CGEvent.tapCreate(tap: .cghidEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: CGEventMask(eventMask),
                                               callback: myCGEventCallback,
                                               userInfo: nil) else {
            print("failed to create event tap")
            exit(1)
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()


        //        NSEvent.addGlobalMonitorForEvents(
        //            matching: [],
        //             handler: { (event: NSEvent) in
        //                event.allTouches()
        //                debugPrint(event)
        ////                if event.keyCode == 0 {
        ////                    self.press(key: 0x1e) //press }
        ////                }
        ////                if event.keyCode == 1 {
        ////                    self.press(key: 0x21) //press {
        ////                }
        //             }
        //           )

        //        NSEvent.addGlobalMonitorForEvents(
        //            matching: [NSEvent.EventTypeMask.keyUp],
        //             handler: { (event: NSEvent) in
        //                debugPrint(event.keyCode)
        //                if event.keyCode == 0 {
        //                    self.press(key: 0x1e) //press }
        //                }
        //                if event.keyCode == 1 {
        //                    self.press(key: 0x21) //press {
        //                }
        //             }
        //           )
    }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()



