package com.nexora.miro.services

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class AutoGrantService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        
        // Texte exact du bouton selon la langue d'Android
        val targetTexts = listOf("Start now", "Démarrer maintenant", "Commencer", "start")
        
        val rootNode = rootInActiveWindow ?: return
        
        for (text in targetTexts) {
            val nodes = rootNode.findAccessibilityNodeInfosByText(text)
            if (nodes != null && nodes.isNotEmpty()) {
                for (node in nodes) {
                    // Vérifie si c'est un bouton cliquable ou s'il faut cliquer sur le parent
                    if (node.isClickable) {
                        node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        return
                    } else if (node.parent?.isClickable == true) {
                        node.parent?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        return
                    }
                }
            }
        }
    }

    override fun onInterrupt() {}
}