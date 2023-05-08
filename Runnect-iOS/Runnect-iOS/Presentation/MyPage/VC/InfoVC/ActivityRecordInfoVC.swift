//
//  ActivityRecordInfoVC.swift
//  Runnect-iOS
//
//  Created by 몽이 누나 on 2023/01/02.
//

import UIKit

import SnapKit
import Then
import Moya

final class ActivityRecordInfoVC: UIViewController {
    
    // MARK: - Properties
    
    private var recordProvider = Providers.recordProvider
    
    private var activityRecordList = [ActivityRecord]()
    
    private var isEditMode: Bool = false
        
    private var selectedRecords: [IndexPath] = []
    
    // MARK: - UI Components
    
    private lazy var navibar = CustomNavigationBar(self, type: .titleWithLeftButton).setTitle("러닝 기록")
    
    private lazy var activityRecordTableView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.separatorStyle = .none
        $0.contentInset = UIEdgeInsets(top: 19, left: 0, bottom: 0, right: 0)
        $0.allowsMultipleSelection = true
    }
    
    private let emptyView = ListEmptyView(description: "아직 러닝 기록이 없어요!\n코스를 그리고 달려보세요", buttonTitle: "코스 그리기")
    
    private let editRecordContainerView = UIView()
    
    private lazy var totalNumOfRecordlabel = UILabel().then {
        $0.font = .b6
        $0.textColor = .g2
        $0.text = "총 기록 0개"
    }
    
    private let editButton = UIButton(type: .custom).then {
        $0.setTitle("편집", for: .normal)
        $0.setTitleColor(.m1, for: .normal)
        $0.titleLabel?.font = .b7
        $0.layer.borderColor = UIColor.m1.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 11
    }
    
    private lazy var deleteRecordButton = CustomButton(title: "삭제하기").then {
        $0.isHidden = true
        var selectedRecords = self.selectedRecords
        $0.isEnabled = false
        
    }
    
    // MARK: - View Life Cycle
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        setUI()
        setLayout()
        setAddTarget()
        setDelegate()
        register()
        getActivityRecordInfo()
        self.hideTabBar(wantsToHide: true)
    }
}

// MARK: - Methods

extension ActivityRecordInfoVC {
    private func setData(activityRecordList: [ActivityRecord]) {
        self.activityRecordList = activityRecordList
        activityRecordTableView.reloadData()
        self.emptyView.isHidden = !activityRecordList.isEmpty
        totalNumOfRecordlabel.text = "총 기록 \(activityRecordList.count)개"
    }
    
    private func setDelegate() {
        self.activityRecordTableView.delegate = self
        self.activityRecordTableView.dataSource = self
        self.emptyView.delegate = self
    }
    
    private func register() {
        self.activityRecordTableView.register(ActivityRecordInfoTVC.self, forCellReuseIdentifier: ActivityRecordInfoTVC.className)
    }
    
    private func setAddTarget() {
        self.editButton.addTarget(self, action: #selector(editButtonDidTap), for: .touchUpInside)
    }
}

// MARK: - @objc Function

extension ActivityRecordInfoVC {
    @objc func editButtonDidTap() {
        selectedRecords = []
        if isEditMode {
            isEditMode = false
            self.totalNumOfRecordlabel.text = "총 기록 \(self.activityRecordList.count)개"
            self.editButton.setTitle("편집", for: .normal)
            self.deleteRecordButton.isHidden = true
        } else {
            isEditMode = true
            self.totalNumOfRecordlabel.text = "기록 선택"
            self.editButton.setTitle("취소", for: .normal)
            self.deleteRecordButton.isHidden = false
        }
    }
}

// MARK: - Layout Helpers

extension ActivityRecordInfoVC {
    private func setNavigationBar() {
        view.addSubview(navibar)
        
        navibar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(48)
        }
    }
    
    private func setUI() {
        view.backgroundColor = .w1
        activityRecordTableView.backgroundColor = .m3
        editRecordContainerView.backgroundColor = .w1
    }
    
