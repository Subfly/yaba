package navigation

enum class YabaScreens(val route: String) {
    HOME(route = "home"),
    SYNC(route = "sync"),
    SEARCH(route = "seach"),
    SETTINGS(route = "settings"),
    FOLDER_DETAIL(route = "folder_detail"),
    TAG_DETAIL(route = "tag_detail"),
    BOOKMARK_DETAIL(route = "bookmark_detail"),
}
