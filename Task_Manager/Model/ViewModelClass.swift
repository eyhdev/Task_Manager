//
//  ViewModelClass.swift
//  TaskManagerApp
//
//  Created by eyh.mac on 7.01.2024.
//

import Foundation
import FirebaseFirestore
import Firebase
import FirebaseStorage
// Define a Task struct conforming to Identifiable and Codable
struct Task: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var details: String
    var color: String
    var type: String
    var deadline: Date
    var isDone: Bool
    var createdTime: String  // New property
    var userId: String?
    var progress: Int
    var fileURL: String?
}

// Define a Users struct conforming to Codable
struct Users: Codable {
    var name: String
    var surname: String
    var email: String
    var departmant: String
    var password: String
    var userId: String?
}

// Define a TaskManager class as ObservableObject
class TaskManager: ObservableObject {
    @Published var tasks: [Task] = [] // Published property for updating UI
    private let db = Firestore.firestore() // Firestore database instance
    private let auth = Auth.auth() // Firebase authentication instance
    
    // Computed property to get the current authenticated user
    var currentUser: User? {
        return auth.currentUser
    }
    
    // Function to sign in a user with email and password
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        auth.signIn(withEmail: email, password: password) { _, error in
            completion(error == nil)
        }
    }
    
    // Function to sign up a new user
    func signUp(users: Users, completion: @escaping (Bool) -> Void) {
        auth.createUser(withEmail: users.email, password: users.password) { result, error in
            guard let user = result?.user, error == nil else {
                completion(false)
                return
            }
            
            var newUser = users
            newUser.userId = user.uid
            
            do {
                // Save user details to Firestore
                _ = try self.db.collection("users").document(user.uid).setData(from: newUser)
                completion(true)
            } catch {
                print("Error saving user details: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    // Function to sign out the current user
    func signOut() {
        do {
            try auth.signOut()
            tasks.removeAll()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    func getAuthorizedUserData(completion: @escaping (Users?) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(nil)
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: Users.self)
                    completion(user)
                } catch {
                    print("Error decoding user: \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                print("User not found or error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }

    
    func updateUserProfile(_ updatedUser: Users, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(false, "User not logged in")
            return
        }

        db.collection("users").document(userId).setData(["name": updatedUser.name, "surname": updatedUser.surname, "email": updatedUser.email, "departmant": updatedUser.departmant], merge: true) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }


    // Function to fetch tasks for the current authenticated user
    func fetchTasks() {
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("tasks")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Update tasks array with fetched data
                self.tasks = documents.compactMap { document in
                    do {
                        return try document.data(as: Task.self)
                    } catch {
                        print("Error decoding task: \(error.localizedDescription)")
                        return nil
                    }
                }
            }
    }
    
    func addTask(title: String, details: String, color: String, type: String, progress: Int, deadline: Date, fileURL: URL?) {
        guard let userId = auth.currentUser?.uid else { return }

        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let createdTime = dateFormatter.string(from: Date())

            var newTask = Task(title: title, details: details, color: color, type: type, deadline: deadline, isDone: false, createdTime: createdTime, userId: userId, progress: progress)

            // Upload file to Firebase Storage
            if let fileURL = fileURL {
                let storageRef = Storage.storage().reference().child("taskFiles/\(UUID().uuidString).pdf")
                storageRef.putFile(from: fileURL, metadata: nil) { _, error in
                    if let error = error {
                        print("Error uploading file: \(error.localizedDescription)")
                        return
                    }

                    // File uploaded successfully, update task with file URL
                    storageRef.downloadURL { url, error in
                        if let downloadURL = url {
                            newTask.fileURL = downloadURL.absoluteString
                            _ = try? self.db.collection("tasks").addDocument(from: newTask)
                        }
                    }
                }
            } else {
                // No file selected, add task without file
                _ = try? self.db.collection("tasks").addDocument(from: newTask)
            }
        } catch {
            print("Error adding task: \(error.localizedDescription)")
        }
    }


    // Function to toggle the status of a task (done or not done)
    func toggleTaskStatus(_ task: Task) {
        guard let documentID = task.id else { return }
        
        let updatedStatus = !task.isDone
        // Update task status in Firestore
        db.collection("tasks").document(documentID).updateData(["isDone": updatedStatus]) { error in
            if let error = error {
                print("Error updating task status: \(error.localizedDescription)")
            }
        }
    }
    
    // Function to edit the details of a task
    func editTask(_ task: Task, with title: String, details: String, color: String, type: String, progress: Int, deadline: Date, createdTime: String) {
        guard let documentID = task.id else { return }
        
        // Create an updated task and update it in Firestore
        let updatedTask = Task(id: documentID, title: title, details: details, color: color, type: type, deadline: deadline, isDone: task.isDone, createdTime: createdTime, userId: task.userId, progress: progress)
        
        do {
            try db.collection("tasks").document(documentID).setData(from: updatedTask, merge: true)
        } catch {
            print("Error updating task: \(error.localizedDescription)")
        }
    }
    
    // Function to delete a task
    func deleteTask(_ task: Task) {
        guard let documentID = task.id else { return }
        
        // Delete task from Firestore
        db.collection("tasks").document(documentID).delete { error in
            if let error = error {
                print("Error deleting task: \(error.localizedDescription)")
            }
        }
    }
}

