//
//  FeedViewController.swift
//  InstaClone
//
//  Created by Salvador Rodriguez on 3/4/19.
//  Copyright © 2019 009252542SalvadorRodriguez. All rights reserved.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    
    var posts = [PFObject]()
    let commentBar = MessageInputBar()
    var showsCommentBar = false
    var selectedPost: PFObject!
    
    override var inputAccessoryView: UIView?{
        return commentBar
    }
    override var canBecomeFirstResponder: Bool{
        return showsCommentBar
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let commnets = (post["comments"] as? [PFObject]) ?? []
        
        return (commnets.count + 2)
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }

    @IBAction func onLogoutButton(_ sender: Any) {
        PFUser.logOut()
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        let delagate = UIApplication.shared.delegate as! AppDelegate
        delagate.window?.rootViewController = loginViewController
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            cell.captionLabel.text = (post["caption"] as! String)
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)
            cell.photoView.af_setImage(withURL: url!)
            
            return cell
        }
        else if indexPath.row <= comments.count
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            let comment = comments[indexPath.row - 1]
            cell.commentLabel.text = comment["text"] as? String
            let user  = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
        return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            return cell
        }
    }
    @objc func loadFeed()
    {
        let query = PFQuery(className:"Posts")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 20
        query.order(byDescending: "createdAt")
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadFeed()

    }
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        commentBar.sendButton.title = "Post"
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        // Do any additional setup after loading the view.
        let center = NotificationCenter.default
//        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)

    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // create the comment
        let comment = PFObject(className: "Comments")
//        let comments = (post["comments"] as? [PFObject]) ?? []

    comment["text"] = text
    comment["post"] = selectedPost
    comment["author"] = PFUser.current()!
    selectedPost.add(comment, forKey: "comments")
    selectedPost.saveInBackground { (success, error) in
        if success{
            print("comment saved")
        }
        else{
            print("Error save comment")
        }
    }
        tableView.reloadData()
        
        //Clear/dismiss
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    @objc func keyboardWillBeHidden(note:Notification)
    {
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 { 
            showsCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            selectedPost = post
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
