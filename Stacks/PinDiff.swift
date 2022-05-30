struct PinDiff {

  let before: [Pin]
  let after: Pin

  static func fromCore(_ x: CorePinDiff) throws -> PinDiff {
    guard let before = x.before else { throw SimpleError("Field .before must be non-null: \(x)") }
    guard let after  = x.after  else { throw SimpleError("Field .after must be non-null: \(x)") }
    return PinDiff(
      before: try fromJson(before),
      after:  try fromJson(after)
    )
  }

}
