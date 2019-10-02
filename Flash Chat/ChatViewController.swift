//
//  ViewController.swift
//  Flash Chat
//
//  Created by Angela Yu on 29/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    // empty array of messages
    var messageArray: [Message] = [Message]()
    
    // We've pre-linked the IBOutlets
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var messageTextfield: UITextField!
    @IBOutlet var messageTableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set yourself as the delegate and datasource here:
        messageTableView.delegate = self
        messageTableView.dataSource = self
        
        // Set yourself as the delegate of the text field here:
        messageTextfield.delegate = self
        
        // Set the tapGesture here
        // the selector is the method that gets triggered when tapping on self (the table view)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        messageTableView.addGestureRecognizer(tapGesture)

        // Register your MessageCell.xib file here:
        messageTableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")
        
        configureTableView()
        retrieveMessages()
        messageTableView.separatorStyle = .none
        
    }

    ///////////////////////////////////////////
    
    //MARK: - TableView DataSource Methods
    
    
    
    // Declare cellForRowAtIndexPath here:
    // in this method we provide the cells that are going to be displayed in the Table View
    // this method gets called for every single row in the Table View
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // blank cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
        
        // set the Custom Cell
        cell.messageBody.text = messageArray[indexPath.row].messageBody
        cell.senderUsername.text = messageArray[indexPath.row].sender
        cell.avatarImageView.image = UIImage(named: "egg")
        
        if cell.senderUsername.text == Auth.auth().currentUser?.email as String? {
            cell.avatarImageView.backgroundColor = UIColor.flatMint()
            cell.messageBackground.backgroundColor = UIColor.flatSkyBlue()
        } else {
            cell.avatarImageView.backgroundColor = UIColor.flatWatermelon()
            cell.messageBackground.backgroundColor = UIColor.flatGray()
        }
        
        return cell
    }
    
    
    // Declare numberOfRowsInSection here:
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArray.count
    }
    
    
    // Declare tableViewTapped here:
    @objc func tableViewTapped() {
        // this method will call internally the textFieldDidEndEditing
        messageTextfield.endEditing(true)
    }
    
    
    // Declare configureTableView here:
    func configureTableView() {
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTableView.estimatedRowHeight = 120.0
    }
    
    
    ///////////////////////////////////////////
    
    //MARK:- TextField Delegate Methods

    
    // Declare textFieldDidBeginEditing here:
    // triggered whenever you touch inside the text field
    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    
    
    // Declare textFieldDidEndEditing here:
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.5, animations: {
            // we hide the keyboard
            self.heightConstraint.constant = 50
            // update the view
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            var keyboardHeight = keyboardRectangle.height

            if #available(iOS 11.0, *) {
                let bottomInset = view.safeAreaInsets.bottom
                keyboardHeight -= bottomInset
            }
            
            // create the animation
            UIView.animate(withDuration: 0.5) {
                // modify the constraint
                self.heightConstraint.constant = CGFloat(50 + keyboardHeight)
                self.view.layoutIfNeeded() //if view change, redraw
            }
        }
    }
    
    ///////////////////////////////////////////
    
    
    //MARK: - Send & Recieve from Firebase
    
    
    
    
    
    @IBAction func sendPressed(_ sender: AnyObject) {
        // collapse the keyboard
        messageTextfield.endEditing(true)
        
        // Send the message to Firebase and save it in our database
        
        // Temporarly disable the send button and the text field
        messageTextfield.isEnabled = false
        sendButton.isEnabled = false
        
        // create a new database inside our main database dedicated to messages
        let messageDB = Database.database().reference().child("Messages")
        
        // we build the message as a dictionary
        let messageDictionary = [
            "Sender": Auth.auth().currentUser?.email,
            "MessageBody": messageTextfield.text!
        ]
        
        // create a custom random key for our message
        messageDB.childByAutoId().setValue(messageDictionary) {
            (error, reference) in
            if error != nil {
                print (error!)
            } else {
                print ("Message saved succesfully.")
                self.messageTextfield.isEnabled = true
                self.sendButton.isEnabled = true
                self.messageTextfield.text = ""
            }
        }
        
        
    }
    
    // Create the retrieveMessages method here:
    func retrieveMessages() {
        // we refer to the sub-database called "Messages"
        let messageDB = Database.database().reference().child("Messages")
        
        // whenever a new entry is added to the Message database...
        messageDB.observe(.childAdded) { (snapshot) in
            // return a snapshot of the database we can use
            
            // snapshot.value is the Message disctionary we inserted in the db in the first place of type Any
            // we'll convert its datatype using the "as" keyword in order to access it
            let snapshotValue = snapshot.value as! Dictionary<String, String>
            
            let text = snapshotValue["MessageBody"]!
            let sender = snapshotValue["Sender"]!
            
            let message = Message()
            message.messageBody = text
            message.sender = sender
            
            // append the message to the overall message array
            self.messageArray.append(message)
            
            // reformat the table view
            self.configureTableView()
            
            // reload the data in our Message table view
            self.messageTableView.reloadData()
        }
        
    }
    

    
    
    
    @IBAction func logOutPressed(_ sender: AnyObject) {
        
        // Log out the user and send them back to WelcomeViewController
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch {
            print("Error: there was a problem in signing out.")
        }
        
    }
    


}
