//
//  RentalTimePickerViewController.swift
//  XunPengMachine
//
//  租车日期与时间段选择器：日期单选、时间段多选
//

import UIKit

final class RentalTimePickerViewController: UIViewController {

    var onConfirm: ((String, String) -> Void)?

    private let maskView = UIView()
    private let panel = UIView()
    private let dateTitleLabel = UILabel.make("选择日期", font: AppFont.bodyM,
                                              color: AppColor.textMain, alignment: .center)
    private let timeTitleLabel = UILabel.make("选择时间", font: AppFont.bodyM,
                                              color: AppColor.textMain, alignment: .center)
    private let datePicker = UIPickerView()
    private let timeTable = UITableView(frame: .zero, style: .plain)
    private let verticalLine = Separator()
    private let horizontalLine = Separator()
    private let summaryLabel = UILabel.make("", font: AppFont.body,
                                            color: AppColor.primary, alignment: .center)
    private let confirmButton = AppButton(title: "确定", style: .danger, height: 52)

    private let calendar = Calendar(identifier: .gregorian)
    private let restrictToFuture: Bool
    private let maximumTimeSlotSelectionCount: Int
    private let years: [Int]
    private var selectedYear: Int
    private var selectedMonth: Int
    private var selectedDay: Int
    private var selectedSlotIndexes = Set<Int>()

    private let timeSlots: [(period: String, range: String)] = (0..<24).map { hour in
        let period: String
        switch hour {
        case 0..<6: period = "凌晨"
        case 6..<12: period = "上午"
        case 12..<18: period = "下午"
        default: period = "晚上"
        }
        return (period, String(format: "%02d:00-%02d:00", hour, hour + 1))
    }

    init(date: String = "", timeSlot: String = "", restrictToFuture: Bool = false,
         maximumTimeSlotSelectionCount: Int = 1) {
        self.restrictToFuture = restrictToFuture
        self.maximumTimeSlotSelectionCount = max(1, maximumTimeSlotSelectionCount)
        let current = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let currentYear = current.year ?? 2026
        let currentMonth = current.month ?? 1
        let currentDay = current.day ?? 1
        years = Array(currentYear...(currentYear + 5))

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        if let value = formatter.date(from: date) {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: value)
            selectedYear = components.year ?? currentYear
            selectedMonth = components.month ?? currentMonth
            selectedDay = components.day ?? currentDay
        } else {
            selectedYear = currentYear
            selectedMonth = currentMonth
            selectedDay = currentDay
        }

        super.init(nibName: nil, bundle: nil)

