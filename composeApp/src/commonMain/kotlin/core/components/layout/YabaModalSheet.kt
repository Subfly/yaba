package core.components.layout

import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import core.theme.ThemeStateProvider

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun YabaModalSheet(
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    sheetState: SheetState = rememberModalBottomSheetState(),
    dragHandle: @Composable (() -> Unit)? = {
        val themeState = ThemeStateProvider.current

        BottomSheetDefaults.DragHandle(
            color = themeState.colors.secondary,
        )
    },
    content: @Composable ColumnScope.() -> Unit,
) {
    val themeState = ThemeStateProvider.current

    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        sheetState = sheetState,
        dragHandle = dragHandle,
        content = content,
        containerColor = themeState.colors.surface,
        contentColor = themeState.colors.onSurface,
    )
}