    private func setLayout() {
        view.addSubviews(editRecordContainerView, activityRecordTableView, deleteRecordButton)
        activityRecordTableView.addSubviews(emptyView)
        
        editRecordContainerView.snp.makeConstraints { make in
            make.top.equalTo(navibar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(38)
        }
        
        editRecordContainerView.addSubviews(totalNumOfRecordlabel, editButton)
        
        totalNumOfRecordlabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(10)
        }
        
        editButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.width.equalTo(47)
            make.height.equalTo(22)
            make.top.equalToSuperview().offset(5)
        }
        
        activityRecordTableView.snp.makeConstraints { make in
            make.top.equalTo(editRecordContainerView.snp.bottom)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        
        deleteRecordButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(32)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(80)
        }
    }
}

// MARK: - UITableViewDelegate

extension ActivityRecordInfoVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 193
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) is ActivityRecordInfoTVC else { return }
        if isEditMode {
                // 선택된 셀의 정보를 저장
                if !selectedRecords.contains(indexPath) {
                    selectedRecords.append(indexPath)
                }
            
                if selectedRecords.count == 0 {
                    self.deleteRecordButton.isEnabled = false
                } else {
                    self.deleteRecordButton.setTitle("삭제하기(\(selectedRecords.count))", for: .normal)
                    self.deleteRecordButton.isEnabled = true
                }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) is ActivityRecordInfoTVC else { return }
        if isEditMode {
            // 선택 취소된 셀의 정보를 삭제
            if let index = selectedRecords.firstIndex(of: indexPath) {
                selectedRecords.remove(at: index)
            }
            
            if selectedRecords.count == 0 {
                self.deleteRecordButton.isEnabled = false
            } else {
                self.deleteRecordButton.setTitle("삭제하기(\(selectedRecords.count))", for: .normal)
                self.deleteRecordButton.isEnabled = true
                
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource

extension ActivityRecordInfoVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityRecordList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let activityRecordCell = tableView.dequeueReusableCell(withIdentifier: ActivityRecordInfoTVC.className, for: indexPath) as? ActivityRecordInfoTVC else { return UITableViewCell()}
        activityRecordCell.selectionStyle = .none
        activityRecordCell.setData(model: activityRecordList[indexPath.item])
        if isEditMode {
            // 선택된 셀에 대한 표시 업데이트
            if selectedRecords.contains(indexPath) {
                activityRecordCell.activityRecordContainerView.image = ImageLiterals.imgRecordContainerSelected
            } else {
                activityRecordCell.activityRecordContainerView.image = ImageLiterals.imgRecordContainer
            }
        } else {
            activityRecordCell.selectionStyle = .none
            // 선택된 셀들을 순회하면서 미선택 이미지로 변경
            for i in 0..<selectedRecords.count {
                let indexPath = IndexPath(row: i, section: 0)
                guard let cell = tableView.cellForRow(at: indexPath) as? ActivityRecordInfoTVC else { continue }
                activityRecordCell.activityRecordContainerView.image = ImageLiterals.imgRecordContainer
            }
        }
        return activityRecordCell
    }
}

// MARK: - ListEmptyViewDelegate

extension ActivityRecordInfoVC: ListEmptyViewDelegate {
    func emptyViewButtonTapped() {
        self.tabBarController?.selectedIndex = 0
    }
}

// MARK: - Network

extension ActivityRecordInfoVC {
    func getActivityRecordInfo() {
        LoadingIndicator.showLoading()
        recordProvider.request(.getActivityRecordInfo) { [weak self] response in
            LoadingIndicator.hideLoading()
            guard let self = self else { return }
            switch response {
            case .success(let result):
                let status = result.statusCode
                if 200..<300 ~= status {
                    do {
                        let responseDto = try result.map(BaseResponse<ActivityRecordInfoDto>.self)
                        guard let data = responseDto.data else { return }
                        self.setData(activityRecordList: data.records)
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
