import UIKit

class ViewController: UIViewController, UISearchBarDelegate,
    UITableViewDataSource
{

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var loadingBar: UIActivityIndicatorView!

    var allCountries: [CountryData] = []
    var searchedCountries: [CountryData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.dataSource = self
        hideLoadingIndicator()
    }

    @IBAction func onFetchCountriesButtonClicked(_ sender: Any) {
        self.hideLoadingIndicator()
        Task {
            do {
                allCountries = try await fetchCountries()
                searchedCountries.removeAll()
                searchedCountries.append(contentsOf: allCountries)
                DispatchQueue.main.async {
                    self.hideLoadingIndicator()
                    self.tableView.reloadData()
                }

            } catch {
                DispatchQueue.main.async {
                    self.hideLoadingIndicator()
                }
            }
        }
    }

    func hideLoadingIndicator() {
        self.loadingBar.stopAnimating()
        self.loadingBar.isHidden = true
    }

    func showLoadingIndicator() {
        self.loadingBar.startAnimating()
        self.loadingBar.isHidden = false
    }

    func fetchCountries() async throws -> [CountryData] {
        let urlString =
            "https://gist.githubusercontent.com/peymano-wmt/32dcb892b06648910ddd40406e37fdab/raw/db25946fd77c5873b0303b858e861ce724e0dcd0/countries.json"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([CountryData].self, from: data)
    }

    func filterCountries(searchText: String) {
        let searchedString = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()
        if searchedString.isEmpty {
            resetSeachedCountriesList()
            return
        }
        let newCountriesList = allCountries.filter {
            return
                ($0.name.lowercased().contains(searchedString)
                || $0.capital.lowercased().contains(searchedString))
        }
        searchedCountries.removeAll()
        searchedCountries.append(contentsOf: newCountriesList)
    }

    func resetSeachedCountriesList() {
        searchedCountries.removeAll()
        searchedCountries.append(contentsOf: allCountries)
    }

    // MARK: - UISearchBarDelegate methods

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search button clicked: \(searchBar.text ?? "")")
        searchBar.resignFirstResponder()  // dismiss keyboard
        filterCountries(searchText: searchBar.text ?? "")
        self.tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("User typed: \(searchText)")
        filterCountries(searchText: searchText)
        self.tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("Cancel clicked")
        searchBar.text = ""
        searchBar.resignFirstResponder()
        resetSeachedCountriesList()
        self.tableView.reloadData()
    }

    // MARK: - UITableView dataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return searchedCountries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let countryData = searchedCountries[indexPath.item]
        let cell =
            tableView.dequeueReusableCell(withIdentifier: "countryCellID")
            as! CountryCell
        cell.nameRegion.text = countryData.name + ", " + countryData.region
        cell.code.text = countryData.code
        cell.capital.text = countryData.capital
        return cell
    }
}
