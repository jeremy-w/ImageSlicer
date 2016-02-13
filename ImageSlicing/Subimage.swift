import Quartz

struct Subimage {
    let rect: CGRect

    func contains(point: CGPoint) -> Bool {
        return CGRectContainsPoint(rect, point)
    }
}
