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


let app = NSApplication.shared
var touchHash = [Int:NSTouch]()
var threeTouchedFlag = false
var touchesTimestamp = [Int:Date]()
let clickThreshold = 0.1 //100ms

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

            if (type.rawValue == 29) {
                let s = NSEvent(cgEvent: event)
                let touches = s?.allTouches()

                for case let touch in touches ?? [] {
                    //debugPrint(touch.normalizedPosition)
                    if (touch.type == .direct) {
                        continue  //touch from the touch bar
                    }

                    if (touchHash[touch.identity.hash] != nil) {
                        let beganTime = touchesTimestamp[touch.identity.hash]

                        if (touch.phase == .ended || touch.phase == .cancelled) {
                            touchHash.removeValue(forKey: touch.identity.hash)
                            touchesTimestamp.removeValue(forKey: touch.identity.hash)
                        } else {
                            /*if (touch.phase == .moved) {*/
                                /*if (abs(touch.normalizedPosition.y - (t?.normalizedPosition.y)!) > 0.005 || abs(touch.normalizedPosition.x - (t?.normalizedPosition.x)!) > 0.005) {*/
                                    /*touchHash.removeValue(forKey: touch.identity.hash)*/
                                /*}*/
                            /*}*/
                        }


                        if (touch.phase == .ended) {
                            let stationaryTouches = touchHash.filter { key, touch in
                                return touch.phase == .stationary
                            }
                            let leftStationaryTouches = stationaryTouches.filter { key, t in
                                return t.normalizedPosition.x < touch.normalizedPosition.x
                            }

                            /*if (stationaryTouches.count == 2) {*/
                                /*threeTouchedFlag = true*/
                            /*}*/

                            // do nothing when release not clicking touch
                            if (beganTime != nil && abs((beganTime?.timeIntervalSinceNow)!) > clickThreshold) {

                            } else {

                                if stationaryTouches.count == 2 {
                                    switch leftStationaryTouches.count {
                                    case 0:
                                        //right click
                                        debugPrint("left")
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
                                            //                                             debugPrint("press }")
                                            cmdShiftPress(key: 0x1e) //press cmd + }
                                        } else {
                                            //                                            debugPrint("press {", stationaryTouches)
                                            cmdShiftPress(key: 0x21) //press cmd  + {
                                        }
                                    }
                                }
                            }



                            //                            debugPrint(touchHash.count)
                            if touchHash.count == 0 {
                                threeTouchedFlag = false
                            }
                        }
                    }

                    if touch.phase == .began || touchHash[touch.identity.hash] != nil {
                        touchesTimestamp[touch.identity.hash] = Date()
                        touchHash[touch.identity.hash] = touch
                    }


                    //debugPrint(touch)
                    //                    debugPrint(touch.identity)
                    //                    debugPrint(touch.phase)
                    //                    debugPrint(touch.normalizedPosition)
                }
            }
            //            let s  = NSEvent(cgEvent: event)
            //            debugPrint(s)

            //debugPrint("GOOD")
            //if [.keyDown , .keyUp].contains(type) {

            //if (e != nil) {
            //                debugPrint(e?.phase ?? "")
            //}


            //                event
            //                var keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            //                if keyCode == 0 {
            //                    keyCode = 6
            //                } else if keyCode == 6 {
            //                    keyCode = 0
            //                }
            //                event.setIntegerValueField(.keyboardEventKeycode, value: keyCode)
            // }
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
        let eventMask = 1 << 29 // NSEventTypeGesture is 29, copied from Obj-C header file
        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
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
//NSView.init().allowedTouchTypes |= NSTouchTypeMaskIndirect
app.delegate = delegate
app.run()


