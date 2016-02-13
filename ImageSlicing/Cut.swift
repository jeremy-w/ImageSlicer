import Quartz

struct Cut {
    let at: CGPoint
    let oriented: Orientation

    func slice(subimage: Subimage) -> [Subimage] {
        let edge: CGRectEdge
        let amount: CGFloat

        switch oriented {
        case .Horizontally:
            edge = .MinYEdge
            amount = at.y - CGRectGetMinY(subimage.rect)
        case .Vertically:
            edge = .MinXEdge
            amount = at.x - CGRectGetMinX(subimage.rect)
        }

        var subrect = CGRectZero
        var otherSubrect = CGRectZero
        CGRectDivide(subimage.rect, &subrect, &otherSubrect, amount, edge)
        return [subrect, otherSubrect].map(Subimage.init)
    }
}
