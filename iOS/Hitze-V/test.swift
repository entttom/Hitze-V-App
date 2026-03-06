import MapKit

func test(item: MKMapItem) {
    if #available(macOS 15.0, *) {
        print(type(of: item.address))
    }
}
