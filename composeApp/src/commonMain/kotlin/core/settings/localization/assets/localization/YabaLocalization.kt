package core.settings.localization.assets.localization

abstract class YabaLocalization {
    abstract val APP_NAME: String
    abstract val OTHERS_FOLDER_NAME: String
    abstract val FOLDERS_TITLE: String
    abstract val TAGS_TITLE: String
    abstract val SYNC: String
    abstract val SETTINGS: String
    abstract val CREATE_BOOKMARK: String
    abstract val CREATE_FOLDER: String
    abstract val CREATE_TAG: String
    abstract val ADD_TAG: String
    abstract val EDIT_BOOKMARK: String
    abstract val EDIT_FOLDER: String
    abstract val EDIT_TAG: String
    abstract val EDIT_SELECTIONS: String
    abstract val PREVIEW: String
    abstract val WRITE_HERE: String
    abstract val TAG_NAME: String
    abstract val FOLDER_NAME: String
    abstract val BOOKMARK_NAME: String
    abstract val BOOKMARK_URL: String
    abstract val BOOKMARK_DESCRIPTION: String
    abstract val BOOKMARK_DESCRIPTION_PLACEHOLDER: String
    abstract val BOOKMARK_FOLDER_PATH_TITLE: String
    abstract val COLOR_SELECTION: String
    abstract val COLOR_SELECTION_FIRST: String
    abstract val COLOR_SELECTION_SECOND: String
    abstract val ICON_SELECTION: String
    abstract val SEARCH_FIELD_PLACEHOLDER: String
    abstract val BOOKMARK_COUNT_PREFIX_TEXT: String
    abstract val SEARCH_FOR_ICON_TEXT: String
    abstract val THEME_AND_LANGUAGE_OPTIONS: String
    abstract val CONTENT_OPTIONS: String
    abstract val THEME_SELECTION_OPTION: String
    abstract val THEME_SELECTION_OPTION_SYSTEM: String
    abstract val THEME_SELECTION_OPTION_DARK: String
    abstract val THEME_SELECTION_OPTION_LIGHT: String
    abstract val LANGUAGE_SELECTION_OPTION: String
    abstract val LANGUAGE_SELECTION_EN: String
    abstract val LANGUAGE_SELECTION_TR: String
    abstract val CONTENT_VIEW_SELECTION_OPTION: String
    abstract val CONTENT_VIEW_SELECTION_GRID: String
    abstract val CONTENT_VIEW_SELECTION_LIST: String
    abstract val SETTINGS_PRIVATE_CONTENT_PASSWORD_TITLE: String
    abstract val NO_CONTENT_HOME_LABEL: String
    abstract val NO_CONTENT_HOME_MESSAGE: String
    abstract val NO_FOLDERS_HOME_LABEL: String
    abstract val NO_FOLDERS_HOME_MESSAGE: String
    abstract val NO_BOOKMARKS_LABEL: String
    abstract val NO_BOOKMARKS_MESSAGE: String
    abstract val NO_TAGS_HOME_LABEL: String
    abstract val NO_TAGS_HOME_MESSAGE: String
    abstract val NO_FOLDERS_SELECT_FOLDER_LABEL: String
    abstract val NO_FOLDERS_SELECT_FOLDER_MESSAGE: String
    abstract val NO_TAGS_SELECT_TAGS_LABEL: String
    abstract val NO_TAGS_SELECT_TAGS_MESSAGE: String
    abstract val NO_TAGS_SELECTED_SELECT_TAGS_LABEL: String
    abstract val NO_TAGS_SELECTED_CLICK_HERE_SELECT_TAGS_LABEL: String
    abstract val NO_TAGS_SELECTED_SELECT_TAGS_MESSAGE: String
    abstract val NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_LABEL: String
    abstract val NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_MESSAGE: String
    abstract val NO_BOOKMARKS_CARD_MESSAGE: String
    abstract val EDIT_TITLE: String
    abstract val DELETE_TITLE: String
    abstract val SELECTED_TAGS_TITLE: String
    abstract val SELECTABLE_TAGS_TITLE: String
    abstract val FINISH_TAG_SELECTION: String
    abstract val CANNOT_BE_EMPTY_ERROR_MESSAGE: String

    abstract fun NO_FOLDERS_SELECT_FOLDER_FORMATTABLE_MESSAGE(
        query: String,
    ): String

    abstract fun NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_FORMATTABLE_MESSAGE(
        query: String,
    ): String

    abstract fun AT_MOST_X_CHARACTERS_ERROR_MESSAGE(
        currentCount: Int,
        maximumCount: Int,
    ): String
}