        let selectedValues = Set(timeSlot.split(separator: ",").map(String.init))
        for (index, slot) in timeSlots.enumerated() {
            if selectedValues.contains(slot.period + slot.range) || selectedValues.contains(slot.range) {
                selectedSlotIndexes.insert(index)
            }
        }
        selectedSlotIndexes = Set(selectedSlotIndexes.sorted()
            .prefix(self.maximumTimeSlotSelectionCount))
        normalizeSelectedDate()
        removeUnavailableSlots()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        restoreSelection()
        updateSummary()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let firstSlot = selectedSlotIndexes.min() {
            timeTable.scrollToRow(at: IndexPath(row: firstSlot, section: 0),
                                  at: .middle, animated: false)
        }
    }

    private func setupUI() {
        view.backgroundColor = .clear
        maskView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        maskView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                             action: #selector(cancelTapped)))
        view.addSubview(maskView)

        panel.backgroundColor = .white
        panel.layer.cornerRadius = 12.fit
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.layer.masksToBounds = true
        view.addSubview(panel)

        panel.addSubview(dateTitleLabel)
        panel.addSubview(timeTitleLabel)
        panel.addSubview(datePicker)
        panel.addSubview(timeTable)
        panel.addSubview(verticalLine)
        panel.addSubview(horizontalLine)
        panel.addSubview(summaryLabel)
        panel.addSubview(confirmButton)

        datePicker.dataSource = self
        datePicker.delegate = self

        timeTable.dataSource = self
        timeTable.delegate = self
        timeTable.rowHeight = 48.fit
        timeTable.separatorStyle = .none
        timeTable.showsVerticalScrollIndicator = false
        timeTable.register(RentalTimeSlotCell.self,
                           forCellReuseIdentifier: RentalTimeSlotCell.reuseId)

        summaryLabel.adjustsFontSizeToFitWidth = true
        summaryLabel.minimumScaleFactor = 0.75
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        maskView.frame = view.bounds

        let safeBottom = view.safeAreaInsets.bottom
        let panelHeight = min(570.fit + safeBottom, view.h - 40.fit)
        panel.frame = CGRect(x: 0, y: view.h - panelHeight,
                             width: view.w, height: panelHeight)

        let headerHeight: CGFloat = 48.fit
        let leftWidth = panel.w * 0.5
        dateTitleLabel.frame = CGRect(x: 0, y: 0, width: leftWidth, height: headerHeight)
        timeTitleLabel.frame = CGRect(x: leftWidth, y: 0,
                                      width: panel.w - leftWidth, height: headerHeight)

        let selectorHeight = panel.h - headerHeight - 126.fit - safeBottom
        datePicker.frame = CGRect(x: 0, y: headerHeight,
                                  width: leftWidth, height: selectorHeight)
        timeTable.frame = CGRect(x: leftWidth, y: headerHeight,
                                 width: panel.w - leftWidth, height: selectorHeight)
        verticalLine.frame = CGRect(x: leftWidth, y: headerHeight,
                                    width: 0.5, height: selectorHeight)
        horizontalLine.frame = CGRect(x: 0, y: datePicker.bottom,
                                      width: panel.w, height: 0.5)
        summaryLabel.frame = CGRect(x: 16.fit, y: horizontalLine.bottom + 8.fit,
                                    width: panel.w - 32.fit, height: 34.fit)
        confirmButton.frame = CGRect(x: 28.fit, y: summaryLabel.bottom + 8.fit,
                                     width: panel.w - 56.fit, height: 52.fit)
    }

    private func restoreSelection() {
        normalizeSelectedDate()
        let yearIndex = max(0, years.firstIndex(of: selectedYear) ?? 0)
        selectedYear = years[yearIndex]
        normalizeSelectedDate()
        datePicker.selectRow(yearIndex, inComponent: 0, animated: false)
        datePicker.selectRow(max(0, selectedMonth - 1), inComponent: 1, animated: false)
        selectedDay = min(selectedDay, daysInSelectedMonth())
        datePicker.selectRow(max(0, selectedDay - 1), inComponent: 2, animated: false)
    }

    private func normalizeSelectedDate() {
        guard restrictToFuture, !isSelectedDateAllowed else { return }
        let current = calendar.dateComponents([.year, .month, .day], from: Date())
        selectedYear = current.year ?? selectedYear
        selectedMonth = current.month ?? selectedMonth
        selectedDay = current.day ?? selectedDay
    }

    private var selectedDateValue: Date? {
        calendar.date(from: DateComponents(year: selectedYear,
                                           month: selectedMonth,
                                           day: selectedDay))
    }

    private var isSelectedDateAllowed: Bool {
        guard restrictToFuture, let date = selectedDateValue else { return true }
        return date >= calendar.startOfDay(for: Date())
    }

    private func isDatePickerRowAvailable(_ row: Int, component: Int) -> Bool {
        guard restrictToFuture else { return true }
        let current = calendar.dateComponents([.year, .month, .day], from: Date())
        let currentYear = current.year ?? selectedYear
        let currentMonth = current.month ?? selectedMonth
        let currentDay = current.day ?? selectedDay

        switch component {
        case 0:
            return years[row] >= currentYear
        case 1:
            return selectedYear > currentYear || row + 1 >= currentMonth
        default:
            if selectedYear > currentYear || selectedMonth > currentMonth { return true }
            return selectedYear == currentYear && selectedMonth == currentMonth && row + 1 >= currentDay
        }
    }

    private func isTimeSlotAvailable(at index: Int, now: Date = Date()) -> Bool {
        guard restrictToFuture else { return true }
        guard let startTime = calendar.date(from: DateComponents(year: selectedYear,
                                                                 month: selectedMonth,
                                                                 day: selectedDay,
                                                                 hour: index)) else {
            return false
        }
        return startTime > now
    }

    private func removeUnavailableSlots() {
        guard restrictToFuture else { return }
        selectedSlotIndexes = Set(selectedSlotIndexes.filter { isTimeSlotAvailable(at: $0) })
    }

    private func daysInSelectedMonth() -> Int {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }

    private var selectedDate: String {
        String(format: "%04d-%02d-%02d", selectedYear, selectedMonth, selectedDay)
    }

    private var selectedTimeSlot: String {
        selectedSlotIndexes.sorted().map {
            timeSlots[$0].period + timeSlots[$0].range
        }.joined(separator: ",")
    }

    private func updateSummary() {
        let dateText = "\(selectedYear)年\(selectedMonth)月\(selectedDay)日"
        let slots = selectedTimeSlot.replacingOccurrences(of: ",", with: "、")
        summaryLabel.text = slots.isEmpty ? "\(dateText)  请选择时间段" : "\(dateText)  \(slots)"
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func confirmTapped() {
        guard !selectedSlotIndexes.isEmpty else {
            Toast.shared.show("请至少选择一个时间段")
            return
        }

        guard isSelectedDateAllowed else {
            Toast.shared.show("只能选择未来的租车时间")
            return
        }

        let unavailableSlots = Set(selectedSlotIndexes.filter { !isTimeSlotAvailable(at: $0) })
        guard unavailableSlots.isEmpty else {
            selectedSlotIndexes.subtract(unavailableSlots)
            timeTable.reloadData()
            updateSummary()
            Toast.shared.show("只能选择未来的租车时间段")
            return
        }

        let date = selectedDate
        let slots = selectedTimeSlot
        let handler = onConfirm
        dismiss(animated: true) {
            handler?(date, slots)
        }
    }
}

