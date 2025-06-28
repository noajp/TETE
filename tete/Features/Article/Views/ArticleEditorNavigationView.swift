//
//  ArticleEditorNavigationView.swift
//  tete
//
//  Navigation wrapper for article editor
//

import SwiftUI

struct ArticleEditorNavigationView: View {
    var body: some View {
        ArticleEditorView()
    }
}

#if DEBUG
struct ArticleEditorNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleEditorNavigationView()
    }
}
#endif