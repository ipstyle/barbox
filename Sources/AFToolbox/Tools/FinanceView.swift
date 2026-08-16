import Foundation
import SwiftUI

struct FinanceView: View {
    @EnvironmentObject private var lang: LanguageStore
    @State private var amountText = "100"
    @State private var eurRate: Double?
    @State private var usdRate: Double?
    @State private var rateDate = ""
    @State private var saron: (date: String, value: Double)?
    @State private var saronPrevious: Double?
    @State private var policyRate: (date: String, value: Double)?
    @State private var loading = false
    @State private var errorText: String?

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionTitle(lang.t("Währungsrechner"))
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            TextField(lang.t("Betrag"), text: $amountText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 110)
                            Text("CHF").font(.system(size: 13, weight: .medium))
                            Spacer()
                        }
                        conversionRow(currency: "EUR", rate: eurRate)
                        conversionRow(currency: "USD", rate: usdRate)
                        if !rateDate.isEmpty {
                            Text(lang.t("EZB-Referenzkurse vom ") + rateDate)
                                .font(.system(size: 10)).foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(10)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 6) {
                    SectionTitle(lang.t("Zinsen (Hypotheken)"))
                    VStack(alignment: .leading, spacing: 8) {
                        if let saron {
                            HStack {
                                Text(lang.t("SARON (Monatsmittel)"))
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                                Spacer()
                                Text(percent(saron.value))
                                    .font(.system(size: 15, weight: .semibold).monospacedDigit())
                                    .foregroundStyle(saron.value >= 0 ? Theme.orange : Theme.green)
                            }
                            if let saronPrevious {
                                let delta = saron.value - saronPrevious
                                Text(lang.t("Vormonat: ") + "\(percent(saronPrevious)) (\(delta >= 0 ? "+" : "")\(String(format: "%.3f", delta)) Pp)")
                                    .font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                            Text(String(format: lang.t("Stand %@ · Quelle SNB"), saron.date))
                                .font(.system(size: 10)).foregroundStyle(.tertiary)
                        }
                        if let policyRate {
                            Divider()
                            HStack {
                                Text(lang.t("SNB-Leitzins"))
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                                Spacer()
                                Text(percent(policyRate.value))
                                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                            }
                            Text(lang.t("Stand ") + policyRate.date)
                                .font(.system(size: 10)).foregroundStyle(.tertiary)
                        }
                        if saron == nil && policyRate == nil && !loading {
                            Text(lang.t("Noch keine Daten — «Aktualisieren» drücken."))
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                }

                HStack(spacing: 8) {
                    Button(lang.t("Aktualisieren")) { fetchAll() }
                        .disabled(loading)
                    if loading { ProgressView().controlSize(.small) }
                    if let errorText {
                        Text(errorText).font(.system(size: 10)).foregroundStyle(Theme.red)
                    }
                }
            }
            .padding(12)
        }
        .navigationTitle(lang.t("Finanzen"))
        .onAppear {
            if eurRate == nil { fetchAll() }
        }
    }

    private func conversionRow(currency: String, rate: Double?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.right")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            if let rate {
                Text(String(format: "%.2f", amount * rate))
                    .font(.system(size: 15, weight: .semibold).monospacedDigit())
                Text(currency).font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
                Text(lang.t("Kurs ") + String(format: "%.4f", rate))
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            } else {
                Text("–").foregroundStyle(.secondary)
                Text(currency).font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private func percent(_ value: Double) -> String {
        String(format: "%.3f %%", value)
    }

    private func fetchAll() {
        loading = true
        errorText = nil
        Task {
            async let rates: Void = fetchRates()
            async let interest: Void = fetchInterest()
            _ = await (rates, interest)
            loading = false
        }
    }

    private func fetchRates() async {
        guard let url = URL(string: "https://api.frankfurter.dev/v1/latest?base=CHF&symbols=EUR,USD") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ratesDict = json["rates"] as? [String: Double] else { return }
            eurRate = ratesDict["EUR"]
            usdRate = ratesDict["USD"]
            rateDate = (json["date"] as? String) ?? ""
        } catch {
            errorText = lang.t("Kurse nicht abrufbar")
        }
    }

    private func fetchInterest() async {
        // SNB-Datenportal: SARON-Monatsmittel und Leitzins
        if let series = await fetchSNBSeries(cube: "zimoma", dimSel: "D0(SARON)") {
            if let last = series.last {
                saron = (Self.monthLabel(last.0, code: lang.code), last.1)
            }
            if series.count >= 2 {
                saronPrevious = series[series.count - 2].1
            }
        }
        if let series = await fetchSNBSeries(cube: "snboffzisa", dimSel: nil), let last = series.last {
            policyRate = (Self.monthLabel(last.0, code: lang.code), last.1)
        }
        if saron == nil && policyRate == nil {
            errorText = (errorText == nil) ? lang.t("SNB-Daten nicht abrufbar") : lang.t("Kurse und SNB-Daten nicht abrufbar")
        }
    }

    private func fetchSNBSeries(cube: String, dimSel: String?) async -> [(String, Double)]? {
        var urlString = "https://data.snb.ch/api/cube/\(cube)/data/json/en"
        if let dimSel {
            urlString += "?dimSel=\(dimSel)"
        }
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let timeseries = json["timeseries"] as? [[String: Any]],
                  let first = timeseries.first,
                  let values = first["values"] as? [[String: Any]] else { return nil }
            return values.compactMap { entry in
                guard let date = entry["date"] as? String,
                      let value = entry["value"] as? Double else { return nil }
                return (date, value)
            }
        } catch {
            return nil
        }
    }

    private static func monthLabel(_ isoMonth: String, code: String) -> String {
        let parts = isoMonth.split(separator: "-")
        guard parts.count == 2, let month = Int(parts[1]) else { return isoMonth }
        let names = code == "en"
            ? ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            : ["Jan", "Feb", "März", "April", "Mai", "Juni", "Juli", "Aug", "Sept", "Okt", "Nov", "Dez"]
        let name = (1...12).contains(month) ? names[month - 1] : String(parts[1])
        return "\(name) \(parts[0])"
    }
}
