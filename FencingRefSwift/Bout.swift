//
//  Bout.swift
//  FencingRefSwift
//
//  Created by Jason DuPertuis on 4/19/15.
//  Copyright (c) 2015 jdp. All rights reserved.
//

import Foundation

/** The main manager of a bout. */
public class Bout {
    
    /** Types of penalty cards */
    public enum Card {
        case None
        case Yellow
        case Red
        case Black
    }
    
    /** Data about each fencer in the bout */
    struct BoutData {
        private var m_iLeftScore:UInt8;
        private var m_iRightScore:UInt8;
        
        /** The score for the left fencer */
        var leftScore:UInt8 {
            get { return m_iLeftScore; }
            set {
                m_iLeftScore = newValue;
                
                if m_iLeftScore < 0 {
                    m_iLeftScore = 0;
                }
            }
        }
        
        /** The score for the right fencer */
        var rightScore:UInt8 {
            get { return m_iRightScore; }
            set {
                m_iRightScore = newValue;
                
                if m_iRightScore < 0 {
                    m_iRightScore = 0;
                }
            }
        }
        
        private var m_leftCard:Card;
        private var m_rightCard:Card;
        
        /** The current card of the left fencer */
        var leftCard:Card {
            get { return m_leftCard; }
            set {
                if newValue == Card.Yellow && m_leftCard == Card.Yellow {
                    m_leftCard = Card.Red;
                } else {
                    m_leftCard = newValue;
                }
                
                if (m_leftCard == Card.Red) {
                    m_iRightScore++;
                }
            }
        }
        
        /** The current card of the right fencer */
        var rightCard:Card {
            get { return m_rightCard; }
            set {
                if newValue == Card.Yellow && m_rightCard == Card.Yellow {
                    m_rightCard = Card.Red;
                } else {
                    m_rightCard = newValue;
                }
                
                if (m_rightCard == Card.Red) {
                    m_iLeftScore++;
                }
            }
        }
        
        init() {
            m_iLeftScore = 0;
            m_iRightScore = 0;
            m_leftCard = Card.None;
            m_rightCard = Card.None;
        }
    }
    
    /** Data on events that happen during the bout */
    struct BoutEvent {
        var m_time:Float;
        var m_leftScore:UInt8;
        var m_rightScore:UInt8;
        var m_sMessage:String;
        
        init(time:Float, leftScore:UInt8, rightScore:UInt8, sMessage:String) {
            m_time = time;
            m_leftScore = leftScore;
            m_rightScore = rightScore;
            m_sMessage = sMessage;
        }
    }
    
    /** Log of events that occur during the bout */
    var m_boutEvents:[BoutEvent];
    
    var m_viewController:BoutViewController;
    
    /** Fencer data for the current bout */
    var m_boutData:BoutData;
    
    /** The current period */
    var m_iPeriod:UInt8;
    
    /** The bout timer */
    var m_timer:Timer?;
    
    /** The default bout time */
    var m_fDefaultTime:Float;
    
    public var leftScore:UInt8 {
        return m_boutData.leftScore;
    }
    
    public var rightScore:UInt8 {
        return m_boutData.rightScore;
    }
    
    init(boutTime fTime:Float, view vc:BoutViewController) {
        m_viewController = vc;
        m_boutData = BoutData();
        m_fDefaultTime = fTime;
        m_iPeriod = 1;
        m_boutEvents = [BoutEvent]();
        
        m_timer = Timer(countdownFrom: fTime, withInterval: 0.1, tickCallback: onTimerTick, finishCallback: onTimerFinish);
        
        vc.setCurrentTime(currentTime: fTime);
        vc.setLeftScore(score: 0);
        vc.setRightScore(score: 0);
    }
    
    // MARK: - Bout actions
    
    /** Begin running the timer */
    public func start() {
        m_timer?.start();
    }
    
    /** Stop the timer */
    public func halt() {
        m_timer?.stop();
    }
    
    public func toggleTimer() {
        m_timer?.toggle();
    }
    
    /** 
    Score touch for fencer on the left
    */
    public func touchLeft() {
        m_boutData.leftScore++;
        m_viewController.setLeftScore(score: m_boutData.leftScore);
        
        recordBoutEvent("Left scores");
    }
    
    public func reverseTouchLeft() {
        m_boutData.leftScore--;
        m_viewController.setLeftScore(score: m_boutData.leftScore);
    }
    
    /** 
    Score touch for fencer on the right 
    */
    public func touchRight() {
        m_boutData.rightScore++;
        m_viewController.setRightScore(score: m_boutData.rightScore);
        
        recordBoutEvent("Right scores");
    }
    
    public func reverseTouchRight() {
        m_boutData.rightScore--;
        m_viewController.setRightScore(score: m_boutData.rightScore);
    }
    
    /** 
    Score a double touch, if allowed by the bout type 
    */
    public func touchDouble() {
        m_boutData.leftScore++;
        m_boutData.rightScore++;
        
        m_viewController.setLeftScore(score: m_boutData.leftScore);
        m_viewController.setRightScore(score: m_boutData.rightScore);
        
        recordBoutEvent("Double-touch");
    }
    
    public func cardLeft(card:Card) {
        m_boutData.leftCard = card;
        m_viewController.setLeftCard(m_boutData.leftCard);
        m_viewController.setRightScore(score: m_boutData.rightScore);
    }
    
    public func cardRight(card:Card) {
        m_boutData.rightCard = card;
        m_viewController.setRightCard(m_boutData.rightCard);
        m_viewController.setLeftScore(score: m_boutData.leftScore);
    }
    
    // MARK: - Bout management
    
    /** Reset the bout to its default state */
    func resetToDefault() {
        m_boutData = BoutData();
        m_timer?.currentTime = m_fDefaultTime;
        
        m_viewController.setLeftScore(score: m_boutData.leftScore);
        m_viewController.setRightScore(score: m_boutData.rightScore);
        m_viewController.setCurrentTime(currentTime: m_fDefaultTime);
    }
    
    // MARK: - Internals
    
    /**
    Record a message into the bout history
    
    :sMessage: The message to record. Timestamp and scores are automatically added.
    */
    private func recordBoutEvent(sMessage:String) {
        var time:Float? = m_timer?.currentTime;
        var event:BoutEvent = BoutEvent(time: time!, leftScore: m_boutData.leftScore, rightScore: m_boutData.rightScore, sMessage: sMessage);
        m_boutEvents.append(event);
    }
    
    // MARK: - Timer handling
    
    /** 
    Called on each tick of the timer.
    
    :fTimerValue: The value of the timer after the tick
    */
    func onTimerTick(fTimerValue:Float) {
        m_viewController.setCurrentTime(currentTime: fTimerValue);
    }
    
    /** Called by the timer when completed. */
    func onTimerFinish() {
        m_viewController.setCurrentTime(currentTime: 0);
        m_viewController.stopTimer();
    }
}