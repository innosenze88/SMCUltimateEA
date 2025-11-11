//+------------------------------------------------------------------+
//| SMC Ultimate EA - State Manager Module                           |
//+------------------------------------------------------------------+

#ifndef _STATE_MANAGER_MQH_
#define _STATE_MANAGER_MQH_

#include "..\Utilities\Config.mqh"
#include "..\Utilities\Utils.mqh"

//+------------------------------------------------------------------+
//| State Manager Class - Controls EA state transitions               |
//+------------------------------------------------------------------+
class StateManager
{
private:
    STATE m_currentState;
    STATE m_previousState;
    datetime m_stateChangeTime;
    int m_stateCounter;
    bool m_stateChanged;

public:
    StateManager()
        : m_currentState(IDLE), m_previousState(IDLE),
          m_stateChangeTime(TimeCurrent()), m_stateCounter(0),
          m_stateChanged(false) {}

    //+------------------------------------------------------------------+
    //| Initialize State Manager                                          |
    //+------------------------------------------------------------------+
    void Initialize()
    {
        m_currentState = IDLE;
        m_previousState = IDLE;
        m_stateChangeTime = TimeCurrent();
        m_stateCounter = 0;
        m_stateChanged = true;

        Logger::Info("State Manager initialized. Starting state: IDLE");
    }

    //+------------------------------------------------------------------+
    //| Get Current State                                                 |
    //+------------------------------------------------------------------+
    STATE GetCurrentState() const
    {
        return m_currentState;
    }

    //+------------------------------------------------------------------+
    //| Get Previous State                                                |
    //+------------------------------------------------------------------+
    STATE GetPreviousState() const
    {
        return m_previousState;
    }

    //+------------------------------------------------------------------+
    //| Check if state changed                                            |
    //+------------------------------------------------------------------+
    bool HasStateChanged() const
    {
        return m_stateChanged;
    }

    //+------------------------------------------------------------------+
    //| Get state duration in seconds                                     |
    //+------------------------------------------------------------------+
    int GetStateDuration() const
    {
        return (int)(TimeCurrent() - m_stateChangeTime);
    }

    //+------------------------------------------------------------------+
    //| Transition to new state                                           |
    //+------------------------------------------------------------------+
    void TransitionTo(STATE newState)
    {
        if (newState == m_currentState)
        {
            m_stateChanged = false;
            m_stateCounter++;
            return;
        }

        m_previousState = m_currentState;
        m_currentState = newState;
        m_stateChangeTime = TimeCurrent();
        m_stateChanged = true;
        m_stateCounter = 0;

        Logger::Info("State transition: " + GetStateName(m_previousState) +
                    " -> " + GetStateName(m_currentState));
    }

    //+------------------------------------------------------------------+
    //| Get State Name                                                    |
    //+------------------------------------------------------------------+
    string GetStateName(STATE state) const
    {
        switch (state)
        {
            case IDLE:                   return "IDLE";
            case SCANNING_MARKET:        return "SCANNING_MARKET";
            case STRUCTURE_ANALYSIS:     return "STRUCTURE_ANALYSIS";
            case CONFIRMATION_PENDING:   return "CONFIRMATION_PENDING";
            case ENTRY_SETUP:            return "ENTRY_SETUP";
            case POSITION_MANAGEMENT:    return "POSITION_MANAGEMENT";
            case EXIT_ANALYSIS:          return "EXIT_ANALYSIS";
            case RISK_CHECK:             return "RISK_CHECK";
            default:                     return "UNKNOWN";
        }
    }

    //+------------------------------------------------------------------+
    //| Check if we should transition to SCANNING_MARKET                  |
    //+------------------------------------------------------------------+
    bool ShouldStartScanning()
    {
        if (m_currentState != IDLE)
            return false;

        if (!TimeUtils::IsTradingTime())
            return false;

        if (PositionUtils::GetOpenPositions() > 0)
            return false;

        return true;
    }

    //+------------------------------------------------------------------+
    //| Check if we should analyze structure                              |
    //+------------------------------------------------------------------+
    bool ShouldAnalyzeStructure()
    {
        if (m_currentState != SCANNING_MARKET)
            return false;

        if (m_stateCounter < 2)  // Give some bars before analyzing
            return false;

        return true;
    }

    //+------------------------------------------------------------------+
    //| Check if we should wait for confirmation                          |
    //+------------------------------------------------------------------+
    bool ShouldWaitForConfirmation(SIGNAL_TYPE signal)
    {
        if (m_currentState != STRUCTURE_ANALYSIS)
            return false;

        if (signal == SIGNAL_NONE)
            return false;

        return true;
    }

    //+------------------------------------------------------------------+
    //| Check if signal is confirmed                                      |
    //+------------------------------------------------------------------+
    bool IsSignalConfirmed(double confidence, int confirmedBars)
    {
        if (m_currentState != CONFIRMATION_PENDING)
            return false;

        // Signal confirmed if confidence > threshold and enough bars passed
        if (confidence >= CONFIRMATION_THRESHOLD && confirmedBars >= SIGNAL_BARS)
            return true;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Check if we should setup entry                                    |
    //+------------------------------------------------------------------+
    bool ShouldSetupEntry()
    {
        if (m_currentState != CONFIRMATION_PENDING)
            return false;

        return true;
    }

    //+------------------------------------------------------------------+
    //| Check if position is open                                         |
    //+------------------------------------------------------------------+
    bool IsPositionOpen()
    {
        return PositionUtils::GetOpenPositions() > 0;
    }

    //+------------------------------------------------------------------+
    //| Check if we should manage position                                |
    //+------------------------------------------------------------------+
    bool ShouldManagePosition()
    {
        if (m_currentState != ENTRY_SETUP && m_currentState != POSITION_MANAGEMENT)
            return false;

        if (!IsPositionOpen())
            return false;

        return true;
    }

    //+------------------------------------------------------------------+
    //| Check if we should analyze exit                                   |
    //+------------------------------------------------------------------+
    bool ShouldAnalyzeExit()
    {
        if (m_currentState != POSITION_MANAGEMENT)
            return false;

        if (GetStateDuration() < 5)  // Wait at least 5 seconds in position
            return false;

        return true;
    }

    //+------------------------------------------------------------------+
    //| Check if we should return to IDLE                                 |
    //+------------------------------------------------------------------+
    bool ShouldReturnToIdle()
    {
        if (m_currentState != EXIT_ANALYSIS)
            return false;

        if (!IsPositionOpen())
            return true;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Check if risk check is needed                                     |
    //+------------------------------------------------------------------+
    bool ShouldCheckRisk()
    {
        if (TimeUtils::IsDailyLimitReached(PositionUtils::GetTradesToday()))
            return true;

        if (!TimeUtils::IsTradingTime())
            return true;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Get state machine status as string                                |
    //+------------------------------------------------------------------+
    string GetStatusString()
    {
        string status = "State: " + GetStateName(m_currentState) +
                       " | Duration: " + IntegerToString(GetStateDuration()) + "s" +
                       " | Counter: " + IntegerToString(m_stateCounter);

        if (m_stateChanged)
            status += " | [STATE CHANGED]";

        return status;
    }
};

#endif
