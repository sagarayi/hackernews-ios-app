//
//  StoryListViewController.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/17/25.
//

import UIKit

class StoryListViewController: UIViewController {
    @IBOutlet weak var storyListTableView: UITableView!
    
    private let vm = StoryListViewModel(repo: DefaultHNRepository(), feed: .top)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Top Stories"
        storyListTableView.dataSource = self
        storyListTableView.delegate = self
        
        vm.onChange = { [weak self] _ in
            Task {
                await MainActor.run {
                    self?.storyListTableView.reloadData()
                }
            }
            
        }
        vm.load()
    }
}

extension StoryListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        vm.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StoryViewCell") as? StoryViewCell else {
            return UITableViewCell()
        }
        
        let item = vm.item(at: indexPath.row)
        cell.configure(item)
        vm.loadMoreIfNeeded(currentIndex: indexPath.row)
        return cell
    }
}

class StoryViewCell: UITableViewCell {
    
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    func configure(_ item: HNItem?) {
        guard let item = item else { return }
        titleLabel.text = item.title ?? "No title available"
        pointsLabel.text = "\(item.score ?? 0) points"
        authorLabel.text = "By \(item.by ?? "Unknown") "
        
        pointsLabel.textColor = .secondaryLabel
        authorLabel.textColor = .secondaryLabel
    }
    
}
