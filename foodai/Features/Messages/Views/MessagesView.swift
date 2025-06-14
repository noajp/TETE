import SwiftUI

struct MessagesView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<10) { index in
                        MessageRow(
                            username: "user\(index + 1)",
                            lastMessage: "最新のメッセージ...",
                            timestamp: "5分前",
                            hasUnread: index < 2
                        )
                        
                        if index < 9 {
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
            }
            .navigationTitle("メッセージ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }
}

struct MessageRow: View {
    let username: String
    let lastMessage: String
    let timestamp: String
    let hasUnread: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // プロフィール画像
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(username)
                        .font(.system(size: 16, weight: hasUnread ? .semibold : .regular))
                    
                    Spacer()
                    
                    Text(timestamp)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Text(lastMessage)
                    .font(.system(size: 14))
                    .foregroundColor(hasUnread ? .black : .gray)
                    .lineLimit(1)
            }
            
            if hasUnread {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}