extension RentalTimePickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return years.count
        case 1: return 12
        default: return daysInSelectedMonth()
        }
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        max(pickerView.w, Screen.width * 0.5) / 3
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        48.fit
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int,
                    forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.font = AppFont.body
        label.textAlignment = .center
        switch component {
        case 0: label.text = "\(years[row])年"
        case 1: label.text = "\(row + 1)月"
        default: label.text = "\(row + 1)日"
        }
        if !isDatePickerRowAvailable(row, component: component) {
            label.textColor = AppColor.textSub.withAlphaComponent(0.4)
        } else {
            label.textColor = pickerView.selectedRow(inComponent: component) == row
                ? AppColor.primary : AppColor.textMain
        }
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                    inComponent component: Int) {
        switch component {
        case 0: selectedYear = years[row]
        case 1: selectedMonth = row + 1
        default: selectedDay = row + 1
        }

        if component == 0 || component == 1 {
            selectedDay = min(selectedDay, daysInSelectedMonth())
        }

        if !isSelectedDateAllowed {
            normalizeSelectedDate()
            Toast.shared.show("不能选择过去的日期")
        }

        let yearIndex = years.firstIndex(of: selectedYear) ?? 0
        pickerView.selectRow(yearIndex, inComponent: 0, animated: true)
        pickerView.selectRow(selectedMonth - 1, inComponent: 1, animated: true)
        pickerView.reloadComponent(2)
        pickerView.selectRow(selectedDay - 1, inComponent: 2, animated: true)
        removeUnavailableSlots()
        timeTable.reloadData()
        pickerView.reloadAllComponents()
        updateSummary()
    }
}

extension RentalTimePickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        timeSlots.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RentalTimeSlotCell.reuseId,
                                                 for: indexPath) as! RentalTimeSlotCell
        let slot = timeSlots[indexPath.row]
        let available = isTimeSlotAvailable(at: indexPath.row)
        cell.configure(period: slot.period, range: slot.range,
                       selected: selectedSlotIndexes.contains(indexPath.row),
                       enabled: available)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard isTimeSlotAvailable(at: indexPath.row) else {
            Toast.shared.show("不能选择过去的时间段")
            return
        }
        if selectedSlotIndexes.contains(indexPath.row) {
            selectedSlotIndexes.remove(indexPath.row)
        } else {
            guard selectedSlotIndexes.count < maximumTimeSlotSelectionCount else {
                Toast.shared.show("最多可选择\(maximumTimeSlotSelectionCount)个时间段")
                return
            }
            selectedSlotIndexes.insert(indexPath.row)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        updateSummary()
    }
}

private final class RentalTimeSlotCell: UITableViewCell {
    static let reuseId = "RentalTimeSlotCell"

    private let periodLabel = UILabel.make("", font: AppFont.body,
                                           color: AppColor.textMain, alignment: .center)
    private let rangeLabel = UILabel.make("", font: AppFont.body,
                                          color: AppColor.textMain, alignment: .center)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(periodLabel)
        contentView.addSubview(rangeLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        periodLabel.frame = CGRect(x: 4.fit, y: 0, width: 52.fit, height: contentView.h)
        rangeLabel.frame = CGRect(x: periodLabel.right, y: 0,
                                  width: contentView.w - periodLabel.right - 4.fit,
                                  height: contentView.h)
    }

    func configure(period: String, range: String, selected: Bool, enabled: Bool) {
        periodLabel.text = period
        rangeLabel.text = range
        contentView.backgroundColor = selected ? UIColor(hex: 0xF0F1F3) : .white
        let color: UIColor
        if !enabled {
            color = AppColor.textSub.withAlphaComponent(0.35)
        } else {
            color = selected ? AppColor.primary : AppColor.textMain
        }
        periodLabel.textColor = color
        rangeLabel.textColor = color
        isUserInteractionEnabled = enabled
    }
}
