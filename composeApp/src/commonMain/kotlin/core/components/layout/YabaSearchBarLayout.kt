package core.components.layout

import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.text.selection.TextSelectionColors
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SearchBar
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.TextFieldColors
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import core.settings.theme.ThemeStateProvider

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun YabaSearchBarLayout(
    query: String,
    onQueryChange: (String) -> Unit,
    onSearch: (String) -> Unit,
    active: Boolean,
    onActiveChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    placeholder: @Composable (() -> Unit)? = null,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val themeState = ThemeStateProvider.current

    SearchBar(
        query = query,
        onQueryChange = onQueryChange,
        onSearch = onSearch,
        active = active,
        onActiveChange = onActiveChange,
        modifier = modifier,
        enabled = enabled,
        placeholder = placeholder,
        leadingIcon = leadingIcon,
        trailingIcon = trailingIcon,
        content = content,
        colors = SearchBarDefaults.colors(
            containerColor = themeState.colors.background,
            dividerColor = themeState.colors.onBackground,
            inputFieldColors = TextFieldColors(
                textSelectionColors = TextSelectionColors(
                    handleColor = themeState.colors.secondary,
                    backgroundColor = themeState.colors.secondary.copy(alpha = 0.8f),
                ),
                cursorColor = themeState.colors.primary,

                // region FOCUSED
                focusedContainerColor = Color.Transparent,
                focusedTextColor = themeState.colors.onBackground,
                focusedPrefixColor = themeState.colors.onBackground,
                focusedSuffixColor = themeState.colors.onBackground,
                focusedSupportingTextColor = themeState.colors.onBackground,
                focusedIndicatorColor = themeState.colors.primary,
                focusedLeadingIconColor = themeState.colors.primary,
                focusedTrailingIconColor = themeState.colors.primary,
                focusedLabelColor = themeState.colors.primary,
                focusedPlaceholderColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                // endregion FOCUSED

                // region UNFOCUSED
                unfocusedContainerColor = Color.Transparent,
                unfocusedPlaceholderColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                unfocusedLabelColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                unfocusedTrailingIconColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                unfocusedLeadingIconColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                unfocusedIndicatorColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                unfocusedTextColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                unfocusedPrefixColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                unfocusedSuffixColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                unfocusedSupportingTextColor = themeState.colors.onBackground.copy(alpha = 0.8f),
                // endregion UNFOCUSED

                // region ERROR
                errorContainerColor = Color.Transparent,
                errorTextColor = themeState.colors.error,
                errorPlaceholderColor = themeState.colors.error.copy(alpha = 0.8f),
                errorPrefixColor = themeState.colors.error,
                errorSuffixColor = themeState.colors.error,
                errorSupportingTextColor = themeState.colors.error,
                errorLabelColor = themeState.colors.error,
                errorTrailingIconColor = themeState.colors.error,
                errorLeadingIconColor = themeState.colors.error,
                errorIndicatorColor = themeState.colors.error,
                errorCursorColor = themeState.colors.error,
                // endregion ERROR

                // region DISABLED
                disabledPrefixColor = Color.Transparent,
                disabledSuffixColor = Color.Transparent,
                disabledTextColor = Color.Transparent,
                disabledLabelColor = Color.Transparent,
                disabledContainerColor = Color.Transparent,
                disabledIndicatorColor = Color.Transparent,
                disabledPlaceholderColor = Color.Transparent,
                disabledLeadingIconColor = Color.Transparent,
                disabledTrailingIconColor = Color.Transparent,
                disabledSupportingTextColor = Color.Transparent,
                // endregion DISABLED
            )
        )
    )
}
