//
//  ProfileView.swift
//  Task_Manager
//
//  Created by eyh.mac on 8.01.2024.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var user: Users?
    @State private var editableUser: Users  // For editing fields
    @State private var showUpdateEmailSheet = false  // State for email update sheet
    @State private var showUpdatePasswordSheet = false  // State for password update sheet
    @Environment(\.presentationMode) var presentationMode

    init(taskManager: TaskManager) {
        self._taskManager = ObservedObject(wrappedValue: taskManager)
        self._editableUser = State(initialValue: Users(name: "", surname: "", email: "", departmant: "", password: "", userId: nil)) // Initialize with empty fields
    }

    var body: some View {
        NavigationView {
            VStack {
                if let user = user {
                    Form {
                        Section(header: Text("Personal Information")) {
                            TextField("Name", text: $editableUser.name)
                            TextField("Surname", text: $editableUser.surname)
                            TextField("Department", text: $editableUser.departmant)
                        }
                        Section {
                            Button("Update Profile") {
                                taskManager.updateUserProfile(editableUser) { success, errorMessage in
                                    if success {
                                        // Handle successful update
                                        print("Profile updated successfully.")
                                        presentationMode.wrappedValue.dismiss()
                                    } else {
                                        // Handle error
                                        print("Failed to update profile: \(errorMessage ?? "Unknown error")")
                                    }
                                }
                            }
                            .bold()
                            .foregroundColor(.blue)
                        }
                        Section {
                            Button(action: {
                                taskManager.signOut()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Sign Out")
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "x.circle.fill")
                    .foregroundColor(.brown)
            })
            .onAppear {
                taskManager.getAuthorizedUserData { fetchedUser in
                    self.user = fetchedUser
                    self.editableUser = fetchedUser ?? Users(name: "", surname: "", email: "", departmant: "", password: "", userId: nil)
                }
            }
        }
    }
}
