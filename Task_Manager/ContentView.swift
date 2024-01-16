//
//  ContentView.swift
//  Task_Manager
//
//  Created by eyh.mac on 7.01.2024.
//

import SwiftUI

struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingLogin = true
    @StateObject var taskManager: TaskManager
    @State private var isShowingAddTaskSheet = false
    @State private var user: Users?
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            if taskManager.currentUser != nil {
                    BottomSections()
                        .navigationTitle("Task Management")
                        .navigationBarTitleDisplayMode(.inline)
                        .sheet(isPresented: $isShowingAddTaskSheet) {
                            AddTaskView(isPresented: $isShowingAddTaskSheet) { title, details, color, type, progress, deadline, fileURL in
                                taskManager.addTask(title: title, details: details, color: color, type: type, progress: progress, deadline: deadline, fileURL: fileURL)
                            }
                        }
                        .navigationBarItems(
                            leading: Image(systemName: "person.circle.fill")
                                .foregroundColor(.brown)
                                .contextMenu(menuItems: {
                                    VStack {
                                        Text("\(user?.name ?? "") \(user?.surname ?? "")")
                                            .bold()
                                        Button {
                                            showingProfile = true
                                        } label: {
                                            Text("View Profile")
                                        }
                                        Button {
                                            taskManager.signOut()
                                        } label: {
                                            Text("Sign Out")
                                        }
                                    }
                                }),
                            trailing: Button(action: {
                                isShowingAddTaskSheet.toggle()
                            }) {
                                Label {
                                    Text("Add Task")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                    
                                } icon: {
                                    Image(systemName: "plus.app.fill")
                                }
                                .foregroundColor(.white)
                                .padding(5)
                                .background(.brown , in:Capsule())
                            }
                        )
                
            } else {
                VStack {
                    AuthView(taskManager: taskManager)
                }
                .padding()
                .navigationTitle("Authentication")
            }
                
        }
        .fullScreenCover(isPresented: $showingProfile, onDismiss: { taskManager.getAuthorizedUserData { fetchedUser in
            self.user = fetchedUser
        }}) {
            ProfileView(taskManager: taskManager)
        }
        .onAppear {
            taskManager.getAuthorizedUserData { fetchedUser in
                self.user = fetchedUser
            }
        }
        .accentColor(.white)
    }
}
