import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 7,
      let width = Int(args[3]), let height = Int(args[4]),
      let x = Int(args[5]), let y = Int(args[6]),
      let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
      width > 0, height > 0, x >= 0, y >= 0,
      x + width <= image.width, y + height <= image.height,
      let cropped = image.cropping(to: CGRect(x: x, y: y, width: width, height: height)),
      let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL,
                                                        UTType.png.identifier as CFString, 1, nil) else {
    fputs("Usage: swift crop-capture.swift source output width height x y\n", stderr)
    exit(1)
}
CGImageDestinationAddImage(destination, cropped, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }
