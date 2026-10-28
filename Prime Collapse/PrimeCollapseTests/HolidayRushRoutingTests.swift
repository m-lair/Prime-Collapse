import XCTest
@testable import Prime_Collapse

final class HolidayRushRoutingTests: XCTestCase {
    func testAcceptsOnlyTheHolidayRushEvent() throws {
        XCTAssertTrue(HolidayRushRoute.matches(try XCTUnwrap(URL(string: "primecollapse://events/holiday-rush"))))
        for raw in ["https://events/holiday-rush", "primecollapse://other/holiday-rush",
                    "primecollapse://events/holiday-rush/extra", "primecollapse://events/holiday-rush?reset=1",
                    "primecollapse://user@events/holiday-rush", "primecollapse://events:80/holiday-rush",
                    "primecollapse://events/holiday-rush#reset"] {
            XCTAssertFalse(HolidayRushRoute.matches(try XCTUnwrap(URL(string: raw))), raw)
        }
    }
}
