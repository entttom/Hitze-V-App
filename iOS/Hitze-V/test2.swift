import MapKit

let req = MKLocalSearch.Request()
req.naturalLanguageQuery = "Wien"
let search = MKLocalSearch(request: req)
search.start { response, error in
    if let item = response?.mapItems.first {
        if #available(macOS 15.0, *) {
            print(type(of: item.address))
            // also try to print the address
            print(item.address)
        }
    }
}
RunLoop.main.run(until: Date(timeIntervalSinceNow: 2))
