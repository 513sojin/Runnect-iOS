//
//  UserProfileVC.swift
//  Runnect-iOS
//
//  Created by 이명진 on 12/10/23.
//

import UIKit

import SnapKit
import Then
import Moya

final class UserProfileVC: UIViewController {

    // MARK: - Properties
    
    private let userProvider = Providers.userProvider
    private let scrapProvider = Providers.scrapProvider
    private var userProfileModel: UserProfileDto?

    private var uploadedCourseList = [UserCourseInfo]()
    private var userId: Int?

    // MARK: - UI Components
    
    private lazy var navibar = CustomNavigationBar(self, type: .titleWithLeftButton).setTitle("프로필")

    private lazy var mapCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    private lazy var UploadedCourseInfoCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        register()
        setNavigationBar()
        setDelegate()
        setLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard UserManager.shared.userType != .visitor else { return }
        getMyPageInfo()
    }
}

// MARK: - Methods
extension UserProfileVC {
    func setUserId(userId: Int) {
        self.userId = userId
    }

    private func setData(model: UserProfileDto) {
        self.userProfileModel = model
        self.uploadedCourseList = model.courses
        UploadedCourseInfoCollectionView.reloadData()
    }

    private func setDelegate() {
        mapCollectionView.delegate = self
        mapCollectionView.dataSource = self
    }
    
    private func register() {
        let cellTypes: [UICollectionViewCell.Type] = [UserInfoCell.self,
                                                      UserProgressCell.self,
                                                      UserUploadedLabelCell.self,
                                                      CourseListCVC.self]
        cellTypes.forEach { cellType in
            mapCollectionView.register(cellType, forCellWithReuseIdentifier: cellType.className)
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension UserProfileVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0, 1, 2:
            return 1
        case 3:
            return uploadedCourseList.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserInfoCell.className, for: indexPath) as? UserInfoCell else { return UICollectionViewCell() }
            // userProfileModel이 nil이 아닌 경우에만 setInfoData 메서드 호출
            if let userProfileModel = userProfileModel {
                cell.setInfoData(model: userProfileModel)
            }
            return cell
        case 1:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserProgressCell.className, for: indexPath) as? UserProgressCell else { return UICollectionViewCell() }
            // userProfileModel이 nil이 아닌 경우에만 bind 메서드 호출
            if let userProfileModel = userProfileModel {
                cell.bind(model: userProfileModel)
            }
            return cell
        case 2:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserUploadedLabelCell.className, for: indexPath) as? UserUploadedLabelCell else { return UICollectionViewCell() }
            return cell
        case 3:
            return courseListCell(collectionView: collectionView, indexPath: indexPath)
        default:
            return UICollectionViewCell()
        }
    }
    
    private func courseListCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourseListCVC.className, for: indexPath) as? CourseListCVC else { return UICollectionViewCell() }
        cell.setCellType(type: .all)
        cell.delegate = self
        let model = self.uploadedCourseList[indexPath.item]
        let location = "\(model.departure.region) \(model.departure.city)"
        cell.setData(imageURL: model.image, title: model.title, location: location, didLike: model.scrapTF, indexPath: indexPath.item)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension UserProfileVC: UICollectionViewDelegateFlowLayout {

    private struct Constants {
        static let cellSpacing: CGFloat = 20
        static let cellPadding: CGFloat = 10
        static let sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        switch indexPath.section {
        case 0:
            return CGSize(width: screenWidth, height: 93)
        case 1:
            return CGSize(width: screenWidth, height: 101)
        case 2:
            return CGSize(width: screenWidth, height: 62)
        case 3:
            let cellWidth = (screenWidth - 2 * Constants.sectionInsets.left - Constants.cellSpacing) / 2
            let cellHeight = CourseListCVCType.getCellHeight(type: .all, cellWidth: cellWidth)
            return CGSize(width: cellWidth, height: cellHeight)
        default:
            return CGSize(width: 0, height: 0)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return section == 3 ? Constants.cellSpacing : 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return section == 3 ? Constants.cellPadding : 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return section == 3 ? Constants.sectionInsets : .zero
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 3 {
            pushToCourseDetail(at: indexPath)
        }
    }

    private func pushToCourseDetail(at indexPath: IndexPath) {
        let courseDetailVC = CourseDetailVC()
        let courseModel = uploadedCourseList[indexPath.item]
        courseDetailVC.setCourseId(courseId: courseModel.courseId, publicCourseId: courseModel.publicCourseId)
        courseDetailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(courseDetailVC, animated: true)
    }
}

// MARK: - CourseListCVCDeleagte
extension UserProfileVC: CourseListCVCDeleagte {
    func likeButtonTapped(wantsTolike: Bool, index: Int) {
        guard UserManager.shared.userType != .visitor else {
            showToastOnWindow(text: "러넥트에 가입하면 코스를 스크랩할 수 있어요")
            return
        }

        let publicCourseId = uploadedCourseList[index].publicCourseId
        scrapCourse(publicCourseId: publicCourseId, scrapTF: wantsTolike)
    }
}

// MARK: - UI & Layout
extension UserProfileVC {
    
    private func setUI() {
        view.backgroundColor = .w1
    }
    
    private func setNavigationBar() {
        view.addSubview(navibar)

        navibar.snp.makeConstraints {
            $0.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
        }
    }

    private func setLayout() {
        view.addSubview(mapCollectionView)
        
        mapCollectionView.snp.makeConstraints {
            $0.top.equalTo(navibar.snp.bottom)
            $0.leading.bottom.trailing.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

// MARK: - Network
extension UserProfileVC {
    private func getMyPageInfo() {
        guard let userId = self.userId else { return }
        LoadingIndicator.showLoading()
        userProvider.request(.getUserProfileInfo(userId: userId)) { [weak self] response in
            LoadingIndicator.hideLoading()
            guard let self = self else { return }

            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    do {
                        let responseDto = try result.map(BaseResponse<UserProfileDto>.self)
                        guard let data = responseDto.data else { return }
                        self.setData(model: data)
                        self.mapCollectionView.reloadData()
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
                self.showToast(message: "탈퇴한 유저 입니다.", duration: 1.2)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func scrapCourse(publicCourseId: Int, scrapTF: Bool) {
        LoadingIndicator.showLoading()
        scrapProvider.request(.createAndDeleteScrap(publicCourseId: publicCourseId, scrapTF: scrapTF)) { [weak self] response in
            LoadingIndicator.hideLoading()
            guard let self = self else { return }
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    print("스크랩 성공")
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

extension UserProfileVC {
    private func showToast(message: String, duration: TimeInterval = 1.0) {
        let toastLabel = UILabel().then {
            $0.backgroundColor = .g1.withAlphaComponent(0.6)
            $0.textColor = UIColor.white
            $0.textAlignment = .center
            $0.font = UIFont.systemFont(ofSize: 12)
            $0.text = message
            $0.alpha = 0.0
            $0.layer.cornerRadius = 10
            $0.clipsToBounds = true
        }

        view.addSubview(toastLabel)

        toastLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-100)
            make.width.equalTo(300)
            make.height.equalTo(35)
        }

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: duration, options: .curveEaseIn, animations: {
                toastLabel.alpha = 0.0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        })
    }
}
