package core.settings.localization.assets.localization

class EnglishLocalization : YabaLocalization() {
    override val APP_NAME: String
        get() = "Yaba"
    override val OTHERS_FOLDER_NAME: String
        get() = "Others"
    override val FOLDERS_TITLE: String
        get() = "Folders"
    override val TAGS_TITLE: String
        get() = "Tags"
    override val SYNC: String
        get() = "Sync"
    override val SETTINGS: String
        get() = "Settings"
    override val CREATE_BOOKMARK: String
        get() = "Create Bookmark"
    override val CREATE_FOLDER: String
        get() = "Create Folder"
    override val CREATE_TAG: String
        get() = "Create Tag"
    override val ADD_TAG: String
        get() = "Add Tag"
    override val EDIT_BOOKMARK: String
        get() = "Edit Bookmark"
    override val EDIT_FOLDER: String
        get() = "Edit Folder"
    override val EDIT_TAG: String
        get() = "Edit Tag"
    override val PREVIEW: String
        get() = "Preview"
    override val WRITE_HERE: String
        get() = "Write here..."
    override val TAG_NAME: String
        get() = "Tag Name"
    override val FOLDER_NAME: String
        get() = "Folder Name"
    override val COLOR_SELECTION: String
        get() = "Color Selection"
    override val COLOR_SELECTION_FIRST: String
        get() = "First Color"
    override val COLOR_SELECTION_SECOND: String
        get() = "Second Color"
    override val ICON_SELECTION: String
        get() = "Icon Selection"
    override val SEARCH_FIELD_PLACEHOLDER: String
        get() = "Start typing to search..."
    override val BOOKMARK_COUNT_PREFIX_TEXT: String
        get() = "Bookmark Count: "
    override val SEARCH_FOR_ICON_TEXT: String
        get() = "Search for Icon"
    override val THEME_AND_LANGUAGE_OPTIONS: String
        get() = "Theme and Language Options"
    override val CONTENT_OPTIONS: String
        get() = "Content Options"
    override val THEME_SELECTION_OPTION: String
        get() = "Theme Selection"
    override val THEME_SELECTION_OPTION_SYSTEM: String
        get() = "Follow System"
    override val THEME_SELECTION_OPTION_DARK: String
        get() = "Dark Theme"
    override val THEME_SELECTION_OPTION_LIGHT: String
        get() = "Light Theme"
    override val LANGUAGE_SELECTION_OPTION: String
        get() = "Language Selection"
    override val LANGUAGE_SELECTION_EN: String
        get() = "English"
    override val LANGUAGE_SELECTION_TR: String
        get() = "Turkish"
    override val CONTENT_VIEW_SELECTION_OPTION: String
        get() = "Content View Style"
    override val CONTENT_VIEW_SELECTION_GRID: String
        get() = "Grid"
    override val CONTENT_VIEW_SELECTION_LIST: String
        get() = "List"
    override val SETTINGS_PRIVATE_CONTENT_PASSWORD_TITLE: String
        get() = "Private Content Password"
    override val NO_CONTENT_HOME_LABEL: String
        get() = "No Content Found"
    override val NO_CONTENT_HOME_MESSAGE: String
        get() = "You can use the 'Add' button to create content"
    override val NO_FOLDERS_HOME_LABEL: String
        get() = "No Folders Found"
    override val NO_FOLDERS_HOME_MESSAGE: String
        get() = "You can use the 'Add' button to create a Folder"
    override val NO_TAGS_HOME_LABEL: String
        get() = "No Tags Found"
    override val NO_TAGS_HOME_MESSAGE: String
        get() = "You can use the 'Add' button to create a Tag"
    override val NO_FOLDERS_SELECT_FOLDER_LABEL: String
        get() = "No Folders Found"
    override val NO_FOLDERS_SELECT_FOLDER_MESSAGE: String
        get() = "You can use the 'Add' button on the Home Screen to create a Folder"
    override val NO_TAGS_SELECT_TAGS_LABEL: String
        get() = "No Tags Found"
    override val NO_TAGS_SELECT_TAGS_MESSAGE: String
        get() = "You can use the 'Add' button on the Home Screen to create a Tag"
    override val NO_TAGS_SELECTED_SELECT_TAGS_LABEL: String
        get() = "No Tags Selected"
    override val NO_TAGS_SELECTED_CLICK_HERE_SELECT_TAGS_LABEL: String
        get() = "You can select tags by clicking here"
    override val NO_TAGS_SELECTED_SELECT_TAGS_MESSAGE: String
        get() = "You can add tags by tapping the available tags below"
    override val NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_LABEL: String
        get() = "No Tags Available"
    override val NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_MESSAGE: String
        get() = "You have selected all the tags, do you really need all of them?"
    override val NO_BOOKMARKS_CARD_MESSAGE: String
        get() = "No Bookmarks Here"
    override val EDIT_TITLE: String
        get() = "Edit"
    override val DELETE_TITLE: String
        get() = "Delete"
    override val SELECTED_TAGS_TITLE: String
        get() = "Selected Tags"
    override val SELECTABLE_TAGS_TITLE: String
        get() = "Available Tags"
    override val FINISH_TAG_SELECTION: String
        get() = "Complete Tag Selection"

    override fun NO_FOLDERS_SELECT_FOLDER_FORMATTABLE_MESSAGE(query: String): String {
        return "No folders found with name containing '$query'"
    }

    override fun NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_FORMATTABLE_MESSAGE(
        query: String,
    ): String {
        return "No tags found with name containing '$query'"
    }
}
