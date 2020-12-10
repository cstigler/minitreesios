//
//  StartViewController.swift
//  Entwined-iOS
//
//  Created by Charlie Stigler on 12/9/20.
//  Copyright © 2020 Charlie Stigler. All rights reserved.
//

import Foundation

import UIKit

class StartViewController: UIViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var autoPilotInterActBt: UIButton!
    @IBOutlet weak var connectingLabel: UIView!
    @IBOutlet weak var startBreakButton: UIButton!

    var imagesArr = [UIImage(named: "entwined1"),
                     UIImage(named: "entwined2"),
                     UIImage(named: "entwined3")]
    
    var timer:Timer? = nil
    
    //var secondsCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        reloadCollectionView()
        ServerController.sharedInstance.connect()
        
        // make connecting label tappable so users can change hostname
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(connectingLabelTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        connectingLabel.addGestureRecognizer(tapGestureRecognizer)
        connectingLabel.isUserInteractionEnabled = true
        
        Model.sharedInstance.reactive.producer(forKeyPath: #keyPath(Model.loaded)).startWithValues { [unowned self] (_) in
            self.connectingLabel.isHidden = Model.sharedInstance.loaded
            self.startBreakButton.isHidden = !Model.sharedInstance.loaded
            self.autoPilotInterActBt.isHidden = !Model.sharedInstance.loaded
        }

        //Set autoplay mode enable by default
        Model.sharedInstance.autoplay = true;
    }
    
    @objc func connectingLabelTapped(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Change Hostname", message: "What hostname is the Entwined server at?", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { (textField : UITextField!) in
            textField.placeholder = "\(ServerController.sharedInstance.serverHostname)"
            textField.delegate = self
        }
        
        let save = UIAlertAction(title: "Connect", style: UIAlertAction.Style.default, handler: { saveAction -> Void in
            var newHostname = (alert.textFields![0] as UITextField).text
            newHostname = newHostname?.trimmingCharacters(in: .whitespacesAndNewlines)
            if (newHostname != nil && newHostname!.isEmpty) {
                return;
            }
            
            if let unwrappedHostname = newHostname {
                ServerController.sharedInstance.serverHostname = unwrappedHostname
                print("Connecting to new hostname \(unwrappedHostname)")
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })

        alert.addAction(save)
        alert.addAction(cancel)

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func startFiveMinuteBreak(_ sender: AnyObject) {
        let confirmationAlert = UIAlertController(title: "Confirm Break", message: "Are you sure you want to start a 5-minute lighting break? All LED patterns will stop and the sculpture will go dark.", preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Start Break", style: .default, handler: { (action) -> Void in
            ServerController.sharedInstance.startBreak(300.0)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })

        confirmationAlert.addAction(ok)
        confirmationAlert.addAction(cancel)
        
        // Present dialog message to user
        self.present(confirmationAlert, animated: true, completion: nil)
    }
    @IBAction func stopBreak(_ sender: AnyObject) {
        
    }
    
    @IBAction func autoPilotInterActBt(_ sender: Any) {
        print("autopilot interact bt, loaded = \(Model.sharedInstance.loaded)")
        if Model.sharedInstance.loaded {
            startControlPanel()
        }
    }
    
    func startControlPanel() {
        print("performing segue")
        performSegue(withIdentifier: "show-controls-segue", sender: self)
        print("performed segue")

        Model.sharedInstance.autoplay = false;
    }
    
    func reloadCollectionView() {
        self.collectionView.reloadData()
        
        // Invalidating timer for safety reasons
        self.timer?.invalidate()
        
        // Below, for each 3.5 seconds MyViewController's 'autoScrollImageSlider' would be fired
        self.timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(StartViewController.autoScrollImageSlider), userInfo: nil, repeats: true)
        
        //This will register the timer to the main run loop
        RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width:collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension StartViewController : UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesArr.count
    }
    
    @objc func autoScrollImageSlider() {
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                let firstIndex = 0
                let lastIndex = (self.imagesArr.count) - 1
                
                let visibleIndices = self.collectionView.indexPathsForVisibleItems
                let nextIndex = visibleIndices[0].row + 1
                
                let nextIndexPath: IndexPath = IndexPath.init(item: nextIndex, section: 0)
                let firstIndexPath: IndexPath = IndexPath.init(item: firstIndex, section: 0)
                
                if nextIndex > lastIndex {
                    self.collectionView.scrollToItem(at: firstIndexPath, at: .centeredHorizontally, animated: true)
                } else {
                    self.collectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        cell.autoPilotImageView.image = imagesArr[indexPath.row]
        return cell
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        self.timer?.invalidate()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if Model.sharedInstance.loaded {
            startControlPanel()
        }
    }
}
