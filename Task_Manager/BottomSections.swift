//
//  BottomSections.swift
//  TaskManagerApp
//
//  Created by eyh.mac on 7.01.2024.
//

import SwiftUI

// SwiftUI view struct representing bottom sections with tabs
struct BottomSections: View {
    var body: some View {
        // TabView to display different sections
        TabView {
            // First tab for displaying the list of tasks
            TasksList(taskManager: TaskManager())
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait.fill") // Icon for the tab
                }
            
            // Second tab for displaying completed tasks
            CompletedTasks(taskManager: TaskManager())
                .tabItem {
                    Image(systemName: "text.badge.checkmark") // Icon for the tab
                }
            
            // Third tab for displaying expired tasks
            ExpiredTasks(taskManager: TaskManager())
                .tabItem {
                    Image(systemName: "xmark.app.fill") // Icon for the tab
                }
        }
        .accentColor(.brown)
    }
}

