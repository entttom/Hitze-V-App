import SwiftUI
import MapKit

struct TestView: View {
    @State private var offset: CGFloat = 0
    var body: some View {
        ZStack(alignment: .trailing) {
            Color.red
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(alignment: .trailing) {
                    Button {
                        withAnimation { offset = 0 }
                    } label: {
                        Image(systemName: "trash")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 80)
                            .frame(maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                }

            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Pill")
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        } else {
                            offset = value.translation.width * 0.2
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width < -40 {
                                offset = -80
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
    }
}
