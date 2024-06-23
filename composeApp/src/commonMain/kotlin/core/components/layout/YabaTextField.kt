package core.components.layout

import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.selection.TextSelectionColors
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import core.settings.theme.ThemeStateProvider

@Composable
fun YabaTextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    textStyle: TextStyle = LocalTextStyle.current,
    label: @Composable (() -> Unit)? = null,
    placeholder: @Composable (() -> Unit)? = null,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null,
    isError: Boolean = false,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    singleLine: Boolean = false,
) {
    val themeState = ThemeStateProvider.current

    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier,
        textStyle = textStyle,
        label = label,
        placeholder = placeholder,
        leadingIcon = leadingIcon,
        trailingIcon = trailingIcon,
        isError = isError,
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions,
        singleLine = singleLine,
        colors = OutlinedTextFieldDefaults.colors().copy(
            focusedTextColor = themeState.colors.onBackground,
            unfocusedTextColor = themeState.colors.onBackground.copy(alpha = 0.8f),
            errorTextColor = themeState.colors.error,
            cursorColor = themeState.colors.primary,
            errorCursorColor = themeState.colors.error,
            textSelectionColors = TextSelectionColors(
                handleColor = themeState.colors.secondary,
                backgroundColor = themeState.colors.secondary.copy(alpha = 0.8f),
            ),
            focusedIndicatorColor = themeState.colors.primary,
            unfocusedIndicatorColor = themeState.colors.onBackground.copy(alpha = 0.8f),
            errorIndicatorColor = themeState.colors.error,
            focusedLeadingIconColor = themeState.colors.primary,
            unfocusedLeadingIconColor = themeState.colors.onBackground.copy(alpha = 0.8f),
            errorLeadingIconColor = themeState.colors.error,
            focusedTrailingIconColor = themeState.colors.primary,
            unfocusedTrailingIconColor = themeState.colors.onBackground.copy(alpha = 0.8f),
            errorTrailingIconColor = themeState.colors.error,
            focusedLabelColor = themeState.colors.primary,
            unfocusedLabelColor = themeState.colors.onBackground.copy(alpha = 0.8f),
            errorLabelColor = themeState.colors.error,
            focusedPlaceholderColor = themeState.colors.onBackground.copy(alpha = 0.8f),
            unfocusedPlaceholderColor = themeState.colors.onBackground.copy(alpha = 0.8f),
            errorPlaceholderColor = themeState.colors.error.copy(alpha = 0.8f),
        ),
    )
}
