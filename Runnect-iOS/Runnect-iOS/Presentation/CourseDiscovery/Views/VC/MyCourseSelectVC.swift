//
//  PlusDetailViewController.swift
//  Runnect-iOS
//
//  Created by YEONOO on 2023/01/05.
//

import UIKit

import Then
import Moya

class MyCourseSelectVC: UIViewController {
    
    // MARK: - Properties
    
    private let courseStorageProvider = MoyaProvider<CourseStorageRouter>(
        plugins: [NetworkLoggerPlugin(verbose: true)]
    )
    
    private var courseList = [Course]()
    
    private var selectedIndex: Int?
    
    // MARK: - UI Components
    
    private lazy var navibar = CustomNavigationBar(self, type: .titleWithLeftButton).setTitle("불러오기")
    private let selectButton = CustomButton(title: "선택하기").setEnabled(false)
    
    // MARK: - collectionview
    
    private lazy var mapCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    // MARK: - Constants
    
    final let collectionViewInset = UIEdgeInsets(top: 28, left: 16, bottom: 28, right: 16)
    final let itemSpacing: CGFloat = 10
    final let lineSpacing: CGFloat = 20
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.setNavigationBar()
        self.setLayout()
        self.setDelegate()
        self.register()
        self.setAddTarget()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.hideTabBar(wantsToHide: true)
        self.getPrivateCourseNotUploaded()
    }
}

// MARK: - Methods

extension MyCourseSelectVC {
    private func setData(courseList: [Course]) {
        self.courseList = courseList
        mapCollectionView.reloadData()
    }
    
    private func setDelegate() {
        mapCollectionView.delegate = self
        mapCollectionView.dataSource = self
    }
    
    private func register() {
        mapCollectionView.register(CourseListCVC.self,
                                   forCellWithReuseIdentifier: CourseListCVC.className)
    }
    
    private func setAddTarget() {
        self.selectButton.addTarget(self, action: #selector(pushToUploadVC), for: .touchUpInside)
    }
}

// MARK: - @objc Function

extension MyCourseSelectVC {
    @objc private func pushToUploadVC() {
        let nextVC = CourseUploadVC()
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}

// MARK: - UI & Layout

extension MyCourseSelectVC {
    private func setNavigationBar() {
        view.addSubview(navibar)
        navibar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(48)
        }
    }
    
    private func setUI() {
        view.backgroundColor = .w1
        self.tabBarController?.tabBar.isHidden = true
    }
        
    private func setLayout() {
        view.addSubviews(selectButton, mapCollectionView)
        self.view.bringSubviewToFront(selectButton)
        
        selectButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(34)
        }
        
        mapCollectionView.snp.makeConstraints { make in
            make.top.equalTo(navibar.snp.bottom)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(selectButton.snp.top).inset(-25)
        }
    }
}
// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension MyCourseSelectVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return courseList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? CourseListCVC else { return }
        self.selectedIndex = indexPath.item
        self.selectButton.setEnabled(true)
        cell.selectCell(didSelect: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? CourseListCVC else { return }
        self.selectedIndex = nil
        cell.selectCell(didSelect: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourseListCVC.className,
                                                            for: indexPath)
                as? CourseListCVC else { return UICollectionViewCell() }
        cell.setCellType(type: .titleWithLocation)
        
        if let selectedIndex = selectedIndex, selectedIndex == indexPath.item {
            cell.selectCell(didSelect: true)
        } else {
            cell.selectCell(didSelect: false)
        }
        
        let model = courseList[indexPath.item]
        
        var title = "\(model.departure.region) \(model.departure.city)"
        if let town = model.departure.town {
            title += " \(town)"
        }
        
        if let name = model.departure.name {
            title += " \(name)"
        }
        
        cell.setData(imageURL: model.image, title: title, location: nil, didLike: nil)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MyCourseSelectVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (UIScreen.main.bounds.width - (self.itemSpacing + 2*self.collectionViewInset.left)) / 2
        let cellHeight = CourseListCVCType.getCellHeight(type: .titleWithLocation, cellWidth: cellWidth)
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return self.collectionViewInset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.lineSpacing
    }
}

// MARK: - Network

extension MyCourseSelectVC {
    private func getPrivateCourseNotUploaded() {
        // self.selectedIndex = nil
        LoadingIndicator.showLoading()
        courseStorageProvider.request(.getPrivateCourseNotUploaded) { [weak self] response in
            LoadingIndicator.hideLoading()
            guard let self = self else { return }
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    do {
                        let responseDto = try result.map(BaseResponse<PrivateCourseNotUploadedResponseDto>.self)
                        guard let data = responseDto.data else { return }
                        self.setData(courseList: data.privateCourses)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                if status >= 400 {
                    print("400 error")
                    self.showNetworkFailureToast()
                }
            case .failure(let error):
                print(error.localizedDescription)
                self.showNetworkFailureToast()
            }
        }
    }
}
